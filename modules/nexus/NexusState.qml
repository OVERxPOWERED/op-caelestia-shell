import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen
    property string searchText
    // Label of the row to scroll to and flash once its page has loaded
    property string pendingHighlight

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal focusSearch
    signal clearSearch
    signal searchMove(int delta)
    signal searchActivate
    signal subPageOpened(idx: int)
    signal subPageClosed

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    // Opens a page (and sub-page) found through search; for a row, its label is
    // highlighted once the page has loaded.
    function openSearchResult(page: int, sub: int, label: string, isRow: bool): void {
        clearSearch();
        pendingHighlight = isRow ? label : "";

        if (currentPageIdx === page) {
            while (subPageIdxStack.length > 0)
                closeSubPage();
            if (sub > 0)
                openSubPage(sub);
        } else {
            currentPageIdx = page; // also resets the sub-page stack
            if (sub > 0)
                subPageIdxStack = [sub];
        }
    }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
