import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 906
    height: 508
    color: "#111111"

    // ── App-password dialog ───────────────────────────────────────────────────
    Rectangle {
        id: appPwdOverlay
        visible: false
        anchors.fill: parent
        color: "#88000000"
        z: 10

        Rectangle {
            width: 460
            height: 300
            radius: 14
            color: "#1A1A1A"
            border.color: "#333333"
            border.width: 1
            anchors.centerIn: parent

            Column {
                anchors { fill: parent; margins: 28 }
                spacing: 16

                Text {
                    text: "App Password Required"
                    color: "#FFFFFF"
                    font { family: "Roboto"; pixelSize: 16; bold: true }
                }

                Text {
                    text: "Enter the app password for " + appPwdDomain.text
                    color: "#AAAAAA"
                    font { family: "Roboto"; pixelSize: 12 }
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Text {
                    id: appPwdDomain
                    text: ""
                    visible: false
                }

                TextField {
                    id: appPwdInput
                    placeholderText: "App password"
                    echoMode: TextInput.Password
                    width: parent.width
                    height: 40
                    background: Rectangle {
                        color: "#111111"; radius: 8
                        border.color: appPwdInput.activeFocus ? "#9900FF" : "#333333"
                        border.width: 1
                    }
                    color: "#FFFFFF"
                    placeholderTextColor: "#666666"
                    leftPadding: 12
                    font.pixelSize: 13
                }

                Text {
                    text: "How to get an app password?"
                    color: "#9900FF"
                    font { family: "Roboto"; pixelSize: 11; underline: true }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(emailSender.appPasswordUrl(appPwdDomain.text))
                    }
                }

                Row {
                    spacing: 12
                    width: parent.width

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 38; radius: 8
                        color: cancelDlgMa.containsMouse ? "#333333" : "#222222"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            text: "Cancel"
                            color: "#AAAAAA"
                            anchors.centerIn: parent
                            font { family: "Roboto"; pixelSize: 13 }
                        }
                        MouseArea {
                            id: cancelDlgMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appPwdOverlay.visible = false
                                appPwdInput.text = ""
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 38; radius: 8
                        color: confirmDlgMa.containsMouse ? "#aa22ff" : "#9900FF"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            text: "Send Recovery Email"
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                            font { family: "Roboto"; pixelSize: 12; bold: true }
                        }
                        MouseArea {
                            id: confirmDlgMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appPwdInput.text.length === 0) return
                                var domain = appPwdDomain.text
                                fileManager.saveSmtpAppPassword(domain, appPwdInput.text)
                                appPwdOverlay.visible = false
                                doSendRecovery(appPwdInput.text)
                                appPwdInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Status overlay ────────────────────────────────────────────────────────
    Rectangle {
        id: statusOverlay
        visible: false
        anchors.fill: parent
        color: "#88000000"
        z: 10

        Rectangle {
            width: 360
            height: 180
            radius: 14
            color: "#1A1A1A"
            border.color: "#333333"
            border.width: 1
            anchors.centerIn: parent

            Column {
                anchors { fill: parent; margins: 24 }
                spacing: 16

                Text {
                    id: statusTitle
                    text: "Sending..."
                    color: "#FFFFFF"
                    font { family: "Roboto"; pixelSize: 15; bold: true }
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    id: statusMessage
                    text: ""
                    color: "#AAAAAA"
                    font { family: "Roboto"; pixelSize: 12 }
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 120; height: 36; radius: 8
                    color: statusCloseMa.containsMouse ? "#aa22ff" : "#9900FF"
                    visible: statusTitle.text !== "Sending..."
                    anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        text: "OK"
                        color: "#FFFFFF"
                        anchors.centerIn: parent
                        font { family: "Roboto"; pixelSize: 13; bold: true }
                    }
                    MouseArea {
                        id: statusCloseMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: statusOverlay.visible = false
                    }
                }
            }
        }
    }

    // ── Main login card ───────────────────────────────────────────────────────
    Rectangle {
        id: mainWindow
        width: 510
        height: 420
        color: "#111111"
        radius: 20
        anchors.centerIn: parent
        border.color: "#333333"
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
            font { family: "Roboto"; pixelSize: 32; bold: true; letterSpacing: 2 }
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
            font { family: "Roboto"; pixelSize: 14 }
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
            font { family: "Roboto"; pixelSize: 20; bold: true }
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
            font { family: "Roboto"; pixelSize: 12 }
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
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        TextField {
            id: masterPass
            placeholderText: "Enter your master password"
            echoMode: TextInput.Password
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
                border.color: masterPass.activeFocus ? "#9900FF" : "#333333"
                border.width: 1
            }

            color: "#FFFFFF"
            placeholderTextColor: "#666666"
            leftPadding: 12
            font.pixelSize: 14

            onAccepted: attemptUnlock()
        }

        Text {
            id: errorText
            text: "Incorrect password"
            color: "#FF4444"
            visible: false
            anchors {
                top: masterPass.bottom
                topMargin: 5
                right: masterPass.right
            }
            font { family: "Roboto"; pixelSize: 11; bold: true }
        }

        Button {
            id: unlockButton
            text: "UNLOCK"
            anchors {
                top: masterPass.bottom
                topMargin: 30
                horizontalCenter: parent.horizontalCenter
            }
            width: 430
            height: 45
            enabled: masterPass.text.length > 0
            hoverEnabled: true

            onClicked: attemptUnlock()

            background: Rectangle {
                color: unlockButton.enabled
                       ? (unlockButton.hovered ? "#aa22ff" : "#9900FF")
                       : "#333333"
                radius: 8
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font { family: "Roboto"; pixelSize: 14; bold: true; letterSpacing: 1 }
            }

            scale: pressed ? 0.95 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
            }
        }

        // ── Forgot password link ──────────────────────────────────────────────
        Text {
            id: forgotLink
            text: "Forgot password?"
            color: forgotMa.containsMouse ? "#bb44ff" : "#9900FF"
            anchors {
                top: unlockButton.bottom
                topMargin: 14
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 12; underline: true }
            Behavior on color { ColorAnimation { duration: 100 } }

            MouseArea {
                id: forgotMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: initiateRecovery()
            }
        }

        Text {
            text: "Your data is encrypted and stored locally on your device"
            color: "#555555"
            anchors {
                top: forgotLink.bottom
                topMargin: 12
                horizontalCenter: parent.horizontalCenter
            }
            font { family: "Roboto"; pixelSize: 10 }
        }
    }

    // ── Animations & timers ───────────────────────────────────────────────────
    SequentialAnimation {
        id: shakeAnimation
        property real originX: 0

        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x + 20; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: masterPass.x - 10; duration: 50 }
        NumberAnimation { target: masterPass; property: "x"; to: shakeAnimation.originX; duration: 50 }
    }

    Timer {
        id: hideErrorTimer
        interval: 3000
        onTriggered: errorText.visible = false
    }

    // ── Email-sender connections ──────────────────────────────────────────────
    Connections {
        target: emailSender
        function onEmailSent() {
            statusTitle.text = "Email Sent ✓"
            statusMessage.text = "Recovery email sent successfully.\nCheck your inbox and delete the message after reading."
        }
        function onEmailFailed(error) {
            statusTitle.text = "Failed to Send"
            statusMessage.text = "Error: " + error
        }
    }

    // ── Logic ─────────────────────────────────────────────────────────────────
    function attemptUnlock() {
        if (fileManager.verifyMasterPassword(masterPass.text)) {
            var json = fileManager.loadPasswords()
            PasswordModel.fromJson(json)
            stackView.push("qrc:/homePage.qml")
        } else {
            errorText.visible = true
            shakeAnimation.originX = masterPass.x
            shakeAnimation.start()
            hideErrorTimer.restart()
            masterPass.selectAll()
        }
    }

    function initiateRecovery() {
        var email = fileManager.getUserEmail()
        if (email === "") {
            statusTitle.text = "No Recovery Email"
            statusMessage.text = "No recovery email is configured.\nPlease contact your administrator or reinstall."
            statusOverlay.visible = true
            return
        }

        var domain = emailSender.domainOf(email)
        var appPwd = fileManager.getSmtpAppPassword(domain)

        if (appPwd === "") {
            // Need to ask for app-password
            appPwdDomain.text = domain
            emailSender.detectSmtp(email)
            appPwdOverlay.visible = true
        } else {
            doSendRecovery(appPwd)
        }
    }

    function doSendRecovery(appPwd) {
        var email = fileManager.getUserEmail()
        var masterPwd = fileManager.getMasterPassword()

        emailSender.setSenderCredentials(email, appPwd)
        emailSender.detectSmtp(email)

        statusTitle.text = "Sending..."
        statusMessage.text = "Sending recovery email to " + email + "..."
        statusOverlay.visible = true

        emailSender.sendPasswordRecoveryEmail(email, masterPwd)
    }
}
