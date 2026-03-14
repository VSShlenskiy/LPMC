import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.9

Window {
    id: root
    visible: true
    width: 906; height: 540
    minimumWidth: 906; maximumWidth: 906
    minimumHeight: 540; maximumHeight: 540
    title: "LPMC"
    color: "#111111"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint
    StackView {
        id: stackView
        anchors.fill: parent
        anchors.top: parent.top
        anchors.topMargin: 32   // ← только здесь, страницы не трогаем
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        initialItem: Item {
            Text {
                id: titleText
                text: "WELCOME TO LPMC"
                color: "#9900FF"
                anchors {
                    top: parent.top
                    topMargin: 150
                    horizontalCenter: parent.horizontalCenter
                }
                font {
                    family: "Roboto" 
                    pixelSize: 64
                    bold: true
                    italic: false
                }
                opacity: 0
                scale: 0.8
                
                SequentialAnimation on opacity {
                    running: true
                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutQuad }
                }
                
                SequentialAnimation on scale {
                    running: true
                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.OutBack }
                }
            }
            
            Button {
                id: myButton
                width: 300; height: 50
                anchors.verticalCenterOffset: 100
                anchors.centerIn: parent
                hoverEnabled: false
                opacity: 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }
                
                Component.onCompleted: {
                    opacity = 1
                }
                
                Text {
                    id: myButtonText
                    text: "GET STARTED"
                    color: "#111111"
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.bold: true
                    font.pointSize: 18
                    font {
                        family: "Roboto" 
                        italic: false
                    }
                }
                
                onClicked: {
                    if(fileManager.isMasterPasswordSet()){
                        stackView.push("admission.qml")
                    }
                    else{
                        stackView.push("regPage.qml")
                    }
                }
                
                scale: pressed ? 0.9 : 1.0
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 150 
                        easing.type: Easing.InOutQuad
                    }
                }
                
                background: Rectangle {
                    color: "#9900FF"
                    radius: 12
                    border.width: 0 
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