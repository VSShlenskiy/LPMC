import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    id: root
    visible: true
    width: 906
    height: 540
    minimumWidth: 906
    maximumWidth: 906
    minimumHeight: 540
    maximumHeight: 540
    title: "LPMC"
    color: "#111111"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint

    StackView {
        id: stackView
        anchors {
            top:    parent.top
            topMargin: 32
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
        }

        initialItem: Item {
            // Welcome screen
            Rectangle {
                anchors.fill: parent
                color: "#111111"

                Text {
                    id: titleText
                    text: "WELCOME TO LPMC"
                    color: "#9900FF"
                    anchors {
                        top: parent.top
                        topMargin: 120
                        horizontalCenter: parent.horizontalCenter
                    }
                    font {
                        family: "Roboto"
                        pixelSize: 56
                        bold: true
                    }
                    opacity: 0
                    scale: 0.8

                    SequentialAnimation on opacity {
                        running: true
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                    }
                    SequentialAnimation on scale {
                        running: true
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.OutBack }
                    }
                }

                Text {
                    text: "Secure local password manager"
                    color: "#666666"
                    anchors {
                        top: titleText.bottom
                        topMargin: 8
                        horizontalCenter: parent.horizontalCenter
                    }
                    font { family: "Roboto"; pixelSize: 15 }
                    opacity: 0
                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation { duration: 300 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }

                Button {
                    id: startButton
                    width: 280
                    height: 52
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 310
                    }
                    hoverEnabled: true
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: true
                        PauseAnimation { duration: 500 }
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
                    }

                    background: Rectangle {
                        color: startButton.hovered ? "#aa22ff" : "#9900FF"
                        radius: 12
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    contentItem: Text {
                        text: "GET STARTED"
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font { family: "Roboto"; pixelSize: 16; bold: true; letterSpacing: 1 }
                    }

                    onClicked: {
                        if (fileManager.isMasterPasswordSet()) {
                            stackView.push("qrc:/admission.qml")
                        } else {
                            stackView.push("qrc:/regPage.qml")
                        }
                    }

                    scale: pressed ? 0.95 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }

    TitleBar {
        id: titleBar
        targetWindow: root
        title: "LPMC"
        z: 100
    }
}
