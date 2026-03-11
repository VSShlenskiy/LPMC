import QtQuick 2.9
import QtQuick.Window 2.2

Rectangle {
    id: titleBar
    width: parent.width
    height: 32
    color: "#1a1a1a"
    z: 100

    property var targetWindow: null
    property string title: "LPMC"
    MouseArea {
        id: dragArea
        anchors.fill: parent
        property point clickPos
        onPressed: clickPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: {
            if (targetWindow) {
                targetWindow.x += mouse.x - clickPos.x
                targetWindow.y += mouse.y - clickPos.y
            }
        }
    }
    Text {
        text: titleBar.title
        color: "#9900FF"
        font { family: "Roboto"; pixelSize: 13; bold: true }
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
    }
    Rectangle {
        id: minBtn
        width: 46; height: 32
        anchors.right: closeBtn.left
        color: minMa.containsMouse ? "#444444" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            text: "—"
            color: "white"
            font.pixelSize: 14
            anchors.centerIn: parent
        }
        MouseArea {
            id: minMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                 if (targetWindow) targetWindow.showMinimized()
            }
        }
    }
    Rectangle {
        id: closeBtn
        width: 46; height: 32
        anchors.right: parent.right
        color: closeMa.containsMouse ? "#e81123" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            text: "✕"
            color: "white"
            font.pixelSize: 14
            anchors.centerIn: parent
        }
        MouseArea {
            id: closeMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (targetWindow) targetWindow.close()
            }
        }
    }
}