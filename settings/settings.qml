import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
  id: settings

  property string home: Quickshell.env("HOME")
  property var colors: ({
    background: "#141218",
    surface: "#141218",
    surface_container: "#211f24",
    surface_container_high: "#2b292f",
    on_surface: "#e6e0e9",
    on_surface_variant: "#cac4cf",
    primary: "#cfbdfe",
    on_primary: "#36275d",
    outline: "#948f99"
  })
  property int currentSection: 0
  property var sections: [
    "Appearance", "Desktop", "Displays", "Input", "Keybindings",
    "Power & Login", "Webapps", "Development", "Updates", "Recovery", "About"
  ]

  function sectionActions(index) {
    switch (index) {
    case 0:
      return [
        { label: "Auto mode", command: ["parmctl", "config", "set", ".appearance.mode", "\"auto\""] },
        { label: "Apply theme", command: ["parmctl", "theme", "apply"] },
        { label: "Wallpapers", command: ["dolphin", settings.home + "/Pictures"] }
      ]
    case 1:
      return [
        { label: "Bar on top", command: ["parmctl", "config", "set", ".shell.bar.position", "\"top\""] },
        { label: "Bar on bottom", command: ["parmctl", "config", "set", ".shell.bar.position", "\"bottom\""] },
        { label: "Reload shell", command: ["parmctl", "shell", "restart"] }
      ]
    case 2:
      return [
        { label: "Monitor report", command: ["alacritty", "-e", "hyprctl", "monitors", "all"] }
      ]
    case 3:
      return [
        { label: "Input devices", command: ["alacritty", "-e", "hyprctl", "devices"] }
      ]
    case 4:
      return [
        { label: "Show keybindings", command: ["alacritty", "-e", "jq", ".keybindings", settings.home + "/.config/parm/config.json"] }
      ]
    case 5:
      return [
        { label: "Wi-Fi", command: ["nm-connection-editor"] },
        { label: "Bluetooth", command: ["blueman-manager"] },
        { label: "Audio", command: ["pavucontrol"] },
        { label: "Printers", command: ["system-config-printer"] }
      ]
    case 6:
      return [
        { label: "List webapps", command: ["alacritty", "-e", "parmctl", "webapp", "list"] }
      ]
    case 7:
      return [
        { label: "Tool status", command: ["alacritty", "-e", "parmctl", "dev", "status"] }
      ]
    case 8:
      return [
        { label: "Run doctor", command: ["alacritty", "-e", "parmctl", "doctor", "--session"] }
      ]
    case 9:
      return [
        { label: "List backups", command: ["alacritty", "-e", "parmctl", "backup", "list"] },
        { label: "Recovery status", command: ["alacritty", "-e", "parmctl", "recovery"] }
      ]
    default:
      return [
        { label: "Validate configuration", command: ["alacritty", "-e", "parmctl", "config", "validate"] }
      ]
    }
  }

  FileView {
    id: themeFile
    path: settings.home + "/.cache/parm/themes/current/colors.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { settings.colors = JSON.parse(text()) }
      catch (error) { console.warn("Parm Settings theme:", error) }
    }
    onFileChanged: reload()
  }

  IpcHandler {
    target: "parm.settings"
    function show(): void { window.visible = true }
  }

  FloatingWindow {
    id: window
    title: "Parm Settings"
    visible: true
    color: settings.colors.background
    implicitWidth: 980
    implicitHeight: 700
    minimumSize: Qt.size(760, 520)

    RowLayout {
      anchors.fill: parent
      anchors.margins: 18
      spacing: 18

      Rectangle {
        Layout.preferredWidth: 220
        Layout.fillHeight: true
        radius: 24
        color: settings.colors.surface_container

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 5

          RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            Rectangle {
              implicitWidth: 48
              implicitHeight: 48
              radius: 16
              color: settings.colors.primary
              Column {
                anchors.centerIn: parent
                spacing: -3
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "00"
                  color: settings.colors.on_primary
                  font.pixelSize: 8
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Pm"
                  color: settings.colors.on_primary
                  font.pixelSize: 17
                  font.weight: Font.DemiBold
                }
              }
            }
            Text {
              text: "Parm"
              color: settings.colors.on_surface
              font.pixelSize: 24
              font.weight: Font.DemiBold
            }
          }

          Repeater {
            model: settings.sections
            Button {
              required property string modelData
              required property int index
              Layout.fillWidth: true
              text: modelData
              flat: true
              onClicked: settings.currentSection = index

              background: Rectangle {
                radius: 16
                color: settings.currentSection === parent.index
                  ? settings.colors.primary
                  : "transparent"
              }
              contentItem: Text {
                text: parent.text
                color: settings.currentSection === parent.index
                  ? settings.colors.on_primary
                  : settings.colors.on_surface_variant
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12
                font.pixelSize: 13
              }
            }
          }

          Item { Layout.fillHeight: true }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 24
        color: settings.colors.surface
        border.width: 1
        border.color: settings.colors.outline

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 28
          spacing: 18

          Text {
            text: settings.sections[settings.currentSection]
            color: settings.colors.on_surface
            font.pixelSize: 28
            font.weight: Font.DemiBold
          }

          Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: {
              var descriptions = [
                "Wallpaper-derived Material 3 colors, light and dark scheduling, KDE and terminal themes.",
                "Bar position, clock, Weather and optional shell modules.",
                "Monitor arrangement with a 15-second automatic revert.",
                "Keyboard, mouse and touchpad behavior.",
                "Search, review and change Parm keyboard shortcuts with conflict detection.",
                "Idle, lock, power profile and tty1 seamless login.",
                "Zen webapps, generated launchers and shortcuts.",
                "Pinned mise tools and optional Docker service.",
                "Signed tagged releases, snapshots and repair.",
                "Snapper system snapshots and configuration backups.",
                "Parm 0.1.0-dev · 00/Pm · MIT licensed."
              ]
              return descriptions[settings.currentSection]
            }
            color: settings.colors.on_surface_variant
            font.pixelSize: 15
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            radius: 20
            color: settings.colors.surface_container

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 20
              spacing: 12

              Text {
                text: settings.currentSection === 0
                  ? "Current appearance"
                  : "Configuration backend"
                color: settings.colors.on_surface
                font.pixelSize: 18
                font.weight: Font.Medium
              }

              Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: settings.currentSection === 0
                  ? "Select a wallpaper with the button below. Parm generates both Material schemes atomically and applies the current schedule."
                  : "This first complete repository revision exposes the settings structure. Controls write through the validated parmctl config interface."
                color: settings.colors.on_surface_variant
                font.pixelSize: 14
              }

              Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                  model: settings.sectionActions(settings.currentSection)

                  Button {
                    required property var modelData
                    text: modelData.label
                    onClicked: Quickshell.execDetached(modelData.command)
                  }
                }
              }
            }
          }

          Item { Layout.fillHeight: true }

          Text {
            text: "Settings closes completely when this window closes."
            color: settings.colors.on_surface_variant
            font.pixelSize: 12
          }
        }
      }
    }
  }
}
