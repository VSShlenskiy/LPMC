import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: editPage

    property string pwdId:       ""
    property string pwdTitle:    ""
    property string pwdUsername: ""
    property string pwdPassword: ""
    property string pwdWebsite:  ""
    property string pwdCategory: "General"

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

                // ── Header ────────────────────────────────────────────────────
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: backMouse.containsMouse ? "#222222" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        text: "\u2190"
                        color: backMouse.containsMouse ? "#9900FF" : "#888888"
                        font.pixelSize: 20
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stackView.pop()
                    }
                }

                Text {
                    text: "LPMC"
                    color: "#9900FF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Roboto"
                    font.pixelSize: 28
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    text: "Edit Password"
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Roboto"
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    text: "Edit your password information"
                    color: "#888888"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Roboto"
                    font.pixelSize: 12
                }

                Item { width: 1; height: 4 }

                // ── Title ─────────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Title *"
                        color: "#CCCCCC"
                        font.family: "Roboto"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    TextField {
                        id: titleField
                        width: parent.width
                        height: 44
                        text: editPage.pwdTitle
                        placeholderText: "Gmail, GitHub, Netflix…"
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 8
                            border.color: titleField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font.family: "Roboto"
                        font.pixelSize: 13
                    }
                }

                // ── Username / Email ──────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Username / Email *"
                        color: "#CCCCCC"
                        font.family: "Roboto"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    TextField {
                        id: usernameField
                        width: parent.width
                        height: 44
                        text: editPage.pwdUsername
                        placeholderText: "user@example.com"
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 8
                            border.color: usernameField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font.family: "Roboto"
                        font.pixelSize: 13
                    }
                }

                // ── Password ──────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Password *"
                        color: "#CCCCCC"
                        font.family: "Roboto"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        TextField {
                            id: passwordField
                            width: parent.width - 52
                            height: 44
                            text: editPage.pwdPassword
                            placeholderText: "Введите пароль"
                            echoMode: showPassToggle.checked ? TextInput.Normal : TextInput.Password
                            background: Rectangle {
                                color: "#1E1E1E"
                                radius: 8
                                border.color: passwordField.activeFocus ? "#9900FF" : "#333333"
                                border.width: 1
                            }
                            color: "#FFFFFF"
                            placeholderTextColor: "#555555"
                            leftPadding: 12
                            font.family: "Roboto"
                            font.pixelSize: 13
                        }

                        Rectangle {
                            id: showPassToggle
                            property bool checked: false
                            width: 44
                            height: 44
                            radius: 8
                            color: showPassMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
                            border.color: "#444444"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                text: showPassToggle.checked ? "\uD83D\uDE48" : "\uD83D\uDC41"
                                font.pixelSize: 16
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                id: showPassMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showPassToggle.checked = !showPassToggle.checked
                            }
                            ToolTip {
                                visible: showPassMouse.containsMouse
                                text: showPassToggle.checked ? "Скрыть пароль" : "Показать пароль"
                                delay: 500
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
                        font.family: "Roboto"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    TextField {
                        id: websiteField
                        width: parent.width
                        height: 44
                        text: editPage.pwdWebsite
                        placeholderText: "https://example.com"
                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 8
                            border.color: websiteField.activeFocus ? "#9900FF" : "#333333"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#555555"
                        leftPadding: 12
                        font.family: "Roboto"
                        font.pixelSize: 13
                    }
                }

                // ── Category ──────────────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Category"
                        color: "#CCCCCC"
                        font.family: "Roboto"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    ComboBox {
                        id: categoryCombo
                        width: parent.width
                        height: 44
                        model: ["General", "Work", "Social", "Banking", "Shopping", "Other"]

                        Component.onCompleted: {
                            var i = model.indexOf(editPage.pwdCategory)
                            currentIndex = i >= 0 ? i : 0
                        }

                        background: Rectangle {
                            color: "#1E1E1E"
                            radius: 8
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
                            anchors {
                                right: parent.right
                                rightMargin: 14
                                verticalCenter: parent.verticalCenter
                            }
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
                    font.family: "Roboto"
                    font.pixelSize: 11
                    font.italic: true
                }

                Text {
                    id: errorText
                    text: ""
                    color: "#FF4444"
                    visible: text.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Roboto"
                    font.pixelSize: 12
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
                            text: parent.text
                            color: "#CCCCCC"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "Roboto"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        onClicked: stackView.pop()
                        scale: pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                    }

                    Button {
                        id: saveBtn
                        text: "Save Changes"
                        width: 130
                        height: 44
                        hoverEnabled: true
                        enabled: titleField.text.length > 0 &&
                                 usernameField.text.length > 0 &&
                                 passwordField.text.length > 0
                        background: Rectangle {
                            color: saveBtn.enabled
                                   ? (saveBtn.hovered ? "#aa22ff" : "#9900FF")
                                   : "#333333"
                            radius: 8
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "Roboto"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        onClicked: {
                            errorText.text = ""
                            PasswordModel.updatePasswordFull(
                                editPage.pwdId,
                                titleField.text.trim(),
                                usernameField.text.trim(),
                                passwordField.text,
                                websiteField.text.trim(),
                                categoryCombo.currentText
                            )
                            if (fileManager.savePasswords(PasswordModel.toJson())) {
                                stackView.pop()
                            } else {
                                errorText.text = "Couldn't save. Check the access rights."
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
}
