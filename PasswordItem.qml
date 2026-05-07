import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    // ── Свойства ──────────────────────────────────────────────────────────────
    property string service:   ""
    property string url:       ""
    property string username:  ""
    property string password:  ""
    property string itemId:    ""   // UUID записи — нужен для rotationManager.rotate()
    property string category:  ""
    property int    itemIndex: -1

    signal deleteRequested(int idx)

    // ── Состояние ротации: "idle" | "rotating" | "success" | "error" ─────────
    property string rotationState: "idle"
    property string rotationError: ""

    // ── Ожидание подтверждения удаления ──────────────────────────────────────
    property bool confirmDelete: false

    // ── Размеры и стиль ───────────────────────────────────────────────────────
    width:  parent ? parent.width : 600
    height: rotationState === "error" && rotationError.length > 0 ? 82 : 66
    color:  hoverArea.containsMouse ? "#242424" : "#1E1E1E"
    radius: 8

    Behavior on color  { ColorAnimation { duration: 120 } }
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // ── Подписка на сигналы rotationManager ──────────────────────────────────
    Connections {
        target: rotationManager

        function onRotationStarted(entryId) {
            if (entryId === root.itemId) {
                root.rotationState = "rotating"
                root.rotationError = ""
            }
        }

        function onRotationSucceeded(entryId) {
            if (entryId === root.itemId) {
                root.rotationState = "success"
                successResetTimer.restart()
            }
        }

        function onRotationFailed(entryId, reason) {
            if (entryId === root.itemId) {
                root.rotationState = "error"
                root.rotationError = reason
                errorResetTimer.restart()
            }
        }

        function onNoExtensionConnected() {
            if (root.rotationState === "rotating") {
                root.rotationState = "error"
                root.rotationError = "Расширение браузера не подключено"
                errorResetTimer.restart()
            }
        }
    }

    Timer { id: successResetTimer; interval: 3000; onTriggered: root.rotationState = "idle" }
    Timer {
        id: errorResetTimer; interval: 5000
        onTriggered: { root.rotationState = "idle"; root.rotationError = "" }
    }

    // ── Service icon ──────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width: 36; height: 36; radius: 8
        color: "#2A2A2A"
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }

        Text {
            text:  root.service.length > 0 ? root.service.charAt(0).toUpperCase() : "?"
            color: "#9900FF"
            font { pixelSize: 16; bold: true }
            anchors.centerIn: parent
        }
    }

    // ── Text info + строка ошибки ─────────────────────────────────────────────
    Column {
        anchors {
            left:           iconRect.right; leftMargin:  12
            right:          btnRow.left;    rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        // Строка 1: название + URL
        Row {
            spacing: 8
            width: parent.width

            Text {
                id: serviceLbl
                text:  root.service
                color: "#FFFFFF"
                font { family: "Roboto"; pixelSize: 14; bold: true }
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, parent.width * 0.4)
            }
            Text {
                text:  root.url
                color: "#555555"
                font { family: "Roboto"; pixelSize: 11 }
                elide: Text.ElideRight
                width: parent.width - serviceLbl.width - 8
            }
        }

        // Строка 2: логин | пароль — оба с явной шириной, пароль не уходит под кнопки
        Row {
            spacing: 8
            width: parent.width

            Text {
                id: usernameLbl
                text:  root.username
                color: "#888888"
                font { family: "Roboto"; pixelSize: 12 }
                elide: Text.ElideRight
                width: Math.floor(parent.width * 0.42)
            }

            Text {
                width: parent.width - usernameLbl.width - 8
                text: showPwd.checked
                    ? root.password
                    : "\u2022".repeat(Math.min(root.password.length, 12))
                color: "#9900FF"
                elide: Text.ElideRight
                font {
                    family: "Roboto"; pixelSize: 12
                    letterSpacing: showPwd.checked ? 0 : 2
                }
            }
        }

        // Строка 3: ошибка ротации (видна только при state === "error")
        Text {
            visible: root.rotationState === "error" && root.rotationError.length > 0
            text:    "⚠  " + root.rotationError
            color:   "#FF5555"
            font { family: "Roboto"; pixelSize: 10 }
            width: parent.width
            elide: Text.ElideRight
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // ── Button row ────────────────────────────────────────────────────────────
    Row {
        id: btnRow
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 6

        // ── Показать/скрыть пароль ────────────────────────────────────────────
        Rectangle {
            id: showPwd
            property bool checked: false
            width: 32; height: 28; radius: 6
            color: showPwdMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                text: showPwd.checked ? "\uD83D\uDE48" : "\uD83D\uDC41"
                font.pixelSize: 14
                anchors.centerIn: parent
            }
            MouseArea {
                id: showPwdMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: showPwd.checked = !showPwd.checked
            }
        }

        // ── Копировать пароль ─────────────────────────────────────────────────
        Rectangle {
            id: copyBtn
            width: 48; height: 28; radius: 6
            color: copyMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: copyLabel
                text: "COPY"; color: "#CCCCCC"
                font { pixelSize: 10; bold: true }
                anchors.centerIn: parent
            }
            MouseArea {
                id: copyMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var dummy = Qt.createQmlObject(
                        'import QtQuick 2.15; TextEdit { visible: false }',
                        root, "copyHelper")
                    dummy.text = root.password
                    dummy.selectAll(); dummy.copy(); dummy.destroy()
                    copyLabel.text  = "✓ OK"
                    copyLabel.color = "#00C851"
                    copyResetTimer.restart()
                }
            }
            Timer {
                id: copyResetTimer; interval: 1500
                onTriggered: { copyLabel.text = "COPY"; copyLabel.color = "#CCCCCC" }
            }
        }

        // ── Авторотация пароля 🔄 ─────────────────────────────────────────────
        Rectangle {
            id: rotateBtn
            width: 28; height: 28; radius: 6
            visible: root.url.length > 0

            color: {
                if (root.rotationState === "rotating") return "#1A1A2E"
                if (root.rotationState === "success")  return "#0D2E1A"
                if (root.rotationState === "error")    return "#2E1A1A"
                return rotateMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                id: rotateIcon; anchors.centerIn: parent; font.pixelSize: 14
                text: {
                    if (root.rotationState === "rotating") return "⏳"
                    if (root.rotationState === "success")  return "✓"
                    if (root.rotationState === "error")    return "✕"
                    return "🔄"
                }
                color: {
                    if (root.rotationState === "success") return "#00C851"
                    if (root.rotationState === "error")   return "#FF5555"
                    return rotateMouse.containsMouse ? "#FFFFFF" : "#AAAAAA"
                }
                Behavior on color { ColorAnimation { duration: 150 } }
                RotationAnimation on rotation {
                    running: root.rotationState === "rotating"
                    loops: Animation.Infinite; from: 0; to: 360; duration: 1200
                }
            }

            ToolTip {
                visible: rotateMouse.containsMouse; delay: 500
                text: {
                    if (root.rotationState === "idle")     return "Автозамена пароля через браузер"
                    if (root.rotationState === "rotating") return "Выполняется смена пароля..."
                    if (root.rotationState === "success")  return "Пароль успешно изменён!"
                    return root.rotationError || "Ошибка"
                }
            }

            MouseArea {
                id: rotateMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                enabled: root.rotationState === "idle"
                onClicked: {
                    if (root.itemId.length === 0) {
                        console.warn("[LPMC] itemId пуст — передайте itemId: model.itemId в делегате")
                        return
                    }
                    rotationManager.rotate(root.itemId)
                }
            }
        }

        // ── Редактировать ✏ → открывает EditPassword.qml ─────────────────────
        Rectangle {
            width: 28; height: 28; radius: 6
            color: editBtnMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                text: "✏"; font.pixelSize: 13; anchors.centerIn: parent
                color: editBtnMouse.containsMouse ? "#FFFFFF" : "#888888"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            ToolTip { visible: editBtnMouse.containsMouse; delay: 500; text: "Редактировать" }

            MouseArea {
                id: editBtnMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    stackView.push("qrc:/EditPassword.qml", {
                        pwdId:       root.itemId,
                        pwdTitle:    root.service,
                        pwdUsername: root.username,
                        pwdPassword: root.password,
                        pwdWebsite:  root.url,
                        pwdCategory: root.category
                    })
                }
            }
        }

        // ── Удалить ✕ ─────────────────────────────────────────────────────────
        Rectangle {
            id: deleteBtn
            width: 28; height: 28; radius: 6
            color: deleteMouse.containsMouse ? "#5A1A1A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                text: "\u2715"; font.pixelSize: 12; anchors.centerIn: parent
                color: deleteMouse.containsMouse ? "#FF5555" : "#666666"
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            MouseArea {
                id: deleteMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.confirmDelete = true
                    confirmResetTimer.restart()
                }
            }
            ToolTip { visible: deleteMouse.containsMouse; delay: 500; text: "Удалить" }
        }
    }

    // ── Оверлей подтверждения удаления — по центру карточки ──────────────────
    Rectangle {
        id: confirmOverlay
        anchors.fill: parent
        radius: parent.radius
        visible: root.confirmDelete
        opacity: root.confirmDelete ? 1 : 0
        color: "#CC1A1A1A"

        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Таймер автосброса (3 сек без действия → отмена)
        Timer {
            id: confirmResetTimer
            interval: 3000
            onTriggered: root.confirmDelete = false
        }

        // Две кнопки строго по центру карточки
        Row {
            anchors.centerIn: parent
            spacing: 10

            // Отмена
            Rectangle {
                width: 90; height: 32; radius: 7
                color: cancelConfirmMa.containsMouse ? "#3A3A3A" : "#2A2A2A"
                border.color: "#555555"; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    text: "Отмена"
                    color: cancelConfirmMa.containsMouse ? "#FFFFFF" : "#AAAAAA"
                    font { family: "Roboto"; pixelSize: 12; bold: true }
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea {
                    id: cancelConfirmMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.confirmDelete = false
                        confirmResetTimer.stop()
                    }
                }
            }

            // Удалить
            Rectangle {
                width: 90; height: 32; radius: 7
                color: yesConfirmMa.containsMouse ? "#CC2222" : "#991111"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    text: "Удалить"
                    color: "#FFFFFF"
                    font { family: "Roboto"; pixelSize: 12; bold: true }
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: yesConfirmMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.confirmDelete = false
                        confirmResetTimer.stop()
                        root.deleteRequested(root.itemIndex)
                    }
                }
            }
        }
    }

    // ── Hover-детектор фона ───────────────────────────────────────────────────
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
    }
}
