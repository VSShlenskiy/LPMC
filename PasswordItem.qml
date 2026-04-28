import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    // ── Свойства ──────────────────────────────────────────────────────────
    property string service:   ""
    property string url:       ""
    property string username:  ""
    property string password:  ""
    property string itemId:    ""   
    property int    itemIndex: -1

    signal deleteRequested(int idx)

    property string rotationState: "idle"
    property string rotationError: ""

    // ── Размеры и стиль ───────────────────────────────────────────────────
    width:  parent ? parent.width : 600
    height: rotationState === "error" && rotationError.length > 0 ? 82 : 66
    color:  hoverArea.containsMouse ? "#242424" : "#1E1E1E"
    radius: 8

    Behavior on color  { ColorAnimation { duration: 120 } }
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // ── Подписка на сигналы rotationManager ──────────────────────────────
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
            // Показываем ошибку только для элемента, который инициировал ротацию
            if (root.rotationState === "rotating") {
                root.rotationState = "error"
                root.rotationError = "Расширение браузера не подключено"
                errorResetTimer.restart()
            }
        }
    }

    Timer {
        id: successResetTimer
        interval: 3000
        onTriggered: root.rotationState = "idle"
    }

    Timer {
        id: errorResetTimer
        interval: 5000
        onTriggered: {
            root.rotationState = "idle"
            root.rotationError = ""
        }
    }

    // ── Service icon ──────────────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width: 36; height: 36; radius: 8
        color: "#2A2A2A"
        anchors {
            left:          parent.left
            leftMargin:    12
            verticalCenter: parent.verticalCenter
        }

        Text {
            text:  root.service.length > 0 ? root.service.charAt(0).toUpperCase() : "?"
            color: "#9900FF"
            font { pixelSize: 16; bold: true }
            anchors.centerIn: parent
        }
    }

    // ── Text info + error row ─────────────────────────────────────────────
    Column {
        anchors {
            left:          iconRect.right;  leftMargin:  12
            right:         btnRow.left;     rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        // Строка 1: название + URL
        Row {
            spacing: 8
            width: parent.width

            Text {
                text:  root.service
                color: "#FFFFFF"
                font { family: "Roboto"; pixelSize: 14; bold: true }
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Text {
                text:  root.url
                color: "#555555"
                font { family: "Roboto"; pixelSize: 11 }
                elide: Text.ElideRight
                width: parent.width - 120
            }
        }

        // Строка 2: логин + пароль (маскированный)
        Row {
            spacing: 10
            width: parent.width

            Text {
                text:  root.username
                color: "#888888"
                font { family: "Roboto"; pixelSize: 12 }
                elide: Text.ElideRight
                width: parent.width - 100
            }
            Text {
                text: showPwd.checked
                    ? root.password
                    : "\u2022".repeat(Math.min(root.password.length, 10))
                color: "#9900FF"
                font {
                    family: "Roboto"; pixelSize: 12
                    letterSpacing: showPwd.checked ? 0 : 3
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

            Behavior on opacity { NumberAnimation { duration: 200 } }
            opacity: visible ? 1.0 : 0.0
        }
    }

    // ── Button row ────────────────────────────────────────────────────────
    Row {
        id: btnRow
        anchors {
            right:         parent.right;  rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 6

        // ── Показать/скрыть пароль ────────────────────────────────────────
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

        // ── Копировать пароль ─────────────────────────────────────────────
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
                    dummy.selectAll()
                    dummy.copy()
                    dummy.destroy()
                    copyLabel.text  = "✓ OK"
                    copyLabel.color = "#00C851"
                    copyResetTimer.restart()
                }
            }
            Timer {
                id: copyResetTimer; interval: 1500
                onTriggered: {
                    copyLabel.text  = "COPY"
                    copyLabel.color = "#CCCCCC"
                }
            }
        }

        // ── Кнопка ротации пароля 🔄 ──────────────────────────────────────
        Rectangle {
            id: rotateBtn
            width: 28; height: 28; radius: 6

            // Кнопку показываем только если задан URL
            visible: root.url.length > 0

            // Цвет фона по состоянию
            color: {
                if (root.rotationState === "rotating") return "#1A1A2E"
                if (root.rotationState === "success")  return "#0D2E1A"
                if (root.rotationState === "error")    return "#2E1A1A"
                return rotateMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            // Иконка
            Text {
                id: rotateIcon
                anchors.centerIn: parent
                font.pixelSize: 14

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

                // Вращение иконки в процессе ротации
                RotationAnimation on rotation {
                    running:  root.rotationState === "rotating"
                    loops:    Animation.Infinite
                    from:     0; to: 360; duration: 1200
                }
            }

            // Tooltip подсказка
            ToolTip {
                id: rotateTip
                visible: rotateMouse.containsMouse
                delay:   500
                text: {
                    if (root.rotationState === "idle")     return "Автозамена пароля через браузер"
                    if (root.rotationState === "rotating") return "Выполняется смена пароля..."
                    if (root.rotationState === "success")  return "Пароль успешно изменён!"
                    if (root.rotationState === "error")    return root.rotationError || "Ошибка"
                    return ""
                }
            }

            MouseArea {
                id: rotateMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                // Блокируем повторный клик пока идёт ротация
                enabled: root.rotationState === "idle"

                onClicked: {
                    if (root.itemId.length === 0) {
                        console.warn("[LPMC] PasswordItem: itemId is empty, cannot rotate. " +
                                     "Убедитесь что в ListView передаётся itemId: model.itemId")
                        return
                    }
                    rotationManager.rotate(root.itemId)
                }
            }
        }

        // ── Удалить запись ────────────────────────────────────────────────
        Rectangle {
            id: deleteBtn
            width: 28; height: 28; radius: 6
            color: deleteMouse.containsMouse ? "#5A1A1A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                text: "\u2715"
                color: deleteMouse.containsMouse ? "#FF5555" : "#666666"
                font.pixelSize: 12
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            MouseArea {
                id: deleteMouse; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.deleteRequested(root.itemIndex)
            }
        }
    }

    // ── Hover detector ────────────────────────────────────────────────────
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
    }
}
