import QtQuick 2.9
import QtQuick.Controls 2.9

Rectangle {
    id: settingsPageRoot
    width: 906
    height: 508
    color: "#0A0A0A"
    
    // Свойства для хранения выбранных настроек
    property string selectedLanguage: "English"
    property string selectedTheme: "Dark"

    // ── Top bar ───────────────────────────────────────────────────────────────
    Rectangle {
        id: topBar
        width: parent.width
        height: 80
        color: "#111111"

        // Back button
        Rectangle {
            id: backBtn
            width: 36
            height: 36
            radius: 8
            color: backMouseArea.containsMouse ? "#222222" : "transparent"
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                text: "←"
                color: backMouseArea.containsMouse ? "#9900FF" : "#AAAAAA"
                font.pixelSize: 24
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: backMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof stackView !== 'undefined' && stackView) {
                        stackView.pop()
                    }
                }
            }
        }

        Text {
            text: "SETTINGS"
            color: "#FFFFFF"
            anchors {
                left: backBtn.right
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            font { family: "Roboto"; pixelSize: 20; bold: true; letterSpacing: 1 }
        }

        Text {
            text: "LPMC"
            color: "#9900FF"
            anchors {
                right: parent.right
                rightMargin: 30
                verticalCenter: parent.verticalCenter
            }
            font { family: "Roboto"; pixelSize: 20; bold: true }
        }
    }

    // ── Content ───────────────────────────────────────────────────────────────
    Row {
        anchors {
            top: topBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 24
        }
        spacing: 20

        // ── Language Section ──────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 20) / 2
            height: parent.height
            color: "#111111"
            radius: 12

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 24
                }
                spacing: 16

                Row {
                    spacing: 10
                    Text {
                        text: "🌐"
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Language"
                        color: "#FFFFFF"
                        font { family: "Roboto"; pixelSize: 18; bold: true }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "Choose the interface language"
                    color: "#666666"
                    font { family: "Roboto"; pixelSize: 12 }
                }

                Rectangle { 
                    width: parent.width
                    height: 1
                    color: "#222222"
                }

                // Language options
                Column {
                    width: parent.width
                    spacing: 8
                    
                    // English option
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 8
                        color: langEnglishMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedLanguage === "English" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 24
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedLanguage === "English"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "🇬🇧"
                            font.pixelSize: 20
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "English"
                            color: settingsPageRoot.selectedLanguage === "English" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 48
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedLanguage === "English"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: langEnglishMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedLanguage = "English"
                                console.log("Language selected: English")
                            }
                        }
                    }
                    
                    // Russian option
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 8
                        color: langRussianMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedLanguage === "Russian" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 24
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedLanguage === "Russian"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "🇷🇺"
                            font.pixelSize: 20
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "Russian"
                            color: settingsPageRoot.selectedLanguage === "Russian" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 48
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedLanguage === "Russian"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: langRussianMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedLanguage = "Russian"
                                console.log("Language selected: Russian")
                            }
                        }
                    }
                    
                    // Lithuanian option
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 8
                        color: langLithuanianMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedLanguage === "Lithuanian" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 24
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedLanguage === "Lithuanian"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "🇱🇹"
                            font.pixelSize: 20
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "Lithuanian"
                            color: settingsPageRoot.selectedLanguage === "Lithuanian" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 48
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedLanguage === "Lithuanian"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: langLithuanianMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedLanguage = "Lithuanian"
                                console.log("Language selected: Lithuanian")
                            }
                        }
                    }
                }
            }
        }

        // ── Theme Section ──────────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 20) / 2
            height: parent.height
            color: "#111111"
            radius: 12

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 24
                }
                spacing: 16

                Row {
                    spacing: 10
                    Text {
                        text: "🎨"
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Theme"
                        color: "#FFFFFF"
                        font { family: "Roboto"; pixelSize: 18; bold: true }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "Choose the color theme"
                    color: "#666666"
                    font { family: "Roboto"; pixelSize: 12 }
                }

                Rectangle { 
                    width: parent.width
                    height: 1
                    color: "#222222"
                }

                // Theme options
                Column {
                    width: parent.width
                    spacing: 8
                    
                    // Dark theme
                    Rectangle {
                        width: parent.width
                        height: 56
                        radius: 8
                        color: themeDarkMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedTheme === "Dark" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 28
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedTheme === "Dark"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 4
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#0A0A0A"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#111111"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#9900FF"
                                border.color: "#333333"
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Dark"
                            color: settingsPageRoot.selectedTheme === "Dark" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 80
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedTheme === "Dark"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: themeDarkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedTheme = "Dark"
                                console.log("Theme selected: Dark")
                            }
                        }
                    }
                    
                    // Light theme
                    Rectangle {
                        width: parent.width
                        height: 56
                        radius: 8
                        color: themeLightMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedTheme === "Light" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 28
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedTheme === "Light"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 4
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#F0F0F0"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#DDDDDD"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#7700CC"
                                border.color: "#333333"
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Light"
                            color: settingsPageRoot.selectedTheme === "Light" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 80
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedTheme === "Light"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: themeLightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedTheme = "Light"
                                console.log("Theme selected: Light")
                            }
                        }
                    }
                    
                    // Purple theme
                    Rectangle {
                        width: parent.width
                        height: 56
                        radius: 8
                        color: themePurpleMouse.containsMouse ? "#1E1E1E" : 
                               (settingsPageRoot.selectedTheme === "Purple" ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3
                            height: 28
                            radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedTheme === "Purple"
                            anchors { 
                                left: parent.left
                                leftMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 4
                            anchors {
                                left: parent.left
                                leftMargin: 16
                                verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#1A0033"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#2D0055"
                                border.color: "#333333"
                                border.width: 1
                            }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: "#CC00FF"
                                border.color: "#333333"
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Purple"
                            color: settingsPageRoot.selectedTheme === "Purple" ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors {
                                left: parent.left
                                leftMargin: 80
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "✓"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedTheme === "Purple"
                            anchors {
                                right: parent.right
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: themePurpleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsPageRoot.selectedTheme = "Purple"
                                console.log("Theme selected: Purple")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Save button (optional)
    Rectangle {
        width: 120
        height: 40
        radius: 8
        color: saveButtonMouse.containsMouse ? "#7700CC" : "#9900FF"
        anchors {
            bottom: parent.bottom
            bottomMargin: 20
            right: parent.right
            rightMargin: 44
        }
        Behavior on color { ColorAnimation { duration: 120 } }
        
        Text {
            text: "SAVE"
            color: "#FFFFFF"
            font { family: "Roboto"; pixelSize: 12; bold: true }
            anchors.centerIn: parent
        }
        
        MouseArea {
            id: saveButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                console.log("Settings saved - Language:", settingsPageRoot.selectedLanguage, "Theme:", settingsPageRoot.selectedTheme)
                // Here you can add actual save logic
                if (typeof stackView !== 'undefined' && stackView) {
                    stackView.pop()
                }
            }
        }
    }
}