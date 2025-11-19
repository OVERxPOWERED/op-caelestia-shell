pragma ComponentBehavior: Bound

import qs.config
import QtQuick

// Reusable pane transition animation component
// Provides standard fade-out/scale-down → update → fade-in/scale-up animation
// Used when switching between detail/settings views in panes
SequentialAnimation {
    id: root

    // The Loader element to animate
    required property Item target
    
    // Optional list of PropertyActions to execute during the transition
    // These typically update the component being displayed
    property list<PropertyAction> propertyActions
    
    // Animation parameters (with sensible defaults)
    property real scaleFrom: 1.0
    property real scaleTo: 0.8
    property real opacityFrom: 1.0
    property real opacityTo: 0.0
    
    // Fade out and scale down
    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: root.opacityFrom
            to: root.opacityTo
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardAccel
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleFrom
            to: root.scaleTo
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardAccel
        }
    }
    
    // Execute property actions (component switching, state updates, etc.)
    // This is where the component change happens while invisible
    ScriptAction {
        script: {
            for (let i = 0; i < root.propertyActions.length; i++) {
                const action = root.propertyActions[i];
                if (action.target && action.property !== undefined) {
                    action.target[action.property] = action.value;
                }
            }
        }
    }
    
    // Fade in and scale up
    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "opacity"
            from: root.opacityTo
            to: root.opacityFrom
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
        
        NumberAnimation {
            target: root.target
            property: "scale"
            from: root.scaleTo
            to: root.scaleFrom
            duration: Appearance.anim.durations.normal / 2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standardDecel
        }
    }
}

