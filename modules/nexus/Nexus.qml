pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }

    signal close

    implicitWidth: implicitHeight * Tokens.sizes.nexus.ratio
    implicitHeight: nState.screen.height * Tokens.sizes.nexus.heightMult

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: Colours.palette.m3surfaceContainerLow

        Behavior on color {
            CAnim {}
        }
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        radius: Tokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    BlobRect {
        anchors.right: parent.right
        anchors.top: parent.top

        group: blobGroup
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: windowBtn.implicitHeight + Tokens.padding.extraSmall

        IconButton {
            id: windowBtn

            anchors.centerIn: parent
            icon: nState.isWindow ? "close" : "pip"
            type: IconButton.Text
            label.fill: 0
            inactiveOnColour: hovered ? nState.isWindow ? Colours.palette.m3error : Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            stateLayer.opacity: 0
            onClicked: {
                if (!nState.isWindow)
                    WindowFactory.create();
                root.close();
            }

            label.scale: pressed ? 0.8 : 1
            label.renderType: Text.QtRendering

            Behavior on label.scale {
                Anim {}
            }
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        nState: nState
        width: Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(root.width / 3))
    }
}
