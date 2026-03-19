import QtQuick 2.9
import QtQuick.Controls 2.9

Rectangle {
    width: 906
    height: 508
    color: "#111111"
    
    Rectangle {
        id: mainWindow
        width: 510
        height: 620
        color: "#111111"
        radius: 20
        anchors.centerIn: parent
        border.color: "#111111"
        border.width: 1
        
        Flickable {
            id: mainFlickable
            anchors.fill: parent
            anchors.topMargin: 20
            contentHeight: mainColumn.height + 80
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            ScrollBar.vertical: null
            
            Column {
                id: mainColumn
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15
                
                Item { width: 1; height: 40 }
                
                Text {
                    text: "LPMC"
                    color: "#9900FF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font {
                        family: "Roboto"
                        pixelSize: 32
                        bold: true
                        letterSpacing: 2
                    }
                }
                
                Text {
                    text: "Add Password"
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font {
                        family: "Roboto"
                        pixelSize: 28
                        bold: true
                    }
                }
                
                Text {
                    text: "Fill in your password information"
                    color: "#AAAAAA"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font {
                        family: "Roboto"
                        pixelSize: 13
                    }
                }
                
                Item { width: 1; height: 10 }
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Text {
                        text: "Title *"
                        color: "#CCCCCC"
                        font {
                            family: "Roboto"
                            pixelSize: 13
                            bold: true
                        }
                    }
                    
                    TextField {
                        id: titleField
                        width: parent.width
                        height: 48
                        placeholderText: "Gmail"
                        
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 10
                            border.color: parent.focus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        
                        color: "#FFFFFF"
                        placeholderTextColor: "#666666"
                        leftPadding: 15
                        font {
                            family: "Roboto"
                            pixelSize: 14
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Text {
                        text: "Username/Email *"
                        color: "#CCCCCC"
                        font {
                            family: "Roboto"
                            pixelSize: 13
                            bold: true
                        }
                    }
                    
                    TextField {
                        id: usernameField
                        width: parent.width
                        height: 48
                        placeholderText: "user@example.com"
                        
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 10
                            border.color: parent.focus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        
                        color: "#FFFFFF"
                        placeholderTextColor: "#666666"
                        leftPadding: 15
                        font {
                            family: "Roboto"
                            pixelSize: 14
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Text {
                        text: "Password *"
                        color: "#CCCCCC"
                        font {
                            family: "Roboto"
                            pixelSize: 13
                            bold: true
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: 10
                        
                        TextField {
                            id: passwordField
                            width: parent.width - 70
                            height: 48
                            placeholderText: "12345678"
                            echoMode: TextField.Normal
                            
                            background: Rectangle {
                                color: "#1E1E1E"
                                radius: 10
                                border.color: parent.focus ? "#9900FF" : "#333333"
                                border.width: 1
                            }
                            
                            color: "#FFFFFF"
                            placeholderTextColor: "#666666"
                            leftPadding: 15
                            font {
                                family: "Roboto"
                                pixelSize: 14
                            }
                        }
                        
                        Rectangle {
                            width: 60
                            height: 48
                            color: "#2A2A2A"
                            radius: 10
                            
                            Text {
                                text: "?"
                                color: "#FFFFFF"
                                anchors.centerIn: parent
                                font {
                                    pixelSize: 24
                                    bold: true
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    passwordField.text = generateStrongPassword()
                                }
                            }
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Text {
                        text: "Website"
                        color: "#CCCCCC"
                        font {
                            family: "Roboto"
                            pixelSize: 13
                            bold: true
                        }
                    }
                    
                    TextField {
                        id: websiteField
                        width: parent.width
                        height: 48
                        placeholderText: "https://example.com"
                        
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 10
                            border.color: parent.focus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        
                        color: "#FFFFFF"
                        placeholderTextColor: "#666666"
                        leftPadding: 15
                        font {
                            family: "Roboto"
                            pixelSize: 14
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: 5
                    
                    Text {
                        text: "Category"
                        color: "#CCCCCC"
                        font {
                            family: "Roboto"
                            pixelSize: 13
                            bold: true
                        }
                    }
                    
                    ComboBox {
                        id: categoryCombo
                        width: parent.width
                        height: 48
                        
                        model: ["General", "Work", "Social", "Banking", "Shopping", "Other"]
                        
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 10
                            border.color: parent.focus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: categoryCombo.displayText
                            color: "#FFFFFF"
                            leftPadding: 15
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                        
                        indicator: Text {
                            text: "^"
                            color: "#666666"
                            anchors.right: parent.right
                            anchors.rightMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 16
                        }
                        
                        delegate: ItemDelegate {
                            width: categoryCombo.width
                            contentItem: Text {
                                text: modelData
                                color: "#FFFFFF"
                                leftPadding: 15
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.highlighted ? "#2A2A2A" : "#1E1E1E"
                            }
                        }
                        
                        popup: Popup {
                            y: categoryCombo.height - 1
                            width: categoryCombo.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 1
                            
                            contentItem: ListView {
                                clip: true
                                implicitHeight: 200
                                model: categoryCombo.delegateModel
                                currentIndex: categoryCombo.highlightedIndex
                                
                                ScrollIndicator.vertical: ScrollIndicator { }
                            }
                            
                            background: Rectangle {
                                color: "#1E1E1E"
                                border.color: "#333333"
                                border.width: 1
                                radius: 10
                            }
                        }
                    }
                }
                
                Text {
                    text: "* Required fields"
                    color: "#666666"
                    anchors.right: parent.right
                    font {
                        family: "Roboto"
                        pixelSize: 11
                        italic: true
                    }
                }
                
                Row {
                    anchors.right: parent.right
                    spacing: 15
                    
                    Button {
                        text: "Cancel"
                        width: 110
                        height: 48
                        
                        background: Rectangle {
                            color: "#2A2A2A"
                            radius: 10
                            border.color: "#444444"
                            border.width: 1
                            
                            opacity: parent.pressed ? 0.8 : 1.0
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font {
                                family: "Roboto"
                                pixelSize: 15
                                bold: true
                            }
                        }
                        
                        onClicked: {
                            stackView.pop()
                        }
                        scale: pressed ? 0.9 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150 
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                    
                    Button {
                        text: "Add"
                        width: 110
                        height: 48
                        enabled: titleField.text.length > 0 && 
                                 usernameField.text.length > 0 && 
                                 passwordField.text.length > 0
                        
                        background: Rectangle {
                            color: parent.enabled ? "#9900FF" : "#333333"
                            radius: 10
                            
                            opacity: parent.pressed ? 0.8 : 1.0
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font {
                                family: "Roboto"
                                pixelSize: 15
                                bold: true
                            }
                        }
                        
                        onClicked: {
                            if (titleField.text && usernameField.text && passwordField.text) {
                                PasswordModel.addPassword(
                                    titleField.text,
                                    usernameField.text,
                                    passwordField.text,
                                    websiteField.text
                                )
                            }

                            if (passwordField.text.length >= 8) {
                                if (fileManager.savePasswordField(passwordField.text)) {
                                    console.log("Password saved successfully")
                                    stackView.pop()
                                }       
                                else {
                                    console.log("Failed to save password")
                                }
                            }

                        }
                        scale: pressed ? 0.9 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150 
                                easing.type: Easing.InOutQuad
                            }
                        }   
                    }
                }
                
                Item { width: 1; height: 40 }
            }
        }
    }
    
    function generateStrongPassword() {
        var length = 16
        var charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}[]|:;<>,.?/~"
        var password = ""
        
        for (var i = 0; i < length; i++) {
            var randomIndex = Math.floor(Math.random() * charset.length)
            password += charset[randomIndex]
        }
        
        return password
    }
}