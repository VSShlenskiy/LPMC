import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: titleBar
    width: parent ? parent.width : 906
    height: 32
    color: "#1a1a1a"
    z: 100

    property var    targetWindow: null
    property string title: "LPMC"

    // Drag to move window
    MouseArea {
        id: dragArea
        anchors { left: parent.left; right: minBtn.left; top: parent.top; bottom: parent.bottom }
        property point clickPos

        onPressed:         clickPos = Qt.point(mouse.x, mouse.y)
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

    // Minimize button
    Rectangle {
        id: minBtn
        width: 46
        height: 32
        anchors.right: closeBtn.left
        color: minMa.containsMouse ? "#444444" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            text: "\u2014"
            color: "#CCCCCC"
            font.pixelSize: 14
            anchors.centerIn: parent
        }
        MouseArea {
            id: minMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { if (targetWindow) targetWindow.showMinimized() }
        }
    }

    // Close button
    Rectangle {
        id: closeBtn
        width: 46
        height: 32
        anchors.right: parent.right
        color: closeMa.containsMouse ? "#e81123" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            text: "\u2715"
            color: "#CCCCCC"
            font.pixelSize: 13
            anchors.centerIn: parent
        }
        MouseArea {
            id: closeMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { if (targetWindow) targetWindow.close() }
        }
    }
}
