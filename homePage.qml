import QtQuick 2.9
import QtQuick.Controls 2.9

Rectangle {
    width: 906
    height: 508
    color: "#0A0A0A"

    // Load persisted passwords as soon as this page appears
    Component.onCompleted: {
        var json = fileManager.loadPasswords()
        PasswordModel.fromJson(json)
    }

    Rectangle {
        id: topBar
        width: parent.width
        height: 80
        color: "#111111"
        
        Text {
            id: logoText
            text: "LPMC"
            color: "#9900FF"
            anchors {
                left: parent.left
                leftMargin: 30
                verticalCenter: parent.verticalCenter
            }
            font { family: "Roboto"; pixelSize: 24; bold: true }
        }
        
        Text {
            text: "Password Manager"
            color: "#888888"
            anchors {
                left: logoText.right
                leftMargin: 10
                bottom: logoText.bottom
                bottomMargin: 5
            }
            font { family: "Roboto"; pixelSize: 12 }
        }
        
        Text {
            text: "ALL PASSWORDS"
            color: "#FFFFFF"
            anchors {
                left: logoText.right
                leftMargin: 150
                verticalCenter: parent.verticalCenter
            }
            font { family: "Roboto"; pixelSize: 20; bold: true; letterSpacing: 1 }
        }
        // Settings button
        Rectangle {
            id: settingsBtn
            width: 40
            height: 40
            radius: 8
            color: settingsMouse.containsMouse ? "#222222" : "transparent"
            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "\u2699"
                color: settingsMouse.containsMouse ? "#9900FF" : "#888888"
                font.pixelSize: 22
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stackView.push("settingPage.qml")
            }
        }
    }
    
    Rectangle {
        id: contentArea
        anchors {
            top: topBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        color: "#0A0A0A"
        
        // ── Left panel ────────────────────────────────────────────────────
        Rectangle {
            id: leftPanel
            width: 200
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: 20
            }
            color: "#111111"
            radius: 10
            
            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 15
                }
                spacing: 15
                
                Text {
                    text: "Categories"
                    color: "#FFFFFF"
                    font { family: "Roboto"; pixelSize: 14; bold: true }
                }
                
                Rectangle { width: parent.width; height: 1; color: "#333333" }
                
                // "All" category with live count badge
                Rectangle {
                    width: parent.width
                    height: 30
                    color: "#333333"
                    radius: 5
                    
                    Text {
                        text: "All"
                        color: "#FFFFFF"
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        font { family: "Roboto"; pixelSize: 13 }
                    }
                    
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#9900FF"
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        
                        Text {
                            // Dynamically reflects the actual number of saved passwords
                            text: PasswordModel.count()
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                            font { pixelSize: 11; bold: true }
                        }
                    }
                }
                
                Text { text: "General"; color: "#888888"; font { family: "Roboto"; pixelSize: 13 } }
                Text { text: "Work";    color: "#888888"; font { family: "Roboto"; pixelSize: 13 } }
                Text { text: "Social";  color: "#888888"; font { family: "Roboto"; pixelSize: 13 } }
                Text { text: "Banking"; color: "#888888"; font { family: "Roboto"; pixelSize: 13 } }
            }
        }
        
        // ── Right panel ───────────────────────────────────────────────────
        Rectangle {
            id: rightPanel
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: leftPanel.right
                right: parent.right
                margins: 20
                leftMargin: 10
            }
            color: "#111111"
            radius: 10
            
            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                }
                spacing: 20
                
                // Search bar
                Rectangle {
                    width: parent.width
                    height: 40
                    color: "#1E1E1E"
                    radius: 8
                    
                    TextInput {
                        id: searchInput
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 12
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 14
                        
                        Text {
                            text: "Search passwords..."
                            color: "#666666"
                            visible: !searchInput.text.length
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 14
                        }
                    }
                }
                
                // Password list
                ListView {
                    id: passwordList
                    width: parent.width
                    height: 350
                    clip: true
                    spacing: 12
                    model: PasswordModel

                    // Empty-state placeholder
                    Text {
                        anchors.centerIn: parent
                        text: "No passwords saved yet.\nClick \"ADD PASSWORD\" to get started."
                        color: "#555555"
                        horizontalAlignment: Text.AlignHCenter
                        font { family: "Roboto"; pixelSize: 14 }
                        visible: passwordList.count === 0
                        lineHeight: 1.6
                    }

                    delegate: PasswordItem {
                        service:  model.title
                        username: model.username
                        password: model.password
                        url:      model.website
                    }
                }
            }
        }
        
        // ── Action buttons ─────────────────────────────────────────────────
        Row {
            anchors {
                bottom: parent.bottom
                bottomMargin: 30
                right: parent.right
                rightMargin: 40
            }
            spacing: 15
            
            Button {
                text: "ADD PASSWORD"
                width: 150
                height: 40
                background: Rectangle { color: "#9900FF"; radius: 8 }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font { family: "Roboto"; pixelSize: 12; bold: true }
                }
                onClicked: stackView.push("generatePasswordPage.qml")
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
            }
            
            Button {
                text: "LOCK VAULT"
                width: 150
                height: 40
                background: Rectangle { color: "#333333"; radius: 8 }
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font { family: "Roboto"; pixelSize: 12; bold: true }
                }
                onClicked: stackView.push("admission.qml")
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
            }
        }
    }
}
