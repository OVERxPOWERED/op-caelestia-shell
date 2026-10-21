pragma Singleton

import QtQuick

// Ranks SearchIndex entries against a query. Every word of the query must match
// somewhere in an entry; entries are scored by where the words match.
QtObject {
    id: root

    readonly property int maxResults: 40

    function isSubsequence(needle: string, hay: string): bool {
        let i = 0;
        for (let j = 0; j < hay.length && i < needle.length; j++) {
            if (hay[j] === needle[i])
                i++;
        }
        return i === needle.length;
    }

    function startsWord(hay: string, token: string): bool {
        return hay.startsWith(token) || hay.includes(" " + token) || hay.includes("-" + token) || hay.includes("(" + token);
    }

    // Score of one query word against one entry; 0 means no match.
    function scoreToken(token: string, e: var, pageLabel: string, kw: list<string>): int {
        const label = e.label.toLowerCase();
        // "wifi" should match "Wi-Fi" exactly
        const flat = label.replace(/[-\s]/g, "");
        if (label === token || flat === token)
            return 100;
        if (label.startsWith(token) || flat.startsWith(token))
            return 85;
        if (startsWord(label, token))
            return 70;
        if (label.includes(token))
            return 55;
        if (kw.includes(token))
            return 50;
        if (kw.some(k => k.startsWith(token)))
            return 40;
        if (e.section.toLowerCase().includes(token) || e.subTitle.toLowerCase().includes(token))
            return 30;
        if (e.subtext.toLowerCase().includes(token))
            return 25;
        if (pageLabel.includes(token))
            return 20;
        if (token.length >= 3 && isSubsequence(token, label))
            return 10;
        return 0;
    }

    function search(query: string, pageLabels: list<string>): list<var> {
        const tokens = query.toLowerCase().trim().split(/\s+/).filter(t => t.length > 0);
        if (tokens.length === 0)
            return [];

        const phrase = tokens.join(" ");
        const results = [];
        const entries = SearchIndex.entries;
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            const kw = e.kw.concat(SearchIndex.pageKeywords[e.page] ?? []);
            const pageLabel = (pageLabels[e.page] ?? "").toLowerCase();

            let total = 0;
            let matched = true;
            // A multi-word keyword such as "dark mode" matches the query as a phrase:
            // a keyword set on the entry itself beats one set on its page
            if (tokens.length > 1 && e.kw.some(k => k.includes(phrase))) {
                total = 100;
            } else if (tokens.length > 1 && e.kind === "page" && e.sub === 0 && (SearchIndex.pageKeywords[e.page] ?? []).some(k => k.includes(phrase))) {
                total = 80;
            } else {
                for (const token of tokens) {
                    const s = scoreToken(token, e, pageLabel, kw);
                    if (s === 0) {
                        matched = false;
                        break;
                    }
                    total += s;
                }
            }
            if (!matched)
                continue;

            // Pages and sub-pages rank just above a row with the same match
            if (e.kind === "page")
                total += 3;
            results.push({
                entry: e,
                score: total,
                order: i
            });
        }

        results.sort((a, b) => b.score - a.score || a.order - b.order);
        return results.slice(0, maxResults);
    }
}
