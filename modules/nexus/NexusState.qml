import QtQuick
import Quickshell

QtObject {
    property ShellScreen screen
    property bool isWindow
    property int currentPageIdx
    property bool searchOpen

    signal close
}
