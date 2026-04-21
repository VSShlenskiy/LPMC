import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: settingsPageRoot
    width: 906
    height: 508
    color: "#0A0A0A"

    // Local state — written to AppSettings only on SAVE
    property string selectedLanguage: AppSettings.language
    property string selectedTheme:    AppSettings.theme

    // ── Top bar ───────────────────────────────────────────────────────────────
    Rectangle {
        id: topBar
        width: parent.width
        height: 70
        color: "#111111"

        Rectangle {
            id: backBtn
            width: 36; height: 36; radius: 8
            color: backMa.containsMouse ? "#222222" : "transparent"
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                text: "\u2190"
                color: backMa.containsMouse ? "#9900FF" : "#AAAAAA"
                font.pixelSize: 22
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: backMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stackView.pop()
            }
        }

        Text {
            text: "SETTINGS"
            color: "#FFFFFF"
            anchors { left: backBtn.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
            font { family: "Roboto"; pixelSize: 18; bold: true; letterSpacing: 1 }
        }

        Text {
            text: "LPMC"
            color: "#9900FF"
            anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
            font { family: "Roboto"; pixelSize: 18; bold: true }
        }
    }

    // ── Two-column layout ─────────────────────────────────────────────────────
    Row {
        anchors {
            top: topBar.bottom; bottom: saveArea.top
            left: parent.left; right: parent.right
            margins: 20; topMargin: 16; bottomMargin: 8
        }
        spacing: 16

        // ── Language column ───────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 16) / 2
            height: parent.height
            color: "#111111"
            radius: 12

            Column {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
                spacing: 14

                Row {
                    spacing: 8
                    Text { text: "\uD83C\uDF10"; font.pixelSize: 18 }
                    Text {
                        text: "Language"
                        color: "#FFFFFF"
                        font { family: "Roboto"; pixelSize: 16; bold: true }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "Choose the interface language"
                    color: "#555555"
                    font { family: "Roboto"; pixelSize: 12 }
                }

                Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                // Language options
                Repeater {
                    model: [
                        { code: "English",    flag: "\uD83C\uDDEC\uD83C\uDDE7", label: "English" },
                        { code: "Russian",    flag: "\uD83C\uDDF7\uD83C\uDDFA", label: "Русский" },
                        { code: "Lithuanian", flag: "\uD83C\uDDF1\uD83C\uDDF9", label: "Lietuvių" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 46
                        radius: 8
                        color: langMa.containsMouse
                               ? "#1E1E1E"
                               : (settingsPageRoot.selectedLanguage === modelData.code ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Active indicator bar
                        Rectangle {
                            width: 3; height: 22; radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedLanguage === modelData.code
                            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        }

                        Text {
                            text: modelData.flag
                            font.pixelSize: 18
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        }

                        Text {
                            text: modelData.label
                            color: settingsPageRoot.selectedLanguage === modelData.code ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors { left: parent.left; leftMargin: 46; verticalCenter: parent.verticalCenter }
                        }

                        Text {
                            text: "\u2713"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedLanguage === modelData.code
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: langMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsPageRoot.selectedLanguage = modelData.code
                        }
                    }
                }
            }
        }

        // ── Theme column ──────────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 16) / 2
            height: parent.height
            color: "#111111"
            radius: 12

            Column {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
                spacing: 14

                Row {
                    spacing: 8
                    Text { text: "\uD83C\uDFA8"; font.pixelSize: 18 }
                    Text {
                        text: "Theme"
                        color: "#FFFFFF"
                        font { family: "Roboto"; pixelSize: 16; bold: true }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "Choose the color theme"
                    color: "#555555"
                    font { family: "Roboto"; pixelSize: 12 }
                }

                Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                // Theme options
                Repeater {
                    model: [
                        {
                            code: "Dark",
                            label: "Dark",
                            swatches: ["#0A0A0A", "#1E1E1E", "#9900FF"]
                        },
                        {
                            code: "Light",
                            label: "Light",
                            swatches: ["#F0F0F0", "#E8E8E8", "#7700CC"]
                        },
                        {
                            code: "Purple",
                            label: "Purple",
                            swatches: ["#0D0017", "#2D0055", "#CC00FF"]
                        }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        radius: 8
                        color: themeMa.containsMouse
                               ? "#1E1E1E"
                               : (settingsPageRoot.selectedTheme === modelData.code ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Active indicator bar
                        Rectangle {
                            width: 3; height: 26; radius: 2
                            color: "#9900FF"
                            visible: settingsPageRoot.selectedTheme === modelData.code
                            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        }

                        // Color swatches
                        Row {
                            id: swatchRow
                            spacing: 3
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }

                            Repeater {
                                model: modelData.swatches
                                Rectangle {
                                    width: 18; height: 18; radius: 4
                                    color: modelData
                                    border.color: "#333333"; border.width: 1
                                }
                            }
                        }

                        Text {
                            text: modelData.label
                            color: settingsPageRoot.selectedTheme === modelData.code ? "#FFFFFF" : "#AAAAAA"
                            font { family: "Roboto"; pixelSize: 14 }
                            anchors { left: swatchRow.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        }

                        Text {
                            text: "\u2713"
                            color: "#9900FF"
                            font.pixelSize: 14
                            visible: settingsPageRoot.selectedTheme === modelData.code
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        }

                        MouseArea {
                            id: themeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsPageRoot.selectedTheme = modelData.code
                        }
                    }
                }
            }
        }
    }

    // ── Save button ───────────────────────────────────────────────────────────
    Rectangle {
        id: saveArea
        height: 64
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        color: "#0A0A0A"

        Rectangle {
            width: 120; height: 40
            radius: 8
            color: saveMa.containsMouse ? "#aa22ff" : "#9900FF"
            anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                text: "SAVE"
                color: "#FFFFFF"
                font { family: "Roboto"; pixelSize: 13; bold: true }
                anchors.centerIn: parent
            }

            MouseArea {
                id: saveMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    AppSettings.setTheme(settingsPageRoot.selectedTheme)
                    AppSettings.setLanguage(settingsPageRoot.selectedLanguage)
                    AppSettings.save()
                    stackView.pop()
                }
            }
        }
    }
}
