import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    property string service:   ""
    property string url:       ""
    property string username:  ""
    property string password:  ""
    property string itemId:    ""
    property int    itemIndex: -1
    property string category:  ""

    signal deleteRequested(int idx)
    signal editRequested(var passwordData)

    width: parent ? parent.width : 600
    height: 66
    color: hoverArea.containsMouse ? "#242424" : "#1E1E1E"
    radius: 8
    Behavior on color { ColorAnimation { duration: 120 } }

    // ── Диалог подтверждения удаления ────────────────────────────────────────
    Rectangle {
        id: deleteConfirm
        visible: false
        anchors.fill: parent
        radius: 8
        color: "#1E1E1E"
        z: 10

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: "Удалить «" + root.service + "»?"
                color: "#FFFFFF"
                font.pixelSize: 13
                font.family: "Roboto"
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 70
                height: 28
                radius: 6
                color: yesMouse.containsMouse ? "#8B0000" : "#5A1A1A"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    text: "Удалить"
                    color: "#FF6666"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: yesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        deleteConfirm.visible = false
                        root.deleteRequested(root.itemIndex)
                    }
                }
            }

            Rectangle {
                width: 60
                height: 28
                radius: 6
                color: noMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    text: "Отмена"
                    color: "#AAAAAA"
                    font.pixelSize: 12
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: noMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deleteConfirm.visible = false
                }
            }
        }
    }

    Rectangle {
        id: iconRect
        width: 36
        height: 36
        radius: 8
        color: "#2A2A2A"
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.service.length > 0 ? root.service.charAt(0).toUpperCase() : "?"
            color: "#9900FF"
            font.pixelSize: 16
            font.bold: true
            anchors.centerIn: parent
        }
    }

    Column {
        id: infoCol
        anchors {
            left: iconRect.right
            leftMargin: 12
            right: btnRow.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        Row {
            spacing: 8
            width: parent.width
            Text {
                text: root.service
                color: "#FFFFFF"
                font.family: "Roboto"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width * 0.5)
                maximumLineCount: 1
            }
            Text {
                text: root.url
                color: "#555555"
                font.family: "Roboto"
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width - Math.min(implicitWidth, parent.width * 0.5) - 8
            }
        }

        Row {
            spacing: 10
            width: parent.width
            Text {
                text: root.username
                color: "#888888"
                font.family: "Roboto"
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width * 0.45
            }
            Text {
                text: showPwd.checked ? root.password : "\u2022".repeat(Math.min(root.password.length, 10))
                color: "#9900FF"
                font.family: "Roboto"
                font.pixelSize: 12
                font.letterSpacing: showPwd.checked ? 0 : 3
                elide: Text.ElideRight
                width: parent.width * 0.55
            }
        }
    }

    Row {
        id: btnRow
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 6

        // ✏ Edit
        Rectangle {
            width: 32
            height: 28
            radius: 6
            color: editMouse.containsMouse ? "#3A1A6A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                text: "\u270F"
                color: editMouse.containsMouse ? "#BB44FF" : "#888888"
                font.pixelSize: 14
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            MouseArea {
                id: editMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.editRequested({
                    itemId:    root.itemId,
                    itemIndex: root.itemIndex,
                    service:   root.service,
                    username:  root.username,
                    password:  root.password,
                    url:       root.url,
                    category:  root.category
                })
            }
            ToolTip { visible: editMouse.containsMouse; text: "Редактировать запись"; delay: 500 }
        }

        // 👁 Show/hide
        Rectangle {
            id: showPwd
            property bool checked: false
            width: 32
            height: 28
            radius: 6
            color: showPwdMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                text: showPwd.checked ? "\uD83D\uDE48" : "\uD83D\uDC41"
                font.pixelSize: 14
                anchors.centerIn: parent
            }
            MouseArea {
                id: showPwdMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: showPwd.checked = !showPwd.checked
            }
        }

        // COPY
        Rectangle {
            width: 48
            height: 28
            radius: 6
            color: copyMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                id: copyLabel
                text: "COPY"
                color: "#CCCCCC"
                font.pixelSize: 10
                font.bold: true
                anchors.centerIn: parent
            }
            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var dummy = Qt.createQmlObject(
                        'import QtQuick 2.15; TextEdit { visible: false }',
                        root, "copyHelper")
                    dummy.text = root.password
                    dummy.selectAll()
                    dummy.copy()
                    dummy.destroy()
                    copyLabel.text = "\u2713 OK"
                    copyLabel.color = "#00C851"
                    copyResetTimer.restart()
                }
            }
            Timer {
                id: copyResetTimer
                interval: 1500
                onTriggered: {
                    copyLabel.text = "COPY"
                    copyLabel.color = "#CCCCCC"
                }
            }
        }

        // ✕ Delete
        Rectangle {
            width: 28
            height: 28
            radius: 6
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
                id: deleteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: deleteConfirm.visible = true
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
    }
}
