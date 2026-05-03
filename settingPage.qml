import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: settingsPageRoot
    width: 906
    height: 508
    color: "#0A0A0A"

    property string selectedLanguage: AppSettings.language
    property string selectedTheme:    AppSettings.theme
    property int    rotationDays:     AppSettings.rotationDays
    property bool   rotationEnabled:  AppSettings.rotationEnabled

    // ── Add App Password Dialog ───────────────────────────────────────────────
    Rectangle {
        id: addPwdOverlay
        visible: false
        anchors.fill: parent
        color: "#88000000"
        z: 20

        property string editDomain: ""
        property bool   isCustom:   false

        Rectangle {
            width: 480
            height: addPwdOverlay.isCustom ? 420 : 340
            radius: 14
            color: "#1A1A1A"
            border.color: "#333333"
            border.width: 1
            anchors.centerIn: parent
            Behavior on height { NumberAnimation { duration: 150 } }

            Column {
                anchors { fill: parent; margins: 28 }
                spacing: 14

                Text {
                    text: addPwdOverlay.editDomain === ""
                        ? "Add App Password"
                        : "Edit: " + addPwdOverlay.editDomain
                    color: "#FFFFFF"
                    font { family: "Roboto"; pixelSize: 16; bold: true }
                }

                Text { text: "Email Service"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }

                Rectangle {
                    width: parent.width; height: 40; radius: 8
                    color: "#111111"; border.color: "#333333"; border.width: 1

                    Text {
                        id: serviceLabel; text: serviceCombo.currentText; color: "#FFFFFF"
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        font { family: "Roboto"; pixelSize: 13 }
                    }
                    Text { text: "▾"; color: "#9900FF"; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } }

                    ComboBox {
                        id: serviceCombo; anchors.fill: parent; opacity: 0
                        model: ["gmail.com","yandex.ru","yandex.com","mail.ru","inbox.ru","list.ru","bk.ru",
                                "outlook.com","hotmail.com","live.com","icloud.com","yahoo.com","rambler.ru","Custom..."]
                        onCurrentTextChanged: addPwdOverlay.isCustom = (currentText === "Custom...")
                    }
                }

                Column {
                    visible: addPwdOverlay.isCustom; width: parent.width; spacing: 10
                    Row {
                        width: parent.width; spacing: 10
                        Column {
                            width: parent.width * 0.65 - 5; spacing: 4
                            Text { text: "SMTP Host"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }
                            TextField {
                                id: customHost; placeholderText: "smtp.example.com"; width: parent.width; height: 36
                                background: Rectangle { color: "#111111"; radius: 8; border.color: "#333333"; border.width: 1 }
                                color: "#FFFFFF"; placeholderTextColor: "#555555"; leftPadding: 10; font.pixelSize: 12
                            }
                        }
                        Column {
                            width: parent.width * 0.35 - 5; spacing: 4
                            Text { text: "Port"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }
                            TextField {
                                id: customPort; placeholderText: "465"; width: parent.width; height: 36
                                background: Rectangle { color: "#111111"; radius: 8; border.color: "#333333"; border.width: 1 }
                                color: "#FFFFFF"; placeholderTextColor: "#555555"; leftPadding: 10; font.pixelSize: 12
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: sslCheck.checked ? "#9900FF" : "#111111"; border.color: "#555555"; border.width: 1
                            CheckBox { id: sslCheck; anchors.fill: parent; opacity: 0; checked: true }
                            Text { text: "✓"; color: "#FFFFFF"; anchors.centerIn: parent; font.pixelSize: 11; visible: sslCheck.checked }
                            MouseArea { anchors.fill: parent; onClicked: sslCheck.checked = !sslCheck.checked }
                        }
                        Text { text: "Use SSL (port 465)"; color: "#CCCCCC"; font { family: "Roboto"; pixelSize: 12 } }
                    }
                }

                Text { text: "App Password"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }

                TextField {
                    id: appPwdField; placeholderText: "Paste your app password here"
                    echoMode: TextInput.Password; width: parent.width; height: 40
                    background: Rectangle { color: "#111111"; radius: 8; border.color: appPwdField.activeFocus ? "#9900FF" : "#333333"; border.width: 1 }
                    color: "#FFFFFF"; placeholderTextColor: "#555555"; leftPadding: 12; font.pixelSize: 13
                }

                Text {
                    text: "How to get an app password for " +
                          (addPwdOverlay.isCustom ? "this service" : serviceCombo.currentText) + "?"
                    color: "#9900FF"
                    font { family: "Roboto"; pixelSize: 11; underline: true }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(emailSender.appPasswordUrl(addPwdOverlay.isCustom ? "" : serviceCombo.currentText))
                    }
                }

                Row {
                    spacing: 12; width: parent.width
                    Rectangle {
                        width: (parent.width - 12) / 2; height: 38; radius: 8
                        color: dlgCancelMa.containsMouse ? "#333333" : "#222222"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { text: "Cancel"; color: "#AAAAAA"; anchors.centerIn: parent; font { family: "Roboto"; pixelSize: 13 } }
                        MouseArea { id: dlgCancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { addPwdOverlay.visible = false; appPwdField.text = "" } }
                    }
                    Rectangle {
                        width: (parent.width - 12) / 2; height: 38; radius: 8
                        color: dlgSaveMa.containsMouse ? "#aa22ff" : "#9900FF"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { text: "Save"; color: "#FFFFFF"; anchors.centerIn: parent; font { family: "Roboto"; pixelSize: 13; bold: true } }
                        MouseArea {
                            id: dlgSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appPwdField.text.length === 0) return
                                var domain = addPwdOverlay.isCustom
                                    ? (customHost.text.length > 0 ? customHost.text : "custom")
                                    : serviceCombo.currentText
                                if (addPwdOverlay.isCustom && customHost.text.length > 0)
                                    emailSender.setManualSmtp(customHost.text, parseInt(customPort.text) || 465, sslCheck.checked)
                                fileManager.saveSmtpAppPassword(domain, appPwdField.text)
                                addPwdOverlay.visible = false
                                appPwdField.text = ""
                                appPasswordsModel.reload()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Test email status toast ───────────────────────────────────────────────
    Rectangle {
        id: testToast
        visible: false; width: 340; height: 48; radius: 10
        anchors { bottom: parent.bottom; bottomMargin: 24; horizontalCenter: parent.horizontalCenter }
        color: testToastSuccess ? "#1a3a1a" : "#3a1a1a"
        border.color: testToastSuccess ? "#00C851" : "#FF4444"; border.width: 1; z: 30
        property bool testToastSuccess: true

        Text { id: toastText; text: ""; color: testToast.testToastSuccess ? "#00C851" : "#FF4444"; anchors.centerIn: parent; font { family: "Roboto"; pixelSize: 12; bold: true } }
        Timer { id: toastTimer; interval: 3500; onTriggered: testToast.visible = false }
    }

    // ── EmailSender connections ───────────────────────────────────────────────
    Connections {
        target: emailSender
        function onEmailSent() { testToast.testToastSuccess = true; toastText.text = "✓ Test email sent successfully!"; testToast.visible = true; toastTimer.restart() }
        function onEmailFailed(error) { testToast.testToastSuccess = false; toastText.text = "✗ " + error; testToast.visible = true; toastTimer.restart() }
    }

    // ── App passwords list model ──────────────────────────────────────────────
    ListModel {
        id: appPasswordsModel
        function reload() {
            clear()
            var map = fileManager.getAllSmtpAppPasswords()
            for (var key in map) { append({ domain: key, masked: "••••••••" }) }
        }
        Component.onCompleted: reload()
    }

    // ── Top bar ───────────────────────────────────────────────────────────────
    Rectangle {
        id: topBar; width: parent.width; height: 70; color: "#111111"

        Rectangle {
            id: backBtn; width: 36; height: 36; radius: 8
            color: backMa.containsMouse ? "#222222" : "transparent"
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { text: "\u2190"; color: backMa.containsMouse ? "#9900FF" : "#AAAAAA"; font.pixelSize: 22; anchors.centerIn: parent; Behavior on color { ColorAnimation { duration: 120 } } }
            MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: stackView.pop() }
        }

        Text { text: "SETTINGS"; color: "#FFFFFF"; anchors { left: backBtn.right; leftMargin: 14; verticalCenter: parent.verticalCenter }; font { family: "Roboto"; pixelSize: 18; bold: true; letterSpacing: 1 } }
        Text { text: "LPMC"; color: "#9900FF"; anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }; font { family: "Roboto"; pixelSize: 18; bold: true } }
    }

    // ── Three-column layout ───────────────────────────────────────────────────
    Row {
        anchors {
            top: topBar.bottom; bottom: saveArea.top
            left: parent.left; right: parent.right
            margins: 20; topMargin: 16; bottomMargin: 8
        }
        spacing: 14

        // ── Language column ───────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 28) / 3; height: parent.height; color: "#111111"; radius: 12

            Column {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
                spacing: 12

                Row { spacing: 8; Text { text: "\uD83C\uDF10"; font.pixelSize: 18 }; Text { text: "Language"; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 15; bold: true }; anchors.verticalCenter: parent.verticalCenter } }
                Text { text: "Interface language"; color: "#555555"; font { family: "Roboto"; pixelSize: 11 } }
                Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                Repeater {
                    model: [
                        { code: "English",    flag: "\uD83C\uDDEC\uD83C\uDDE7", label: "English"  },
                        { code: "Russian",    flag: "\uD83C\uDDF7\uD83C\uDDFA", label: "Русский"  },
                        { code: "Lithuanian", flag: "\uD83C\uDDF1\uD83C\uDDF9", label: "Lietuvių" }
                    ]
                    delegate: Rectangle {
                        width: parent.width; height: 44; radius: 8
                        color: langMa.containsMouse ? "#1E1E1E" : (settingsPageRoot.selectedLanguage === modelData.code ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle { width: 3; height: 20; radius: 2; color: "#9900FF"; visible: settingsPageRoot.selectedLanguage === modelData.code; anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter } }
                        Text { text: modelData.flag; font.pixelSize: 16; anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } }
                        Text { text: modelData.label; color: settingsPageRoot.selectedLanguage === modelData.code ? "#FFFFFF" : "#AAAAAA"; font { family: "Roboto"; pixelSize: 13 }; anchors { left: parent.left; leftMargin: 42; verticalCenter: parent.verticalCenter } }
                        Text { text: "\u2713"; color: "#9900FF"; font.pixelSize: 13; visible: settingsPageRoot.selectedLanguage === modelData.code; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } }
                        MouseArea { id: langMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsPageRoot.selectedLanguage = modelData.code }
                    }
                }
            }
        }

        // ── Theme column ──────────────────────────────────────────────────────
        Rectangle {
            width: (parent.width - 28) / 3; height: parent.height; color: "#111111"; radius: 12

            Column {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
                spacing: 12

                Row { spacing: 8; Text { text: "\uD83C\uDFA8"; font.pixelSize: 18 }; Text { text: "Theme"; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 15; bold: true }; anchors.verticalCenter: parent.verticalCenter } }
                Text { text: "Color theme"; color: "#555555"; font { family: "Roboto"; pixelSize: 11 } }
                Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                Repeater {
                    model: [
                        { code: "Dark",   label: "Dark",   swatches: ["#0A0A0A", "#1E1E1E", "#9900FF"] },
                        { code: "Light",  label: "Light",  swatches: ["#F0F0F0", "#E8E8E8", "#7700CC"] },
                        { code: "Purple", label: "Purple", swatches: ["#0D0017", "#2D0055", "#CC00FF"] }
                    ]
                    delegate: Rectangle {
                        width: parent.width; height: 48; radius: 8
                        color: themeMa.containsMouse ? "#1E1E1E" : (settingsPageRoot.selectedTheme === modelData.code ? "#1A0033" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle { width: 3; height: 24; radius: 2; color: "#9900FF"; visible: settingsPageRoot.selectedTheme === modelData.code; anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter } }
                        Row {
                            id: swatchRow; spacing: 3
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            Repeater { model: modelData.swatches; Rectangle { width: 16; height: 16; radius: 3; color: modelData; border.color: "#333333"; border.width: 1 } }
                        }
                        Text { text: modelData.label; color: settingsPageRoot.selectedTheme === modelData.code ? "#FFFFFF" : "#AAAAAA"; font { family: "Roboto"; pixelSize: 13 }; anchors { left: swatchRow.right; leftMargin: 10; verticalCenter: parent.verticalCenter } }
                        Text { text: "\u2713"; color: "#9900FF"; font.pixelSize: 13; visible: settingsPageRoot.selectedTheme === modelData.code; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } }
                        MouseArea { id: themeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsPageRoot.selectedTheme = modelData.code }
                    }
                }
            }
        }

        // ── Email Recovery + Auto Rotation column ─────────────────────────────
        Rectangle {
            width: (parent.width - 28) / 3; height: parent.height; color: "#111111"; radius: 12; clip: true

            Flickable {
                anchors.fill: parent; contentHeight: emailCol.implicitHeight + 20; clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 2; color: "#9900FF"; implicitWidth: 4 }
                }

                Column {
                    id: emailCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
                    spacing: 12

                    // ── Email Recovery ────────────────────────────────────────
                    Row { spacing: 8; Text { text: "✉"; font.pixelSize: 18; color: "#9900FF" }; Text { text: "Email Recovery"; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 15; bold: true }; anchors.verticalCenter: parent.verticalCenter } }
                    Text { text: "Send master password to your email"; color: "#555555"; font { family: "Roboto"; pixelSize: 11 } }
                    Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                    Text { text: "Recovery Email"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }
                    TextField {
                        id: recoveryEmailField; text: fileManager.getUserEmail(); placeholderText: "your@email.com"; width: parent.width; height: 36
                        background: Rectangle { color: "#0A0A0A"; radius: 8; border.color: recoveryEmailField.activeFocus ? "#9900FF" : "#333333"; border.width: 1 }
                        color: "#FFFFFF"; placeholderTextColor: "#555555"; leftPadding: 10; font.pixelSize: 12
                        onEditingFinished: fileManager.saveUserEmail(text)
                    }

                    Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }
                    Text { text: "Configured App Passwords"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }

                    Repeater {
                        model: appPasswordsModel
                        delegate: Rectangle {
                            width: parent.width; height: 44; radius: 8; color: "#0A0A0A"; border.color: "#1E1E1E"; border.width: 1
                            Row {
                                anchors { left: parent.left; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 6
                                Column {
                                    width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter
                                    Text { text: model.domain; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 12; bold: true }; elide: Text.ElideRight; width: parent.width }
                                    Text { text: model.masked; color: "#555555"; font { family: "Roboto"; pixelSize: 11 } }
                                }
                                Rectangle {
                                    width: 36; height: 28; radius: 6
                                    color: testBtnMa.containsMouse ? "#1A1A1A" : "transparent"; border.color: "#333333"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { text: "▶"; color: "#9900FF"; font.pixelSize: 11; anchors.centerIn: parent }
                                    MouseArea {
                                        id: testBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { var email = recoveryEmailField.text; var pwd = fileManager.getSmtpAppPassword(model.domain); emailSender.setSenderCredentials(email, pwd); emailSender.detectSmtp(email); emailSender.sendTestEmail(email) }
                                    }
                                    ToolTip.visible: testBtnMa.containsMouse; ToolTip.text: "Send test email"; ToolTip.delay: 600
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 6
                                    color: delBtnMa.containsMouse ? "#3a0000" : "transparent"; border.color: "#330000"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { text: "✕"; color: "#FF4444"; font.pixelSize: 11; anchors.centerIn: parent }
                                    MouseArea { id: delBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { fileManager.deleteSmtpAppPassword(model.domain); appPasswordsModel.reload() } }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 36; radius: 8
                        color: addPwdMa.containsMouse ? "#1A0033" : "#0D0020"; border.color: "#9900FF"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row { anchors.centerIn: parent; spacing: 6; Text { text: "+"; color: "#9900FF"; font { pixelSize: 16; bold: true }; anchors.verticalCenter: parent.verticalCenter }; Text { text: "Add App Password"; color: "#9900FF"; font { family: "Roboto"; pixelSize: 12; bold: true }; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: addPwdMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { addPwdOverlay.editDomain = ""; addPwdOverlay.isCustom = false; appPwdField.text = ""; addPwdOverlay.visible = true } }
                    }

                    Text { text: "App passwords are encrypted and stored locally."; color: "#444444"; font { family: "Roboto"; pixelSize: 10; italic: true }; wrapMode: Text.WordWrap; width: parent.width }

                    // ── Auto Password Rotation ────────────────────────────────
                    Rectangle { width: parent.width; height: 1; color: "#1E1E1E" }

                    Row {
                        spacing: 8
                        Text { text: "🔁"; font.pixelSize: 18 }
                        Text { text: "Auto Password Rotation"; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 14; bold: true }; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Text { text: "Rotation interval"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11; bold: true } }

                    // Кнопки быстрого выбора
                    Flow {
                        width: parent.width; spacing: 6
                        Repeater {
                            model: [
                                { days: 30, label: "30 days" },
                                { days: 60, label: "60 days" },
                                { days: 90, label: "90 days" }
                            ]
                            delegate: Rectangle {
                                width: 72; height: 30; radius: 6
                                color: rotIntervalMa.containsMouse ? "#1E1E1E" : (settingsPageRoot.rotationDays === modelData.days ? "#1A0033" : "#0A0A0A")
                                border.color: settingsPageRoot.rotationDays === modelData.days ? "#9900FF" : "#333333"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { text: modelData.label; color: settingsPageRoot.rotationDays === modelData.days ? "#9900FF" : "#AAAAAA"; anchors.centerIn: parent; font { family: "Roboto"; pixelSize: 11; bold: settingsPageRoot.rotationDays === modelData.days } }
                                MouseArea { id: rotIntervalMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { settingsPageRoot.rotationDays = modelData.days; customDaysField.text = "" } }
                            }
                        }
                    }

                    // Свой интервал
                    Row {
                        spacing: 8; width: parent.width
                        Text { text: "Custom:"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11 }; anchors.verticalCenter: parent.verticalCenter }
                        TextField {
                            id: customDaysField; placeholderText: "N"; width: 54; height: 28
                            inputMethodHints: Qt.ImhDigitsOnly; validator: IntValidator { bottom: 1; top: 365 }
                            background: Rectangle { color: "#0A0A0A"; radius: 6; border.color: customDaysField.activeFocus ? "#9900FF" : "#333333"; border.width: 1 }
                            color: "#FFFFFF"; placeholderTextColor: "#555555"; leftPadding: 8; font.pixelSize: 12
                            onTextChanged: { var v = parseInt(text); if (!isNaN(v) && v > 0) settingsPageRoot.rotationDays = v }
                        }
                        Text { text: "days"; color: "#AAAAAA"; font { family: "Roboto"; pixelSize: 11 }; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // Тоггл вкл/выкл
                    Row {
                        spacing: 10; width: parent.width
                        Rectangle {
                            width: 36; height: 20; radius: 10
                            color: settingsPageRoot.rotationEnabled ? "#9900FF" : "#2A2A2A"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsPageRoot.rotationEnabled = !settingsPageRoot.rotationEnabled }
                            Rectangle {
                                width: 14; height: 14; radius: 7; color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                x: settingsPageRoot.rotationEnabled ? 19 : 3
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }
                        }
                        Text {
                            text: settingsPageRoot.rotationEnabled ? "Auto Rotation ON" : "Auto Rotation OFF"
                            color: settingsPageRoot.rotationEnabled ? "#9900FF" : "#555555"
                            font { family: "Roboto"; pixelSize: 12 }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // ── Save button ───────────────────────────────────────────────────────────
    Rectangle {
        id: saveArea; height: 64
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        color: "#0A0A0A"

        Rectangle {
            width: 120; height: 40; radius: 8
            color: saveMa.containsMouse ? "#aa22ff" : "#9900FF"
            anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
            Behavior on color { ColorAnimation { duration: 120 } }

            Text { text: "SAVE"; color: "#FFFFFF"; font { family: "Roboto"; pixelSize: 13; bold: true }; anchors.centerIn: parent }

            MouseArea {
                id: saveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    AppSettings.setTheme(settingsPageRoot.selectedTheme)
                    AppSettings.setLanguage(settingsPageRoot.selectedLanguage)
                    AppSettings.setRotationDays(settingsPageRoot.rotationDays)
                    AppSettings.setRotationEnabled(settingsPageRoot.rotationEnabled)
                    AppSettings.save()
                    if (recoveryEmailField.text.length > 0)
                        fileManager.saveUserEmail(recoveryEmailField.text)
                    stackView.pop()
                }
            }
        }
    }
}
