import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    property string service:   ""
    property string url:       ""
    property string username:  ""
    property string password:  ""
    property int    itemIndex: -1

    signal deleteRequested(int idx)

    width:  parent ? parent.width : 600
    height: 66
    color:  hoverArea.containsMouse ? "#242424" : "#1E1E1E"
    radius: 8
    Behavior on color { ColorAnimation { duration: 120 } }

    // ── Service icon placeholder ──────────────────────────────────────────────
    Rectangle {
        id: iconRect
        width: 36
        height: 36
        radius: 8
        color: "#2A2A2A"
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }

        Text {
            text: root.service.length > 0 ? root.service.charAt(0).toUpperCase() : "?"
            color: "#9900FF"
            font { pixelSize: 16; bold: true }
            anchors.centerIn: parent
        }
    }

    // ── Text info ─────────────────────────────────────────────────────────────
    Column {
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
                font { family: "Roboto"; pixelSize: 14; bold: true }
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                text: root.url
                color: "#555555"
                font { family: "Roboto"; pixelSize: 11 }
                elide: Text.ElideRight
                width: parent.width - 120
            }
        }

        Row {
            spacing: 10
            width: parent.width

            Text {
                text: root.username
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
                font { family: "Roboto"; pixelSize: 12; letterSpacing: showPwd.checked ? 0 : 3 }
            }
        }
    }

    // ── Button row ────────────────────────────────────────────────────────────
    Row {
        id: btnRow
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 6

        // Show/hide password toggle
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

        // Copy password button
        Rectangle {
            id: copyBtn
            width: 48
            height: 28
            radius: 6
            color: copyMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: copyLabel
                text: "COPY"
                color: "#CCCCCC"
                font { pixelSize: 10; bold: true }
                anchors.centerIn: parent
            }

            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Copy password to clipboard
                    var dummy = Qt.createQmlObject(
                        'import QtQuick 2.15; TextEdit { visible: false }',
                        root, "copyHelper")
                    dummy.text = root.password
                    dummy.selectAll()
                    dummy.copy()
                    dummy.destroy()

                    // Visual feedback
                    copyLabel.text = "✓ OK"
                    copyLabel.color = "#00C851"
                    copyResetTimer.restart()
                }
            }

            Timer {
                id: copyResetTimer
                interval: 1500
                onTriggered: {
                    copyLabel.text  = "COPY"
                    copyLabel.color = "#CCCCCC"
                }
            }
        }

        // Delete button
        Rectangle {
            id: deleteBtn
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
                onClicked: root.deleteRequested(root.itemIndex)
            }
        }
    }

    // Hover detector for background
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        // Don't block child MouseAreas
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
    }
}
