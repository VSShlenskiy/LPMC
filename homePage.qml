import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: homePage_root
    width: 906
    height: 508
    color: "#0A0A0A"

    // Поиск
    property string searchFilter: ""

    // Выбранная категория
    property string selectedCategory: "All"

    // ── Top bar ───────────────────────────────────────────────────────────────
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
            font {
                family: "Roboto"
                pixelSize: 24
                bold: true
            }
        }

        Text {
            text: "Password Manager"
            color: "#555555"
            anchors {
                left: logoText.right
                leftMargin: 10
                bottom: logoText.bottom
                bottomMargin: 4
            }
            font {
                family: "Roboto"
                pixelSize: 11
            }
        }

        Text {
            text: "ALL PASSWORDS"
            color: "#FFFFFF"
            anchors {
                left: parent.left
                leftMargin: 240
                verticalCenter: parent.verticalCenter
            }
            font {
                family: "Roboto"
                pixelSize: 18
                bold: true
                letterSpacing: 1
            }
        }

        // Settings button
        Rectangle {
            id: settingsBtn
            width: 38
            height: 38
            radius: 8
            color: settingsMouse.containsMouse ? "#222222" : "transparent"

            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                text: "⚙"
                color: settingsMouse.containsMouse ? "#9900FF" : "#666666"
                font.pixelSize: 22
                anchors.centerIn: parent

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stackView.push("qrc:/settingPage.qml")
            }
        }
    }

    // ── Content ───────────────────────────────────────────────────────────────
    Rectangle {
        id: contentArea

        anchors {
            top: topBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        color: "#0A0A0A"

        // ── Left panel (categories) ───────────────────────────────────────────
        Rectangle {
            id: leftPanel
            width: 190

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: 16
            }

            color: "#111111"
            radius: 10

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 14
                }

                spacing: 12

                Text {
                    text: "Categories"
                    color: "#FFFFFF"

                    font {
                        family: "Roboto"
                        pixelSize: 13
                        bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#2A2A2A"
                }

                // All category
                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: selectedCategory === "All" ? "#2A2A2A" : "transparent"

                    Text {
                        text: "All"
                        color: "#FFFFFF"

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }

                        font {
                            family: "Roboto"
                            pixelSize: 13
                        }
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: "#9900FF"

                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: PasswordModel.count()
                            color: "#FFFFFF"
                            anchors.centerIn: parent

                            font {
                                pixelSize: 11
                                bold: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = "All"
                    }
                }

                // Categories list
                ListView {
                    id: categoriesList
                    width: parent.width
                    height: Math.min(count * 36, leftPanel.height - 100)
                    clip: true
                    spacing: 4

                    model: ["General", "Work", "Social", "Banking", "Shopping", "Other"]

                    currentIndex: {
                        var cats = ["General", "Work", "Social", "Banking", "Shopping", "Other"]
                        return cats.indexOf(selectedCategory)
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Beginning)
                    }

                    delegate: Rectangle {
                        width: categoriesList.width
                        height: 32
                        radius: 6
                        color: selectedCategory === modelData ? "#2A2A2A" : "transparent"

                        Text {
                            text: modelData
                            color: selectedCategory === modelData ? "#FFFFFF" : "#666666"

                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            font {
                                family: "Roboto"
                                pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: selectedCategory = modelData
                        }
                    }
                }
            }
        }

        // ── Right panel (password list) ───────────────────────────────────────
        Rectangle {
            id: rightPanel

            anchors {
                top: parent.top
                bottom: actionRow.top
                left: leftPanel.right
                right: parent.right
                topMargin: 16
                bottomMargin: 8
                leftMargin: 10
                rightMargin: 16
            }

            color: "#111111"
            radius: 10

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }

                spacing: 14

                // Search bar
                Rectangle {
                    width: parent.width
                    height: 38
                    color: "#1E1E1E"
                    radius: 8
                    border.color: searchInput.activeFocus ? "#9900FF" : "#2A2A2A"
                    border.width: 1

                    Text {
                        text: "🔍"
                        color: "#555555"
                        font.pixelSize: 14

                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    TextInput {
                        id: searchInput

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 32
                            rightMargin: 10
                        }

                        color: "#FFFFFF"
                        font.pixelSize: 13
                        clip: true

                        onTextChanged: searchFilter = text.toLowerCase()

                        Text {
                            text: "Search passwords..."
                            color: "#444444"
                            visible: !searchInput.text.length
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 13
                        }
                    }
                }

                // Password list
                ListView {
                    id: passwordList
                    width: parent.width
                    height: rightPanel.height - 70
                    clip: true
                    spacing: 0
                    model: PasswordModel

                    onModelChanged: passwordList.positionViewAtBeginning()

                    function scrollToFirst() {
                        for (var i = 0; i < passwordList.count; i++) {
                            var item = passwordList.itemAtIndex(i)
                            if (item && item.matchesFilter) {
                                passwordList.positionViewAtIndex(i, ListView.Beginning)
                                return
                            }
                        }
                        passwordList.positionViewAtBeginning()
                    }

                    Connections {
                        target: homePage_root
                        function onSelectedCategoryChanged() { passwordList.scrollToFirst() }
                        function onSearchFilterChanged()     { passwordList.scrollToFirst() }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No passwords saved yet.\nClick ADD PASSWORD to get started."
                        color: "#444444"
                        horizontalAlignment: Text.AlignHCenter

                        font {
                            family: "Roboto"
                            pixelSize: 14
                        }

                        visible: passwordList.count === 0
                        lineHeight: 1.7
                    }

                    delegate: Item {
                        property string itemCategory: model.category || "General"
                        property bool matchesFilter:
                            model.title.toLowerCase().indexOf(searchFilter) >= 0
                            && (selectedCategory === "All" || itemCategory === selectedCategory)

                        width: passwordList.width
                        height: matchesFilter ? 74 : 0  // 66 + 8 bottom gap
                        clip: true
                        visible: matchesFilter

                        PasswordItem {
                            width: parent.width
                            service: model.title
                            username: model.username
                            password: model.password
                            url: model.website
                            itemId: model.itemId
                            category: model.category || "General"
                            itemIndex: index

                            onDeleteRequested: function(idx) {
                                PasswordModel.removePassword(idx)
                                fileManager.savePasswords(PasswordModel.toJson())
                            }
                        }
                    }
                }
            }
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            id: actionRow

            anchors {
                bottom: parent.bottom
                bottomMargin: 20
                right: parent.right
                rightMargin: 32
            }

            spacing: 12

            Button {
                text: "ADD PASSWORD"
                width: 148
                height: 40
                hoverEnabled: true

                background: Rectangle {
                    color: parent.hovered ? "#aa22ff" : "#9900FF"
                    radius: 8

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font {
                        family: "Roboto"
                        pixelSize: 12
                        bold: true
                    }
                }

                onClicked: stackView.push("qrc:/generatePasswordPage.qml")

                scale: pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Button {
                text: "LOCK VAULT"
                width: 130
                height: 40
                hoverEnabled: true

                background: Rectangle {
                    color: parent.hovered ? "#3A3A3A" : "#2A2A2A"
                    radius: 8
                    border.color: "#444444"
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "#CCCCCC"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    font {
                        family: "Roboto"
                        pixelSize: 12
                        bold: true
                    }
                }

                onClicked: {
                    PasswordModel.fromJson("[]")
                    stackView.push("qrc:/admission.qml")
                }

                scale: pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}