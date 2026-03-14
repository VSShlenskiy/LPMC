import QtQuick 2.9
import QtQuick.Controls 2.9

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
        border.color: "#111111"
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
            font {
                family: "Roboto"
                pixelSize: 32
                bold: true
                letterSpacing: 2
            }
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
            font {
                family: "Roboto"
                pixelSize: 14
                bold: false
            }
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
            font {
                family: "Roboto"
                pixelSize: 20
                bold: true
            }
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
            font {
                family: "Roboto"
                pixelSize: 12
                bold: false
            }
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
            font {
                family: "Roboto"
                pixelSize: 11
                bold: true
            }
        }
        
        TextField {
            id: masterPass
            placeholderText: "Enter your master password"
            echoMode: TextField.Password
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
                border.color: parent.focus ? "#9900FF" : "#333333"
                border.width: 1
            }
            
            color: "#FFFFFF"
            placeholderTextColor: "#666666"
            leftPadding: 12
            font.pixelSize: 14
            
            onAccepted: {
                if (masterPass.text.length === 8) {
                    attemptUnlock()
                }
            }
        }
        
        Button {
            id: unlockButton
            text: "Unlock Vault"
            anchors {
                top: masterPass.bottom
                topMargin: 30
                horizontalCenter: parent.horizontalCenter
            }
            
            width: 430
            height: 45
            enabled: masterPass.text.length > 0
            
            hoverEnabled: false
            
            onClicked: {
                attemptUnlock()
            }
            
            background: Rectangle {
                color: unlockButton.enabled ? "#9900FF" : "#333333"
                radius: 8
                
                opacity: unlockButton.pressed ? 0.8 : 1.0
            }
            
            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font {
                    family: "Roboto"
                    pixelSize: 14
                    bold: true
                    letterSpacing: 1
                }
            }
            scale: pressed ? 0.9 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 150 
                    easing.type: Easing.InOutQuad
                }
            }
            
            states: []
        }
        
        Text {
            id: storageText
            text: "Your data is encrypted and stored locally on your device"
            color: "#666666"
            anchors {
                top: unlockButton.bottom
                topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
            font {
                family: "Roboto"
                pixelSize: 10
                bold: false
            }
        }
        
        Text {
            id: errorText
            text: "Incorrect password"
            color: "#FF4444"
            visible: false
            anchors {
                top: masterPass.bottom
                topMargin: 5
                right: parent.right
                rightMargin: 40
            }
            font {
                family: "Roboto"
                pixelSize: 11
                bold: true
            }
        }
        
        Text {
            id: capsLockIndicator
            text: "Caps Lock is on"
            color: "#FFAA00"
            visible: false
            anchors {
                top: masterPass.bottom
                topMargin: 5
                left: parent.left
                leftMargin: 40
            }
            font {
                family: "Roboto"
                pixelSize: 11
                bold: true
            }
        }
    }
    
    function attemptUnlock() {
        // Здесь должна быть проверка мастер-пароля
        
        if (fileManager.verifyMasterPassword(masterPass.text)) {
            stackView.push("homePage.qml")
        } else {
            errorText.visible = true
            
            masterPass.background.color = "#2A1E1E"
            shakeAnimation.start()
            
            hideErrorTimer.start()
        }
    }
    
    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x; duration: 50 }
        
        onStopped: {
            masterPass.background.color = "#1E1E1E"
        }
    }
    
    Timer {
        id: hideErrorTimer
        interval: 3000
        onTriggered: {
            errorText.visible = false
        }
    }
}