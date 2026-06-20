pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils
import ".."

Searcher {
    id: root

    readonly property string themesDir: Quickshell.shellPath("assets/themes")

    function prettyName(folder: string): string {
        return folder.replace(/[_-]+/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}theme `.length);
    }

    function reload(): void {
        themeDirs.path = "";
        themeDirs.path = root.themesDir;
    }

    list: themes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions
    keys: ["name", "folder"]
    weights: [0.8, 0.2]

    FileSystemModel {
        id: themeDirs

        path: root.themesDir
        filter: FileSystemModel.Dirs
        watchChanges: true
    }

    Variants {
        id: themes

        model: themeDirs.entries
        Theme {}
    }

    component Theme: QtObject {
        required property FileSystemEntry modelData
        readonly property string folder: modelData.name
        readonly property string name: root.prettyName(folder)
        readonly property string desc: qsTr("Apply theme assets and wallpaper")
        readonly property string wallpaperPath: `${modelData.path}/wallpaper.jpg`

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;
            GlobalConfig.paths.themeName = folder;
            GlobalConfig.save();
            Wallpapers.setWallpaper(wallpaperPath);
        }
    }
}
