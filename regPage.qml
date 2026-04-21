import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 906
    height: 508
    color: "#111111"

    Rectangle {
        id: mainWindow
        width: 510
        height: 520
        color: "#111111"
        radius: 20
        anchors.centerIn: parent
        border.color: "#333333"
        border.width: 1

        Text {
            id: logoText
            text: "LPMC"
            color: "#9900FF"
            anchors {
                top: parent.top
                topMargin: 30
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 32; bold: true; letterSpacing: 2 }
        }

        Text {
            id: subtitleText
            text: "Password Manager"
            color: "#CCCCCC"
            anchors {
                top: logoText.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 14 }
        }

        Text {
            id: createMasterText
            text: "Create Master Password"
            color: "#FFFFFF"
            anchors {
                top: subtitleText.bottom
                topMargin: 25
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 18; bold: true }
        }

        Text {
            id: setupText
            text: "Set up your master password to secure your vault"
            color: "#AAAAAA"
            anchors {
                top: createMasterText.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 12 }
        }

        // ── Master password field ─────────────────────────────────────────────
        Text {
            id: masterPassLabel
            text: "Master Password"
            color: "#CCCCCC"
            anchors {
                top: setupText.bottom
                topMargin: 25
                left: parent.left
                leftMargin: 40
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        TextField {
            id: masterPass
            placeholderText: "Enter your master password"
            echoMode: TextInput.Password
            passwordCharacter: "*"
            anchors {
                top: masterPassLabel.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            height: 40
            background: Rectangle {
                color: "#1E1E1E"
                radius: 8
                border.color: masterPass.activeFocus ? "#9900FF" : "#333333"
                border.width: 1
            }
            color: "#FFFFFF"
            placeholderTextColor: "#666666"
            leftPadding: 12
            font.pixelSize: 14
        }

        Text {
            id: lengthErrorText
            text: masterPass.text.length >= 8 ? "✓ Strong enough" : "Minimum 8 characters"
            color: masterPass.text.length >= 8 ? "#00C851" : "#FF4444"
            visible: masterPass.text.length > 0
            anchors {
                top: masterPass.bottom
                topMargin: 4
                right: masterPass.right
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        // ── Confirm password field ────────────────────────────────────────────
        Text {
            id: confirmPassLabel
            text: "Confirm Password"
            color: "#CCCCCC"
            anchors {
                top: masterPass.bottom
                topMargin: 22
                left: parent.left
                leftMargin: 40
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        TextField {
            id: confirmPass
            placeholderText: "Confirm your master password"
            echoMode: TextInput.Password
            passwordCharacter: "*"
            anchors {
                top: confirmPassLabel.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            height: 40
            background: Rectangle {
                color: "#1E1E1E"
                radius: 8
                border.color: confirmPass.activeFocus ? "#9900FF" : "#333333"
                border.width: 1
            }
            color: "#FFFFFF"
            placeholderTextColor: "#666666"
            leftPadding: 12
            font.pixelSize: 14
        }

        Text {
            id: matchErrorText
            text: "Passwords don't match"
            color: "#FF4444"
            visible: confirmPass.text.length > 0 && masterPass.text !== confirmPass.text
            anchors {
                top: confirmPass.bottom
                topMargin: 4
                right: confirmPass.right
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        // ── Strength bar ──────────────────────────────────────────────────────
        Rectangle {
            id: strengthBg
            width: 430
            height: 4
            color: "#1E1E1E"
            radius: 2
            anchors {
                top: confirmPass.bottom
                topMargin: 22
                horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: {
                    if (masterPass.text.length === 0)  return 0
                    if (masterPass.text.length < 6)    return parent.width * 0.25
                    if (masterPass.text.length < 10)   return parent.width * 0.6
                    return parent.width
                }
                height: parent.height
                radius: 2
                color: {
                    if (masterPass.text.length === 0)  return "#333333"
                    if (masterPass.text.length < 6)    return "#FF4444"
                    if (masterPass.text.length < 10)   return "#FFBB33"
                    return "#00C851"
                }
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // ── Create button ─────────────────────────────────────────────────────
        Button {
            id: createButton
            text: "CREATE"
            anchors {
                top: strengthBg.bottom
                topMargin: 22
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            height: 45
            enabled: masterPass.text.length >= 8 && masterPass.text === confirmPass.text
            hoverEnabled: true

            onClicked: {
                if (fileManager.saveMasterPassword(masterPass.text)) {
                    stackView.push("qrc:/homePage.qml")
                } else {
                    saveErrorText.visible = true
                }
            }

            background: Rectangle {
                color: createButton.enabled
                       ? (createButton.hovered ? "#aa22ff" : "#9900FF")
                       : "#333333"
                radius: 8
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font { family: "Roboto"; pixelSize: 14; bold: true; letterSpacing: 1 }
            }

            scale: pressed ? 0.95 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            id: saveErrorText
            text: "Failed to save password. Check disk permissions."
            color: "#FF4444"
            visible: false
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            anchors {
                top: createButton.bottom
                topMargin: 8
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            font { family: "Roboto"; pixelSize: 11 }
        }

        Text {
            text: "⚠  Remember this password! It cannot be recovered."
            color: "#FFAA00"
            anchors {
                top: createButton.bottom
                topMargin: saveErrorText.visible ? 30 : 12
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 11; italic: true }
        }
    }
}
