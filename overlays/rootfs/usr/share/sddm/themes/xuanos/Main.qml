import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SDDM 1.0

Rectangle {
    id: root
    width: 1280
    height: 720
    color: "#08162E"

    Image {
        id: background
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#08162E"
        opacity: 0.55
    }

    property int currentUserIndex: 0

    Component.onCompleted: {
        if (sddm.rememberLastUser && sddm.lastUser !== "") {
            for (var i = 0; i < sddm.users.count; ++i) {
                if (sddm.users.get(i).name === sddm.lastUser) {
                    root.currentUserIndex = i
                    break
                }
            }
        }
        passwordField.forceActiveFocus()
    }

    function doLogin() {
        if (sddm.users.count === 0)
            return
        var user = sddm.users.get(root.currentUserIndex).name
        var sessionFile = ""
        if (sddm.sessions.count > 0)
            sessionFile = sddm.sessions.get(sessionCombo.currentIndex).file
        sddm.login(user, passwordField.text, sessionFile)
    }

    Rectangle {
        id: card
        width: 430
        height: 560
        anchors.centerIn: parent
        radius: 22
        color: "#122647"
        opacity: 0.94
        layer.enabled: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 16

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 112
                height: 112

                Rectangle {
                    anchors.fill: parent
                    radius: 56
                    color: "#1E3D6B"
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 18
                    source: "xuanos-logo.svg"
                    sourceSize: Qt.size(76, 76)
                    visible: sddm.users.count === 0 || sddm.users.get(root.currentUserIndex).avatar === ""
                }

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: sddm.users.count > 0 ? sddm.users.get(root.currentUserIndex).avatar : ""
                    asynchronous: true
                    visible: sddm.users.count > 0 && sddm.users.get(root.currentUserIndex).avatar !== ""
                    Rectangle {
                        anchors.fill: parent
                        radius: 56
                        color: "transparent"
                        border.width: 2
                        border.color: "#2AA8FF"
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.family: "Inter"
                font.pixelSize: 20
                font.bold: true
                color: "#FFFFFF"
                text: sddm.users.count > 0 ? sddm.users.get(root.currentUserIndex).displayName : qsTr("No users available")
            }

            Label {
                id: errorLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.family: "Inter"
                font.pixelSize: 13
                color: "#FF7A85"
                text: ""
            }

            ComboBox {
                id: userCombo
                Layout.fillWidth: true
                visible: sddm.users.count > 1
                model: sddm.users
                textRole: "displayName"
                currentIndex: root.currentUserIndex
                onCurrentIndexChanged: root.currentUserIndex = currentIndex
                font.family: "Inter"
                font.pixelSize: 14
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                echoMode: TextInput.Password
                placeholderText: qsTr("Password")
                color: "#FFFFFF"
                font.family: "Inter"
                font.pixelSize: 15
                leftPadding: 14
                rightPadding: 14
                background: Rectangle {
                    radius: 12
                    color: passwordField.activeFocus ? "#0E2A52" : "#0C2244"
                    border.width: 1.5
                    border.color: passwordField.activeFocus ? "#2AA8FF" : "#24406B"
                }
                onAccepted: root.doLogin()
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                text: qsTr("Log in")
                font.family: "Inter"
                font.pixelSize: 16
                font.bold: true
                contentItem: Text {
                    text: loginButton.text
                    font: loginButton.font
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 12
                    color: loginButton.pressed ? "#005A9E" : "#0078D4"
                }
                onClicked: root.doLogin()
            }

            ComboBox {
                id: sessionCombo
                Layout.fillWidth: true
                model: sddm.sessions
                textRole: "name"
                font.family: "Inter"
                font.pixelSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Repeater {
                    model: [
                        { label: qsTr("Suspend"), action: function() { sddm.suspend() } },
                        { label: qsTr("Reboot"), action: function() { sddm.reboot() } },
                        { label: qsTr("Power off"), action: function() { sddm.powerOff() } }
                    ]

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: modelData.label
                        font.family: "Inter"
                        font.pixelSize: 13
                        contentItem: Text {
                            text: parent.text
                            color: "#C9D8EE"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font: parent.font
                        }
                        background: Rectangle {
                            radius: 10
                            color: "#1E3D6B"
                            border.width: 1
                            border.color: "#2A4E82"
                        }
                        onClicked: modelData.action()
                    }
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorLabel.text = qsTr("Login failed. Please check the password and try again.")
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
