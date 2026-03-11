import QtQuick 2.9
import QtQuick.Controls 2.9

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
        border.color: "#111111"
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
            id: createMasterText
            text: "Create Master Password"
            color: "#FFFFFF"
            anchors {
                top: subtitleText.bottom
                topMargin: 25
                horizontalCenter: parent.horizontalCenter
            }
            font {
                family: "Roboto"
                pixelSize: 18
                bold: true
            }
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
                top: setupText.bottom
                topMargin: 25
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
            height: 40
            
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
        }
        
        Text {
            id: confirmPassLabel
            text: "Confirm Password"
            color: "#CCCCCC"
            anchors {
                top: masterPass.bottom
                topMargin: 15
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
            id: confirmPass
            placeholderText: "Confirm your master password"
            echoMode: TextField.Password
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
                border.color: parent.focus ? "#9900FF" : "#333333"
                border.width: 1
            }
            
            color: "#FFFFFF"
            placeholderTextColor: "#666666"
            leftPadding: 12
            font.pixelSize: 14
            
            onTextChanged: checkPasswords()
        }
        
        Rectangle {
            id: strengthIndicator
            width: 430
            height: 4
            color: "#1E1E1E"
            radius: 2
            anchors {
                top: confirmPass.bottom
                topMargin: 8
                horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: {
                    if (masterPass.text.length === 0) return 0
                    else if (masterPass.text.length < 6) return parent.width * 0.3
                    else if (masterPass.text.length < 10) return parent.width * 0.6
                    else return parent.width
                }
                height: parent.height
                color: {
                    if (masterPass.text.length === 0) return "#333333"
                    else if (masterPass.text.length < 6) return "#FF4444"
                    else if (masterPass.text.length < 10) return "#FFBB33"
                    else return "#00C851"
                }
                radius: 2
            }
        }
        
        Button {
            id: createButton
            text: "Create Password"
            anchors {
                top: strengthIndicator.bottom
                topMargin: 25
                horizontalCenter: parent.horizontalCenter
            }
            
            width: 430
            height: 45
            enabled: passwordsMatch && masterPass.text.length >= 8
            
            hoverEnabled: false
            
            onClicked: {
                if (passwordsMatch && masterPass.text.length >= 8) {
                    if (fileManager.saveMasterPassword(masterPass.text)) {
                        console.log("Password saved successfully")
                        stackView.push("homePage.qml")
                    }       
                    else {
                        console.log("Failed to save password")
                    }
                }
            }
            
            background: Rectangle {
                color: createButton.enabled ? "#9900FF" : "#333333"
                radius: 8
                
                opacity: createButton.pressed ? 0.8 : 1.0
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
            
            states: []
        }
        
        Text {
            id: warningText
            text: "Important: Remember this password! You'll need it every time you access your vault. There is no way to recover it if you forget."
            color: "#FFAA00"
            anchors {
                top: createButton.bottom
                topMargin: 15
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font {
                family: "Roboto"
                pixelSize: 11
                bold: false
                italic: true
            }
        }
        
        Text {
            id: storageText
            text: "Your data is encrypted and stored locally on your device"
            color: "#666666"
            anchors {
                top: warningText.bottom
                topMargin: 10
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
            text: "Passwords don't match"
            color: "#FF4444"
            visible: !passwordsMatch && (masterPass.text.length > 0 || confirmPass.text.length > 0)
            anchors {
                top: confirmPass.bottom
                topMargin: 25
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
            id: lengthErrorText
            text: "Minimum 8 characters"
            color: masterPass.text.length > 0 && masterPass.text.length < 8 ? "#FF4444" : "#00C851"
            visible: masterPass.text.length > 0
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
    }
    
    property bool passwordsMatch: {
        return masterPass.text === confirmPass.text && masterPass.text.length > 0
    }
    
    function checkPasswords() {
        console.log("Password check:", masterPass.text, confirmPass.text, passwordsMatch)
    }
}