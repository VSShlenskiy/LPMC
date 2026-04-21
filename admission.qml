import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 906
    height: 508
    color: "#111111"

    Rectangle {
        id: mainWindow
        width: 510
        height: 400
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
                topMargin: 40
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
            id: unlockTitle
            text: "Enter Master Password"
            color: "#FFFFFF"
            anchors {
                top: subtitleText.bottom
                topMargin: 30
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 20; bold: true }
        }

        Text {
            id: unlockSubtitle
            text: "Unlock your password vault"
            color: "#AAAAAA"
            anchors {
                top: unlockTitle.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 12 }
        }

        Text {
            id: masterPassLabel
            text: "Master Password"
            color: "#CCCCCC"
            anchors {
                top: unlockSubtitle.bottom
                topMargin: 30
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
            height: 45

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

            onAccepted: attemptUnlock()
        }

        Text {
            id: errorText
            text: "Incorrect password"
            color: "#FF4444"
            visible: false
            anchors {
                top: masterPass.bottom
                topMargin: 5
                right: masterPass.right
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        Button {
            id: unlockButton
            text: "UNLOCK"
            anchors {
                top: masterPass.bottom
                topMargin: 30
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            height: 45
            enabled: masterPass.text.length > 0
            hoverEnabled: true

            onClicked: attemptUnlock()

            background: Rectangle {
                color: unlockButton.enabled
                       ? (unlockButton.hovered ? "#aa22ff" : "#9900FF")
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
            text: "Your data is encrypted and stored locally on your device"
            color: "#555555"
            anchors {
                top: unlockButton.bottom
                topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 10 }
        }
    }

    // Shake animation for wrong password
    SequentialAnimation {
        id: shakeAnimation
        property real originX: 0

        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: shakeAnimation.originX; duration: 50 }
    }

    Timer {
        id: hideErrorTimer
        interval: 3000
        onTriggered: errorText.visible = false
    }

    function attemptUnlock() {
        if (fileManager.verifyMasterPassword(masterPass.text)) {
            // Load saved passwords into model before navigating
            var json = fileManager.loadPasswords()
            PasswordModel.fromJson(json)
            stackView.push("qrc:/homePage.qml")
        } else {
            errorText.visible = true
            shakeAnimation.originX = masterPass.x
            shakeAnimation.start()
            hideErrorTimer.restart()
            masterPass.selectAll()
        }
    }
}
