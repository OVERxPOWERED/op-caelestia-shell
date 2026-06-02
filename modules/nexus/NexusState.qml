import QtQuick
import Quickshell

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool navExpanded
    property string currentPageName
    property int currentPageIdx

    signal close
}
