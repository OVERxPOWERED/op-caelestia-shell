import QtQuick

Loader {
    id: root

    property Component sourceComp
    property bool isComplete

    asynchronous: true
    Component.onCompleted: {
        isComplete = true;
        sourceComponent = sourceComp;
    }
    onSourceCompChanged: {
        if (isComplete)
            anim.restart();
    }

    SequentialAnimation {
        id: anim

        running: false

        Anim {
            target: root
            property: "opacity"
            to: 0
            type: Anim.FastEffects
        }
        ScriptAction {
            script: root.sourceComponent = root.sourceComp
        }
        Anim {
            target: root
            property: "opacity"
            to: 1
            type: Anim.DefaultEffects
        }
    }
}
