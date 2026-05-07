import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 906
    height: 508
    color: "#111111"

    Rectangle {
        id: mainWindow
        width: 500
        height: 490
        color: "#111111"
        radius: 20
        anchors.centerIn: parent
        border.color: "#333333"
        border.width: 1

        Flickable {
            id: mainFlickable
            anchors {
                fill: parent
                topMargin: 16
                leftMargin: 16
                rightMargin: 4
                bottomMargin: 16
            }
            contentWidth: mainColumn.width
            contentHeight: mainColumn.implicitHeight + 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
                policy: ScrollBar.AsNeeded
                anchors.left: parent.right
                anchors.leftMargin: 4
                contentItem: Rectangle {
                    radius: 2
                    color: "#9900FF"
                    implicitWidth: 4
                }
            }

            Column {
                id: mainColumn
                width: parent.width - 16
                spacing: 14

                Item { width: 1; height: 8 }

                Text {
                    text: "LPMC"
                    color: "#9900FF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { family: "Roboto"; pixelSize: 28; bold: true; letterSpacing: 2 }
                }

                Text {
                    text: "Add Password"
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { family: "Roboto"; pixelSize: 22; bold: true }
                }

                Text {
                    text: "Fill in your password information"
                    color: "#888888"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { family: "Roboto"; pixelSize: 12 }
                }

                Item { width: 1; height: 4 }

                // ── Title ─────────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Title *"
                        color: "#CCCCCC"
                        font { family: "Roboto"; pixelSize: 12; bold: true }
                    }

                    TextField {
                        id: titleField
                        width: parent.width
                        height: 44
                        placeholderText: "Gmail, GitHub, Netflix…"
                        background: Rectangle {
                            color: "#1E1E1E"; radius: 8
                            border.color: titleField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font { family: "Roboto"; pixelSize: 13 }
                    }
                }

                // ── Username / Email ──────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Username / Email *"
                        color: "#CCCCCC"
                        font { family: "Roboto"; pixelSize: 12; bold: true }
                    }

                    TextField {
                        id: usernameField
                        width: parent.width
                        height: 44
                        placeholderText: "user@example.com"
                        background: Rectangle {
                            color: "#1E1E1E"; radius: 8
                            border.color: usernameField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font { family: "Roboto"; pixelSize: 13 }
                    }
                }

                // ── Password ──────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Password *"
                        color: "#CCCCCC"
                        font { family: "Roboto"; pixelSize: 12; bold: true }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        TextField {
                            id: passwordField
                            width: parent.width - 52
                            height: 44
                            placeholderText: "Enter or generate a password"
                            background: Rectangle {
                                color: "#1E1E1E"; radius: 8
                                border.color: passwordField.activeFocus ? "#9900FF" : "#333333"
                                border.width: 1
                            }
                            color: "#FFFFFF"
                            placeholderTextColor: "#555555"
                            leftPadding: 12
                            font { family: "Roboto"; pixelSize: 13 }
                        }

                        // Generate button
                        Rectangle {
                            width: 44
                            height: 44
                            color: genMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
                            radius: 8
                            border.color: "#444444"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                text: "\u2B06"
                                color: "#9900FF"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: genMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: passwordField.text = generateStrongPassword()
                            }

                            ToolTip {
                                visible: genMouse.containsMouse
                                text: "Generate strong password"
                                delay: 600
                            }
                        }
                    }
                }

                // ── Website ───────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Website"
                        color: "#CCCCCC"
                        font { family: "Roboto"; pixelSize: 12; bold: true }
                    }

                    TextField {
                        id: websiteField
                        width: parent.width
                        height: 44
                        placeholderText: "https://example.com"
                        background: Rectangle {
                            color: "#1E1E1E"; radius: 8
                            border.color: websiteField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font { family: "Roboto"; pixelSize: 13 }
                    }
                }

                // ── Category ──────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Category"
                        color: "#CCCCCC"
                        font { family: "Roboto"; pixelSize: 12; bold: true }
                    }

                    ComboBox {
                        id: categoryCombo
                        width: parent.width
                        height: 44
                        model: ["General", "Work", "Social", "Banking", "Shopping", "Other"]
                        currentIndex: 0  // Default to "General"

                        background: Rectangle {
                            color: "#1E1E1E"; radius: 8
                            border.color: categoryCombo.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: categoryCombo.displayText
                            color: "#FFFFFF"
                            leftPadding: 12
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                        }
                        indicator: Text {
                            text: categoryCombo.popup.visible ? "\u25B2" : "\u25BC"
                            color: "#666666"
                            font.pixelSize: 10
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        }
                        delegate: ItemDelegate {
                            width: categoryCombo.width
                            contentItem: Text {
                                text: modelData
                                color: "#FFFFFF"
                                leftPadding: 12
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                            }
                            background: Rectangle {
                                color: parent.highlighted ? "#2A2A2A" : "#1E1E1E"
                            }
                        }
                        popup: Popup {
                            y: categoryCombo.height + 2
                            width: categoryCombo.width
                            padding: 0
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: categoryCombo.delegateModel
                                currentIndex: categoryCombo.highlightedIndex
                            }
                            background: Rectangle {
                                color: "#1E1E1E"
                                border.color: "#444444"
                                border.width: 1
                                radius: 8
                            }
                        }
                    }
                }

                Text {
                    text: "* Required fields"
                    color: "#555555"
                    anchors.right: parent.right
                    font { family: "Roboto"; pixelSize: 11; italic: true }
                }

                // ── Error message ─────────────────────────────────────────────
                Text {
                    id: errorText
                    text: ""
                    color: "#FF4444"
                    visible: text.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { family: "Roboto"; pixelSize: 12 }
                }

                // ── Buttons ───────────────────────────────────────────────────
                Row {
                    anchors.right: parent.right
                    spacing: 12

                    Button {
                        text: "Cancel"
                        width: 110
                        height: 44
                        hoverEnabled: true
                        background: Rectangle {
                            color: parent.hovered ? "#333333" : "#242424"
                            radius: 8
                            border.color: "#444444"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: "#CCCCCC"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font { family: "Roboto"; pixelSize: 14; bold: true }
                        }
                        onClicked: stackView.pop()
                        scale: pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                    }

                    Button {
                        id: addButton
                        text: "Add"
                        width: 110
                        height: 44
                        hoverEnabled: true
                        enabled: titleField.text.length > 0 &&
                                 usernameField.text.length > 0 &&
                                 passwordField.text.length > 0

                        background: Rectangle {
                            color: addButton.enabled
                                   ? (addButton.hovered ? "#aa22ff" : "#9900FF")
                                   : "#333333"
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font { family: "Roboto"; pixelSize: 14; bold: true }
                        }

                        onClicked: {
                            errorText.text = ""

                            // Получаем выбранную категорию
                            var selectedCategory = categoryCombo.currentText || "General"
                            console.log("Saving with category:", selectedCategory)

                            // Передаем категорию в addPassword
                            PasswordModel.addPassword(
                                titleField.text.trim(),
                                usernameField.text.trim(),
                                passwordField.text,
                                websiteField.text.trim(),
                                selectedCategory  // Передаем категорию пятым параметром
                            )

                            var json = PasswordModel.toJson()
                            console.log("JSON to save:", json)
                            
                            if (fileManager.savePasswords(json)) {
                                stackView.pop()
                            } else {
                                PasswordModel.removePassword(PasswordModel.count() - 1)
                                errorText.text = "Failed to save. Check disk permissions."
                            }
                        }

                        scale: pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                    }
                }

                Item { width: 1; height: 8 }
            }
        }
    }

    function generateStrongPassword() {
        var length  = 18
        var lower   = "abcdefghjkmnpqrstuvwxyz"
        var upper   = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        var digits  = "23456789"
        var special = "!@#$%^&*-_=+"
        var charset = lower + upper + digits + special
        var pwd = ""
        // Ensure at least one of each required character type
        pwd += lower.charAt(Math.floor(Math.random() * lower.length))
        pwd += upper.charAt(Math.floor(Math.random() * upper.length))
        pwd += digits.charAt(Math.floor(Math.random() * digits.length))
        pwd += special.charAt(Math.floor(Math.random() * special.length))
        for (var i = 4; i < length; i++) {
            pwd += charset.charAt(Math.floor(Math.random() * charset.length))
        }
        // Shuffle the result so required chars aren't always at the start
        return pwd.split("").sort(function() { return Math.random() - 0.5 }).join("")
    }
}