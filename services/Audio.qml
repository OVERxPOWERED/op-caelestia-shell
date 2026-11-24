pragma Singleton

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.utils

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    // --- Routing, Combined Output & Live Device Availability ---
    property var streamTargets: ({})
    property bool combinedSinkEnabled: false
    property var combinedSinkMembers: []
    property var sinkVolumeTrims: ({})
    property var routeAvailability: ({})
    property var nodeDeviceMeta: ({})
    readonly property string combinedModuleName: "caelestia_combined"
    readonly property PwNode combinedSinkNode: sinks.find(s => s && s.name === combinedModuleName) ?? null
    readonly property bool isCombinedSinkActive: combinedSinkNode !== null
    property bool routingStateLoaded: false

    signal routingChanged()

    function getStreamTargetId(stream: PwNode): int {
        if (!stream)
            return -1;
        return streamTargets[stream.id] ?? -1;
    }

    function setStreamTarget(stream: PwNode, targetSink: PwNode): void {
        if (!stream)
            return;

        const streamId = stream.id;
        const targetId = targetSink ? targetSink.id : -1;
        const targetName = targetSink ? targetSink.name : (sink ? sink.name : "");
        const props = stream.properties || {};
        const serial = props["object.serial"] || "";

        const newTargets = Object.assign({}, streamTargets);
        if (targetId === -1 || (sink && targetId === sink.id)) {
            delete newTargets[streamId];
        } else {
            newTargets[streamId] = targetId;
        }
        streamTargets = newTargets;
        routingChanged();

        let cmd = "";
        if (targetId === -1) {
            cmd = `pw-metadata -n default ${streamId} -d target.node 2>/dev/null; pw-metadata -n default ${streamId} -d target.object 2>/dev/null`;
            if (serial && targetName) {
                cmd += `; pactl move-sink-input ${serial} ${targetName} 2>/dev/null || true`;
            }
        } else {
            cmd = `pw-metadata -n default ${streamId} target.node ${targetId} 2>/dev/null; pw-metadata -n default ${streamId} target.object ${targetId} 2>/dev/null`;
            if (serial && targetName) {
                cmd += `; pactl move-sink-input ${serial} ${targetName} 2>/dev/null || true`;
            }
        }

        audioCmdProc.exec(["sh", "-c", cmd]);
    }

    function toggleCombinedSinkMember(sinkName: string): void {
        const members = [...combinedSinkMembers];
        const idx = members.indexOf(sinkName);
        if (idx >= 0) {
            members.splice(idx, 1);
        } else {
            members.push(sinkName);
        }
        combinedSinkMembers = members;
        saveRoutingState();
        rebuildCombinedSink();
    }

    function setCombinedSinkEnabled(enable: bool): void {
        combinedSinkEnabled = enable;
        saveRoutingState();
        rebuildCombinedSink();
    }

    function setSinkTrimVolume(node: PwNode, vol: real): void {
        if (node?.ready && node?.audio) {
            node.audio.muted = false;
            node.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, vol));
            const newTrims = Object.assign({}, sinkVolumeTrims);
            newTrims[node.name] = vol;
            sinkVolumeTrims = newTrims;
            saveRoutingState();
        }
    }

    function saveRoutingState(): void {
        if (!routingStateLoaded)
            return;
        const data = {
            combinedEnabled: combinedSinkEnabled,
            combinedSinkMembers: combinedSinkMembers,
            sinkVolumeTrims: sinkVolumeTrims
        };
        routingStorage.setText(JSON.stringify(data, null, 2));
    }

    function rebuildCombinedSink(): void {
        if (!combinedSinkEnabled) {
            const unloadCmd = "for id in $(pactl list short modules 2>/dev/null | grep module-combine-sink | awk '{print $1}'); do pactl unload-module \"$id\" 2>/dev/null || true; done";
            audioCmdProc.exec(["sh", "-c", unloadCmd]);
            return;
        }

        const activeMembers = [];
        for (const s of sinks) {
            if (s && s.name !== combinedModuleName && combinedSinkMembers.includes(s.name)) {
                activeMembers.push(s.name);
            }
        }

        if (activeMembers.length >= 2) {
            const slavesStr = activeMembers.join(",");
            const cmd = `for id in $(pactl list short modules 2>/dev/null | grep module-combine-sink | awk '{print $1}'); do pactl unload-module "$id" 2>/dev/null || true; done; pactl load-module module-combine-sink sink_name=${combinedModuleName} slaves=${slavesStr} sink_properties=device.description="Combined\\ Output"`;
            audioCmdProc.exec(["sh", "-c", cmd]);
        }
    }

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return Tr.trCtx("Unknown", "unknown audio stream");

        const props = stream.properties || {};
        const appName = props["application.name"] || stream.name || "";
        const mediaTitle = props["media.name"] || props["media.title"] || stream.description || "";

        const genericTitles = ["AudioStream", "Playback", "System Sounds", "ALSA Playback", appName];
        const isGeneric = !mediaTitle || genericTitles.some(t => mediaTitle.toLowerCase().trim() === t.toLowerCase().trim());

        if (!isGeneric && mediaTitle !== "") {
            if (appName !== "" && mediaTitle.toLowerCase().includes(appName.toLowerCase()))
                return mediaTitle;
            if (["Chromium", "Firefox", "Google Chrome", "Brave", "Edge", "Opera", "Vivaldi", "Zen Browser"].some(b => appName.toLowerCase().includes(b.toLowerCase())))
                return mediaTitle;
            if (appName !== "")
                return `${appName}: ${mediaTitle}`;
            return mediaTitle;
        }

        return appName || stream.description || stream.name || Tr.trCtx("Unknown application", "unknown application audio stream");
    }

    function getStreamIcon(stream: PwNode): string {
        if (!stream)
            return "";

        const props = stream.properties || {};
        const iconName = props["application.icon-name"] || props["media.icon-name"] || "";
        if (iconName) {
            const path = Quickshell.iconPath(iconName, "");
            if (path)
                return path;
        }

        const appName = props["application.name"] || props["application.process.binary"] || stream.name || "";
        if (appName) {
            const icon = DesktopEntries.heuristicLookup(appName)?.icon;
            if (icon) {
                const path = Quickshell.iconPath(icon, "");
                if (path)
                    return path;
            }
        }

        return "";
    }

    function isHiddenStream(stream: PwNode): bool {
        if (!stream)
            return true;

        const name = getStreamName(stream).toLowerCase();
        const props = stream.properties || {};
        const appName = (props["application.name"] ?? "").toLowerCase();
        const nodeName = (stream.name ?? "").toLowerCase();
        const binary = (props["application.process.binary"] ?? "").toLowerCase();
        const mediaName = (props["media.name"] ?? "").toLowerCase();

        const isInternal = name.includes("quickshell") || name.includes("caelestia")
            || appName.includes("quickshell") || appName.includes("caelestia")
            || nodeName.includes("quickshell") || nodeName.includes("caelestia")
            || binary.includes("quickshell") || binary.includes("caelestia");

        const isWallpaper = name.includes("wallpaper") || appName.includes("wallpaper")
            || nodeName.includes("wallpaper") || binary.includes("wallpaper")
            || name.includes("skwd") || appName.includes("skwd")
            || nodeName.includes("skwd") || binary.includes("skwd")
            || mediaName.includes(" - mpv") || (nodeName === "mpv" && binary !== "mpv");

        return isInternal || isWallpaper;
    }

    function playFocusEnd(): void {
        if (GlobalConfig.focus.chime)
            sfxFocusEnd.play();
    }

    function playBreakEnd(): void {
        if (GlobalConfig.focus.chime)
            sfxBreakEnd.play();
    }

    function isBluetoothConnected(node: PwNode): bool {
        const desc = (node.description || "").toLowerCase();
        const name = (node.name || "").toLowerCase();
        const props = node.properties || {};
        const isBluetooth = props["device.api"] === "bluez5" || props["device.bus"] === "bluetooth" || name.startsWith("bluez_output.") || name.startsWith("bluez_input.") || desc.includes("bluetooth");
        if (!isBluetooth)
            return true;

        const btDevices = Bluetooth.devices?.values ?? [];
        const match = btDevices.find(d => {
            if (!d)
                return false;
            const dAddrUnderscore = (d.address || "").toLowerCase().replace(/:/g, "_");
            const dAddrColon = (d.address || "").toLowerCase();
            const dName = (d.name || "").toLowerCase();
            return (dAddrUnderscore !== "" && name.includes(dAddrUnderscore))
                || (dAddrColon !== "" && name.includes(dAddrColon))
                || (dName !== "" && desc.includes(dName));
        });
        return !!match && (match.paired || match.bonded) && match.connected;
    }

    function isNodeConnectedByRoute(node: PwNode): bool {
        const desc = (node.description || "").toLowerCase();
        const props = node.properties || {};
        const profDesc = (props["device.profile.description"] || "").toLowerCase();

        if (desc.includes("unplugged") || desc.includes("disconnected") || profDesc.includes("unplugged") || profDesc.includes("disconnected"))
            return false;

        const meta = nodeDeviceMeta[node.id];
        const devId = props["device.id"] !== undefined ? props["device.id"] : meta?.devId;
        const profDev = props["card.profile.device"] !== undefined ? props["card.profile.device"] : meta?.profDev;

        if (devId !== undefined && profDev !== undefined) {
            const key = `${devId}:${profDev}`;
            if (routeAvailability[key] === false)
                return false;
        }

        return true;
    }

    function isValidOutputSink(node: PwNode): bool {
        if (!node || !node.isSink)
            return false;

        // If it's our combined sink, it is always valid when present
        if (node.name === root.combinedModuleName)
            return true;

        if (!isBluetoothConnected(node))
            return false;

        if (!isNodeConnectedByRoute(node))
            return false;

        return true;
    }

    function isValidInputSource(node: PwNode): bool {
        if (!node || !node.audio || node.isSink)
            return false;

        const name = (node.name || "").toLowerCase();
        const desc = (node.description || "").toLowerCase();
        const props = node.properties || {};
        const mediaClass = (props["media.class"] || "").toLowerCase();

        // Exclude sink monitors
        if (name.endsWith(".monitor") || desc.startsWith("monitor of ") || mediaClass === "audio/sink")
            return false;

        if (!isBluetoothConnected(node))
            return false;

        if (!isNodeConnectedByRoute(node))
            return false;

        return true;
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink && root.isValidOutputSink(node))
                    newSinks.push(node);
                else if (root.isValidInputSource(node))
                    newSources.push(node);
            } else if (node.audio) {
                newStreams.push(node);
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;

        if (!metaProc.running)
            metaProc.exec(["pw-metadata", "-n", "default"]);

        if (root.combinedSinkEnabled && root.routingStateLoaded) {
            const comb = newSinks.find(s => s && s.name === root.combinedModuleName);
            if (comb && root.sink?.name !== root.combinedModuleName) {
                root.setAudioSink(comb);
            } else if (!comb) {
                root.rebuildCombinedSink();
            }
        }
    }

    onSinkChanged: {
        root.refreshNodes();
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(Tr.tr("Audio output changed"), Tr.tr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(Tr.tr("Audio input changed"), Tr.tr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        pwDumpProc.running = true;
        previousSinkName = sink?.description || sink?.name || Tr.trCtx("Unknown device", "unknown audio device");
        previousSourceName = source?.description || source?.name || Tr.trCtx("Unknown device", "unknown audio device");
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
            pwDumpDebounce.restart();
        }

        target: Pipewire.nodes
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
            pwDumpDebounce.restart();
        }

        target: Bluetooth.devices
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    CavaProvider {
        id: cava

        bars: GlobalConfig.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        function toggleCombined(): void {
            root.setCombinedSinkEnabled(!root.combinedSinkEnabled);
        }

        target: "audio"
    }

    Process {
        id: audioCmdProc
    }

    Timer {
        id: pwDumpDebounce

        interval: 120
        repeat: false
        onTriggered: {
            if (!pwDumpProc.running)
                pwDumpProc.running = true;
        }
    }

    Process {
        id: pwSubscribeProc

        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("card") || line.includes("sink") || line.includes("source") || line.includes("device"))
                    pwDumpDebounce.restart();
            }
        }
    }

    Process {
        id: pwDumpProc

        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const nextAvail = {};
                    const nextMeta = {};

                    for (const obj of data) {
                        if (!obj)
                            continue;
                        if (obj.type === "PipeWire:Interface:Device") {
                            const devId = obj.id;
                            const routes = obj.info?.params?.EnumRoute ?? [];
                            const perDev = {};
                            for (const r of routes) {
                                const devs = r.devices ?? [];
                                const avail = r.available !== "no";
                                for (const d of devs) {
                                    const key = `${devId}:${d}`;
                                    perDev[key] = (perDev[key] === true) || avail;
                                }
                            }
                            for (const k in perDev)
                                nextAvail[k] = perDev[k];
                        } else if (obj.type === "PipeWire:Interface:Node") {
                            const props = obj.info?.props ?? {};
                            if (props["device.id"] !== undefined && props["card.profile.device"] !== undefined) {
                                nextMeta[obj.id] = {
                                    devId: props["device.id"],
                                    profDev: props["card.profile.device"]
                                };
                            }
                        }
                    }

                    root.routeAvailability = nextAvail;
                    root.nodeDeviceMeta = nextMeta;
                    root.refreshNodes();
                } catch (e) {
                    console.warn("Audio: failed to parse pw-dump:", e);
                }
            }
        }
    }

    SoundEffect {
        id: sfxFocusEnd

        source: Qt.resolvedUrl("../assets/sounds/notifications/" + GlobalConfig.focus.focusEndSound)
        volume: 0.8
    }

    SoundEffect {
        id: sfxBreakEnd

        source: Qt.resolvedUrl("../assets/sounds/notifications/" + GlobalConfig.focus.breakEndSound)
        volume: 0.8
    }

    Process {
        id: metaProc

        command: ["pw-metadata", "-n", "default"]
        stdout: StdioCollector {
            onStreamFinished: {
                const targets = {};
                const lines = text.split("\n");
                for (const line of lines) {
                    const match = line.match(/update:\s+id:(\d+)\s+key:'target\.(?:node|object)'\s+value:'(\d+)'/);
                    if (match) {
                        targets[parseInt(match[1])] = parseInt(match[2]);
                    }
                }
                root.streamTargets = targets;
                root.routingChanged();
            }
        }
    }

    FileView {
        id: routingStorage

        printErrors: false
        path: `${Paths.state}/audio_routing.json`
        onLoaded: {
            try {
                const content = text().trim();
                if (content.length > 0) {
                    const data = JSON.parse(content);
                    if (data) {
                        root.combinedSinkEnabled = !!data.combinedEnabled;
                        if (Array.isArray(data.combinedSinkMembers))
                            root.combinedSinkMembers = data.combinedSinkMembers;
                        if (data.sinkVolumeTrims && typeof data.sinkVolumeTrims === "object")
                            root.sinkVolumeTrims = data.sinkVolumeTrims;
                    }
                }
            } catch (e) {
                console.warn("Failed to parse audio routing JSON:", e);
            }
            root.routingStateLoaded = true;
            if (root.combinedSinkEnabled) {
                root.rebuildCombinedSink();
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.routingStateLoaded = true;
                Qt.callLater(() => routingStorage.setText(JSON.stringify({
                    combinedEnabled: false,
                    combinedSinkMembers: [],
                    sinkVolumeTrims: {}
                }, null, 2)));
            }
        }
    }
}
