import QtQuick 2.0

Item {
    id: root
    width: 800
    height: 440

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"

        Text {
            anchors.centerIn: parent
            text: "Installing NetLinux Desktop..."
            color: "#00e87b"
            font.pixelSize: 24
            font.family: "DejaVu Sans"
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Linux Engineering. Applied AI. Energy Decarbonisation."
            color: "#666666"
            font.pixelSize: 14
            font.family: "DejaVu Sans"
        }
    }
}
