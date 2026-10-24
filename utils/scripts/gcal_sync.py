#!/usr/bin/env python3
"""
Google Calendar OAuth2 & Synchronization Helper for Caelestia Shell.
Zero external dependencies (uses standard library only).
"""

import sys
import os
import json
import time
import urllib.request
import urllib.parse
import urllib.error
import http.server
import socketserver
import webbrowser
import datetime
from argparse import ArgumentParser

DEFAULT_PORT = 8765
REDIRECT_URI = f"http://127.0.0.1:{DEFAULT_PORT}/callback"
AUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"
USERINFO_ENDPOINT = "https://www.googleapis.com/oauth2/v2/userinfo"
CALENDAR_LIST_ENDPOINT = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
EVENTS_ENDPOINT = "https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events"

SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/userinfo.email",
]

def get_default_dirs():
    home = os.path.expanduser("~")
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    xdg_cache = os.environ.get("XDG_CACHE_HOME", os.path.join(home, ".cache"))
    config_dir = os.path.join(xdg_config, "caelestia", "calendar")
    cache_dir = os.path.join(xdg_cache, "caelestia", "calendar")
    return config_dir, cache_dir

class GCalManager:
    def __init__(self, config_dir=None, cache_dir=None):
        default_config, default_cache = get_default_dirs()
        self.config_dir = config_dir or default_config
        self.cache_dir = cache_dir or default_cache

        os.makedirs(self.config_dir, exist_ok=True)
        os.makedirs(self.cache_dir, exist_ok=True)

        self.credentials_file = os.path.join(self.config_dir, "credentials.json")
        self.tokens_file = os.path.join(self.config_dir, "tokens.json")
        self.config_file = os.path.join(self.config_dir, "config.json")
        self.calendars_file = os.path.join(self.cache_dir, "calendars.json")
        self.events_file = os.path.join(self.cache_dir, "events.json")

    def load_json(self, path):
        if not os.path.exists(path):
            return None
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return None

    def save_json(self, path, data):
        tmp_path = path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, path)

    def get_credentials(self, explicit_id=None, explicit_secret=None, credentials_path=None):
        if explicit_id and explicit_secret:
            return {"client_id": explicit_id, "client_secret": explicit_secret}

        if credentials_path and os.path.exists(credentials_path):
            data = self.load_json(credentials_path)
            if data:
                return self._parse_credentials_dict(data)

        # Check in config_dir/credentials.json
        data = self.load_json(self.credentials_file)
        if data:
            return self._parse_credentials_dict(data)

        return None

    def _parse_credentials_dict(self, data):
        if not isinstance(data, dict):
            return None
        if "installed" in data:
            return {
                "client_id": data["installed"].get("client_id"),
                "client_secret": data["installed"].get("client_secret"),
            }
        if "web" in data:
            return {
                "client_id": data["web"].get("client_id"),
                "client_secret": data["web"].get("client_secret"),
            }
        if "client_id" in data and "client_secret" in data:
            return {
                "client_id": data["client_id"],
                "client_secret": data["client_secret"],
            }
        return None

    def save_credentials(self, client_id, client_secret):
        creds = {"client_id": client_id, "client_secret": client_secret}
        self.save_json(self.credentials_file, creds)
        return creds

    def get_tokens(self):
        return self.load_json(self.tokens_file)

    def is_authenticated(self):
        tokens = self.get_tokens()
        return bool(tokens and tokens.get("refresh_token"))

    def refresh_access_token(self):
        tokens = self.get_tokens()
        if not tokens or not tokens.get("refresh_token"):
            return None

        creds = self.get_credentials()
        if not creds:
            return None

        data = {
            "client_id": creds["client_id"],
            "client_secret": creds["client_secret"],
            "refresh_token": tokens["refresh_token"],
            "grant_type": "refresh_token",
        }
        req_data = urllib.parse.urlencode(data).encode("utf-8")
        req = urllib.request.Request(
            TOKEN_ENDPOINT,
            data=req_data,
            headers={"Content-Type": "application/x-www-form-urlencoded", "User-Agent": "Caelestia-Calendar/1.0"}
        )

        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                token_resp = json.loads(resp.read().decode("utf-8"))
                tokens["access_token"] = token_resp["access_token"]
                expires_in = token_resp.get("expires_in", 3600)
                tokens["expires_at"] = time.time() + expires_in
                self.save_json(self.tokens_file, tokens)
                return tokens["access_token"]
        except Exception as e:
            sys.stderr.write(f"Failed to refresh access token: {e}\n")
            return None

    def get_valid_access_token(self):
        tokens = self.get_tokens()
        if not tokens:
            return None

        # If token expires in less than 2 minutes, refresh it
        if tokens.get("expires_at", 0) - time.time() < 120:
            return self.refresh_access_token()

        return tokens.get("access_token")

    def login(self, client_id=None, client_secret=None, credentials_path=None):
        creds = self.get_credentials(client_id, client_secret, credentials_path)
        if not creds or not creds.get("client_id") or not creds.get("client_secret"):
            return {"status": "error", "message": "Missing Client ID or Client Secret"}

        # Save credentials for future refreshes
        self.save_credentials(creds["client_id"], creds["client_secret"])

        # Setup local OAuth callback receiver
        auth_code_holder = {"code": None, "error": None}

        class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
            def log_message(self, format, *args):
                pass  # Suppress console log

            def do_GET(self):
                parsed = urllib.parse.urlparse(self.path)
                if parsed.path == "/callback":
                    params = urllib.parse.parse_qs(parsed.query)
                    if "code" in params:
                        auth_code_holder["code"] = params["code"][0]
                        self.send_response(200)
                        self.send_header("Content-Type", "text/html; charset=utf-8")
                        self.end_headers()
                        html = """
                        <!DOCTYPE html>
                        <html>
                        <head><title>Caelestia - Authentication Successful</title>
                        <style>
                          body { font-family: system-ui, -apple-system, sans-serif; background: #121212; color: #e0e0e0; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                          .card { background: #1e1e1e; padding: 2rem 3rem; border-radius: 16px; border: 1px solid #333; text-align: center; max-width: 400px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
                          h2 { color: #8ab4f8; margin-top: 0; }
                          p { color: #aaa; line-height: 1.5; }
                        </style>
                        </head>
                        <body>
                          <div class="card">
                            <h2>Authentication Successful</h2>
                            <p>Google Calendar has been successfully linked with Caelestia Shell.</p>
                            <p>You can close this tab and return to your desktop.</p>
                          </div>
                        </body>
                        </html>
                        """
                        self.wfile.write(html.encode("utf-8"))
                    elif "error" in params:
                        auth_code_holder["error"] = params["error"][0]
                        self.send_response(400)
                        self.send_header("Content-Type", "text/html; charset=utf-8")
                        self.end_headers()
                        self.wfile.write(b"Authentication failed or cancelled.")
                    else:
                        self.send_response(404)
                        self.end_headers()
                else:
                    self.send_response(404)
                    self.end_headers()

        params = {
            "client_id": creds["client_id"],
            "redirect_uri": REDIRECT_URI,
            "response_type": "code",
            "scope": " ".join(SCOPES),
            "access_type": "offline",
            "prompt": "consent",
        }
        auth_url = f"{AUTH_ENDPOINT}?{urllib.parse.urlencode(params)}"

        server = None
        try:
            socketserver.TCPServer.allow_reuse_address = True
            server = socketserver.TCPServer(("127.0.0.1", DEFAULT_PORT), OAuthCallbackHandler)
            server.timeout = 180  # 3 minute timeout
        except Exception as e:
            return {"status": "error", "message": f"Could not bind local port {DEFAULT_PORT}: {e}"}

        # Open user browser
        try:
            webbrowser.open(auth_url)
        except Exception as e:
            sys.stderr.write(f"Could not open browser automatically: {e}\n")

        # Wait for callback
        while auth_code_holder["code"] is None and auth_code_holder["error"] is None:
            server.handle_request()

        server.server_close()

        if auth_code_holder["error"]:
            return {"status": "error", "message": f"OAuth error: {auth_code_holder['error']}"}

        code = auth_code_holder["code"]
        if not code:
            return {"status": "error", "message": "Authentication timed out"}

        # Exchange authorization code for tokens
        token_data = {
            "client_id": creds["client_id"],
            "client_secret": creds["client_secret"],
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": REDIRECT_URI,
        }
        req = urllib.request.Request(
            TOKEN_ENDPOINT,
            data=urllib.parse.urlencode(token_data).encode("utf-8"),
            headers={"Content-Type": "application/x-www-form-urlencoded", "User-Agent": "Caelestia-Calendar/1.0"}
        )

        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                token_resp = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            return {"status": "error", "message": f"Token exchange failed: {e}"}

        tokens = {
            "access_token": token_resp["access_token"],
            "refresh_token": token_resp.get("refresh_token"),
            "expires_at": time.time() + token_resp.get("expires_in", 3600),
            "scope": token_resp.get("scope", ""),
        }

        # Check if calendar scope was granted
        granted_scope = token_resp.get("scope", "")
        if "calendar" not in granted_scope:
            return {
                "status": "error",
                "message": "Calendar permission was not granted. Please ensure 'Google Calendar API' is enabled in Google Cloud Console, and check the box for 'See and download any calendar you can access' on Google's sign-in screen."
            }

        # Get user email
        email = self.fetch_user_email(tokens["access_token"])
        tokens["email"] = email

        self.save_json(self.tokens_file, tokens)

        # Trigger initial sync
        sync_res = self.sync()
        if sync_res.get("status") == "error":
            return {
                "status": "error",
                "message": sync_res.get("message", "Sync failed"),
                "email": email,
            }

        return {
            "status": "success",
            "message": "Authenticated successfully",
            "email": email,
            "sync": sync_res,
        }

    def fetch_user_email(self, access_token):
        try:
            req = urllib.request.Request(
                USERINFO_ENDPOINT,
                headers={"Authorization": f"Bearer {access_token}", "User-Agent": "Caelestia-Calendar/1.0"}
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                info = json.loads(resp.read().decode("utf-8"))
                return info.get("email", "")
        except Exception:
            return ""

    def logout(self):
        for f in [self.tokens_file, self.calendars_file, self.events_file]:
            if os.path.exists(f):
                try:
                    os.remove(f)
                except Exception:
                    pass
        return {"status": "success", "message": "Logged out successfully"}

    def fetch_calendars(self, access_token):
        req = urllib.request.Request(
            CALENDAR_LIST_ENDPOINT,
            headers={"Authorization": f"Bearer {access_token}", "User-Agent": "Caelestia-Calendar/1.0"}
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 403:
                raise RuntimeError("Google Calendar API returned 403 (Forbidden). Please make sure 'Google Calendar API' is enabled in Google Cloud Console and calendar permission is checked on sign-in.")
            raise e

        cal_items = []
        cfg = self.load_json(self.config_file) or {}
        enabled_map = cfg.get("enabled_calendars", {})

        for item in data.get("items", []):
            cal_id = item.get("id")
            primary = bool(item.get("primary", False))
            # Default: primary is enabled, others enabled if in config or selected
            is_enabled = enabled_map.get(cal_id, primary)

            cal_items.append({
                "id": cal_id,
                "summary": item.get("summary", "Untitled"),
                "primary": primary,
                "backgroundColor": item.get("backgroundColor", "#4285F4"),
                "foregroundColor": item.get("foregroundColor", "#ffffff"),
                "enabled": is_enabled,
            })

        self.save_json(self.calendars_file, {"calendars": cal_items, "updated": time.time()})
        return cal_items

    def sync(self):
        token = self.get_valid_access_token()
        if not token:
            return {"status": "error", "message": "Not authenticated or token refresh failed"}

        tokens = self.get_tokens()
        email = tokens.get("email", "") if tokens else ""

        try:
            calendars = self.fetch_calendars(token)
        except Exception as e:
            return {"status": "error", "message": f"Failed to fetch calendar list: {e}"}

        # Date window: start of previous month to end of next month
        now = datetime.datetime.now()
        # ~60 days back and ~60 days forward
        start_date = (now - datetime.timedelta(days=60)).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end_date = (now + datetime.timedelta(days=60)).replace(day=28, hour=23, minute=59, second=59, microsecond=0)

        time_min = start_date.isoformat() + "Z"
        time_max = end_date.isoformat() + "Z"

        all_events_by_date = {}

        for cal in calendars:
            if not cal.get("enabled", False):
                continue

            cal_id = cal["id"]
            cal_color = cal.get("backgroundColor", "#4285F4")
            encoded_id = urllib.parse.quote(cal_id, safe="")
            url = f"{EVENTS_ENDPOINT.format(calendarId=encoded_id)}?timeMin={time_min}&timeMax={time_max}&singleEvents=true&orderBy=startTime&maxResults=250"

            try:
                req = urllib.request.Request(
                    url,
                    headers={"Authorization": f"Bearer {token}", "User-Agent": "Caelestia-Calendar/1.0"}
                )
                with urllib.request.urlopen(req, timeout=15) as resp:
                    ev_data = json.loads(resp.read().decode("utf-8"))
            except Exception as e:
                sys.stderr.write(f"Error fetching events for {cal['summary']}: {e}\n")
                continue

            for item in ev_data.get("items", []):
                summary = item.get("summary", "No Title")
                start = item.get("start", {})
                end = item.get("end", {})
                item_color = item.get("colorId") or cal_color

                is_all_day = "date" in start
                if is_all_day:
                    start_str = start.get("date")  # YYYY-MM-DD
                    end_str = end.get("date")      # YYYY-MM-DD (exclusive)
                    try:
                        cur = datetime.date.fromisoformat(start_str)
                        finish = datetime.date.fromisoformat(end_str)
                        # Iterate through all days for this all-day event
                        while cur < finish:
                            d_key = cur.isoformat()
                            if d_key not in all_events_by_date:
                                all_events_by_date[d_key] = []
                            all_events_by_date[d_key].append({
                                "id": item.get("id"),
                                "summary": summary,
                                "allDay": True,
                                "startTime": "",
                                "endTime": "",
                                "color": cal_color,
                                "calendar": cal.get("summary", "")
                            })
                            cur += datetime.timedelta(days=1)
                    except Exception:
                        pass
                else:
                    start_dt_str = start.get("dateTime")
                    end_dt_str = end.get("dateTime")
                    if not start_dt_str:
                        continue
                    try:
                        # Extract date portion YYYY-MM-DD and time portion HH:MM
                        s_dt = datetime.datetime.fromisoformat(start_dt_str)
                        e_dt = datetime.datetime.fromisoformat(end_dt_str) if end_dt_str else s_dt

                        d_key = s_dt.date().isoformat()
                        if d_key not in all_events_by_date:
                            all_events_by_date[d_key] = []

                        all_events_by_date[d_key].append({
                            "id": item.get("id"),
                            "summary": summary,
                            "allDay": False,
                            "startTime": s_dt.strftime("%H:%M"),
                            "endTime": e_dt.strftime("%H:%M"),
                            "color": cal_color,
                            "calendar": cal.get("summary", "")
                        })
                    except Exception:
                        pass

        # Sort events per day: allDay events first, then by startTime
        for d_key, events in all_events_by_date.items():
            events.sort(key=lambda x: (not x["allDay"], x["startTime"]))

        result_payload = {
            "account": email,
            "lastSync": datetime.datetime.now().isoformat(),
            "lastSyncEpoch": time.time(),
            "calendars": calendars,
            "events": all_events_by_date,
        }

        self.save_json(self.events_file, result_payload)

        return {
            "status": "success",
            "message": "Events synced successfully",
            "account": email,
            "eventsCount": sum(len(v) for v in all_events_by_date.values()),
            "daysWithEvents": len(all_events_by_date),
            "lastSync": result_payload["lastSync"],
        }

    def set_calendar_enabled(self, calendar_id, enabled):
        cfg = self.load_json(self.config_file) or {}
        enabled_map = cfg.get("enabled_calendars", {})
        enabled_map[calendar_id] = enabled
        cfg["enabled_calendars"] = enabled_map
        self.save_json(self.config_file, cfg)

        # Update cache file as well
        cal_data = self.load_json(self.calendars_file)
        if cal_data and "calendars" in cal_data:
            for c in cal_data["calendars"]:
                if c["id"] == calendar_id:
                    c["enabled"] = enabled
            self.save_json(self.calendars_file, cal_data)

        # Trigger sync to update events
        return self.sync()

    def get_status(self):
        auth = self.is_authenticated()
        tokens = self.get_tokens() or {}
        events_data = self.load_json(self.events_file) or {}
        calendars_data = self.load_json(self.calendars_file) or {}

        return {
            "authenticated": auth,
            "email": tokens.get("email", ""),
            "lastSync": events_data.get("lastSync", ""),
            "lastSyncEpoch": events_data.get("lastSyncEpoch", 0),
            "calendars": calendars_data.get("calendars", []),
            "totalDaysWithEvents": len(events_data.get("events", {})),
        }

def main():
    parser = ArgumentParser(description="Google Calendar Sync for Caelestia")
    parser.add_argument("command", choices=["status", "login", "sync", "logout", "list-calendars", "toggle-calendar"])
    parser.add_argument("--client-id", dest="client_id", help="OAuth Client ID")
    parser.add_argument("--client-secret", dest="client_secret", help="OAuth Client Secret")
    parser.add_argument("--credentials-file", dest="credentials_file", help="Path to client_secret.json")
    parser.add_argument("--calendar-id", dest="calendar_id", help="Calendar ID to toggle")
    parser.add_argument("--enabled", dest="enabled", choices=["true", "false"], help="Enable or disable calendar")
    parser.add_argument("--config-dir", dest="config_dir", help="Custom config directory")
    parser.add_argument("--cache-dir", dest="cache_dir", help="Custom cache directory")

    args = parser.parse_args()
    mgr = GCalManager(config_dir=args.config_dir, cache_dir=args.cache_dir)

    if args.command == "status":
        print(json.dumps(mgr.get_status(), indent=2))
    elif args.command == "login":
        res = mgr.login(args.client_id, args.client_secret, args.credentials_file)
        print(json.dumps(res, indent=2))
        sys.exit(0 if res.get("status") == "success" else 1)
    elif args.command == "sync":
        res = mgr.sync()
        print(json.dumps(res, indent=2))
        sys.exit(0 if res.get("status") == "success" else 1)
    elif args.command == "logout":
        res = mgr.logout()
        print(json.dumps(res, indent=2))
    elif args.command == "list-calendars":
        token = mgr.get_valid_access_token()
        if not token:
            print(json.dumps({"status": "error", "message": "Not authenticated"}))
            sys.exit(1)
        cals = mgr.fetch_calendars(token)
        print(json.dumps({"status": "success", "calendars": cals}, indent=2))
    elif args.command == "toggle-calendar":
        if not args.calendar_id or args.enabled is None:
            print(json.dumps({"status": "error", "message": "--calendar-id and --enabled required"}))
            sys.exit(1)
        enabled_bool = args.enabled.lower() == "true"
        res = mgr.set_calendar_enabled(args.calendar_id, enabled_bool)
        print(json.dumps(res, indent=2))

if __name__ == "__main__":
    main()
