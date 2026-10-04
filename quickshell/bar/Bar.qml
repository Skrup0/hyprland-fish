import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config

// One taskbar per screen:
// [Start][workspaces] [windows ..........] [tray] [VOL][BAT][Notif][clock]
// No background of its own: the buttons float directly over the wallpaper.
PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "plasticbar"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        anchors.topMargin: 8
        anchors.bottomMargin: 5
        spacing: 4

        StartButton {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Workspaces {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Taskbar {
            screen: bar.screen
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SysTray {
            Layout.fillHeight: true
        }

        VolumeButton {
            Layout.fillHeight: true
        }

        BatteryButton {
            Layout.fillHeight: true
        }

        NotifButton {
            Layout.fillHeight: true
        }

        Clock {
            Layout.fillHeight: true
        }
    }
}
