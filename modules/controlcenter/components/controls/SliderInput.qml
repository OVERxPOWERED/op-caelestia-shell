pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 0
    property var validator: null
    property string suffix: "" // Optional suffix text (e.g., "×", "px")
    property var formatValueFunction: null // Optional custom format function
    property var parseValueFunction: null // Optional custom parse function
    
    function formatValue(val: real): string {
        if (formatValueFunction) {
            return formatValueFunction(val);
        }
        // Default format function
        if (validator && validator.bottom !== undefined) {
            // Check if it's an integer validator
            if (validator.top !== undefined && validator.top === Math.floor(validator.top)) {
                return Math.round(val).toString();
            }
        }
        return val.toFixed(1);
    }
    
    function parseValue(text: string): real {
        if (parseValueFunction) {
            return parseValueFunction(text);
        }
        // Default parse function
        if (validator && validator.bottom !== undefined) {
            // Check if it's an integer validator
            if (validator.top !== undefined && validator.top === Math.floor(validator.top)) {
                return parseInt(text);
            }
        }
        return parseFloat(text);
    }
    
    signal valueChanged(real newValue)

    spacing: Appearance.spacing.small

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            visible: root.label !== ""
            text: root.label
            font.pointSize: Appearance.font.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledRect {
            Layout.preferredWidth: 70
            implicitHeight: inputField.implicitHeight + Appearance.padding.small * 2
            color: inputHover.containsMouse || inputField.activeFocus 
                   ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                   : Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Appearance.rounding.small
            border.width: 1
            border.color: inputField.activeFocus 
                          ? Colours.palette.m3primary
                          : Qt.alpha(Colours.palette.m3outline, 0.3)

            Behavior on color { CAnim {} }
            Behavior on border.color { CAnim {} }

            MouseArea {
                id: inputHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                acceptedButtons: Qt.NoButton
            }

            StyledTextField {
                id: inputField
                anchors.centerIn: parent
                width: parent.width - Appearance.padding.normal
                horizontalAlignment: TextInput.AlignHCenter
                validator: root.validator
                
                Component.onCompleted: {
                    text = root.formatValue(root.value);
                }
                
                onTextChanged: {
                    if (activeFocus) {
                        const val = root.parseValue(text);
                        if (!isNaN(val)) {
                            // Validate against validator bounds if available
                            let isValid = true;
                            if (root.validator) {
                                if (root.validator.bottom !== undefined && val < root.validator.bottom) {
                                    isValid = false;
                                }
                                if (root.validator.top !== undefined && val > root.validator.top) {
                                    isValid = false;
                                }
                            }
                            
                            if (isValid) {
                                root.valueChanged(val);
                            }
                        }
                    }
                }
                
                onEditingFinished: {
                    const val = root.parseValue(text);
                    let isValid = true;
                    if (root.validator) {
                        if (root.validator.bottom !== undefined && val < root.validator.bottom) {
                            isValid = false;
                        }
                        if (root.validator.top !== undefined && val > root.validator.top) {
                            isValid = false;
                        }
                    }
                    
                    if (isNaN(val) || !isValid) {
                        text = root.formatValue(root.value);
                    }
                }
            }
        }

        StyledText {
            visible: root.suffix !== ""
            text: root.suffix
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.normal
        }
    }

    StyledSlider {
        id: slider

        Layout.fillWidth: true
        implicitHeight: Appearance.padding.normal * 3

        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        
        onMoved: {
            const newValue = root.stepSize > 0 ? Math.round(value / root.stepSize) * root.stepSize : value;
            root.valueChanged(newValue);
            if (!inputField.activeFocus) {
                inputField.text = root.formatValue(newValue);
            }
        }
    }
    
    // Update input field when value changes externally (slider is already bound)
    onValueChanged: {
        if (!inputField.activeFocus) {
            inputField.text = root.formatValue(root.value);
        }
    }
}

