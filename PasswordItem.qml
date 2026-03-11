import QtQuick 2.9
import QtQuick.Controls 2.9

Rectangle {
    id: root
    property string service
    property string url
    property string username
    property string password
    
    width: parent ? parent.width : 400
    height: 70
    color: "#1E1E1E"
    radius: 8
    
    Column {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 15
        }
        spacing: 5
        
        Row {
            width: parent.width
            spacing: 10
            
            Text {
                text: root.service
                color: "#FFFFFF"
                font {
                    family: "Roboto"
                    pixelSize: 14
                    bold: true
                }
            }
            
            Text {
                text: root.url
                color: "#666666"
                font {
                    family: "Roboto"
                    pixelSize: 11
                }
                elide: Text.ElideRight
                width: parent.width - 200
            }
        }
        
        Row {
            width: parent.width
            spacing: 10
            
            Text {
                text: root.username
                color: "#AAAAAA"
                font {
                    family: "Roboto"
                    pixelSize: 12
                }
                width: parent.width - 100
                elide: Text.ElideRight
            }
            
            Text {
                text: root.password
                color: "#9900FF"
                font {
                    family: "Roboto"
                    pixelSize: 12
                    letterSpacing: 2
                }
            }
        }
    }
    
    Rectangle {
        width: 30
        height: 30
        radius: 5
        color: "#333333"
        anchors {
            right: parent.right
            rightMargin: 15
            verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: "COPY"
            color: "#FFFFFF"
            anchors.centerIn: parent
            font.pixelSize: 10
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Copy password for", root.service)
            }
        }
    }
}