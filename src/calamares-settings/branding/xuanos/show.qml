import QtQuick 2.15;
import calamares.slideshow 1.0;

Presentation {
    id: presentation
    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0E2A52"
            Text {
                anchors.centerIn: parent
                color: "#FFFFFF"
                font.pixelSize: 26
                font.family: "Inter"
                text: "xuan OS — Linux 的自由，Windows 的易用"
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#08162E"
            Text {
                anchors.centerIn: parent
                color: "#C9D8EE"
                font.pixelSize: 22
                font.family: "Inter"
                wrapMode: Text.WordWrap
                text: "Wine 与 Bottles 让 Windows 程序开箱即用"
            }
        }
    }
}
