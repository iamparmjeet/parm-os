import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: shell

  property string home: Quickshell.env("HOME")
  property var config: ({
    shell: {
      bar: { position: "top", height: 42, clockFormat: "dddd HH:mm" },
      weather: { enabled: true, location: "" }
    }
  })
  property var colors: ({
    background: "#141218",
    on_background: "#e6e0e9",
    surface: "#141218",
    surface_container: "#211f24",
    surface_container_high: "#2b292f",
    on_surface: "#e6e0e9",
    on_surface_variant: "#cac4cf",
    primary: "#cfbdfe",
    on_primary: "#36275d",
    secondary: "#cbc2db",
    outline: "#948f99",
    error: "#ffb4ab"
  })
  property bool launcherVisible: false
  property string weatherText: "Weather"
  property string systemText: "CPU --  RAM --"

  function loadJson(file, fallback) {
    var raw = file.text() || ""
    if (!raw.trim()) return fallback
    try { return JSON.parse(raw) } catch (error) {
      console.warn("Parm JSON load failed:", error)
      return fallback
    }
  }

  function reloadTheme() {
    themeFile.reload()
    configFile.reload()
  }

  FileView {
    id: configFile
    path: shell.home + "/.config/parm/config.json"
    watchChanges: true
    printErrors: false
    onLoaded: shell.config = shell.loadJson(configFile, shell.config)
    onFileChanged: reload()
  }

  FileView {
    id: themeFile
    path: shell.home + "/.cache/parm/themes/current/colors.json"
    watchChanges: true
    printErrors: false
    onLoaded: shell.colors = shell.loadJson(themeFile, shell.colors)
    onFileChanged: reload()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Process {
    id: stats
    command: ["bash", "-lc", "read _ u n s i w x y z < /proc/stat; a=$((u+n+s+i+w+x+y+z)); b=$((a-i-w)); sleep 0.2; read _ u n s i w x y z < /proc/stat; c=$((u+n+s+i+w+x+y+z)); d=$((c-i-w)); cpu=$((100*(d-b)/(c-a))); mem=$(free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'); printf 'CPU %s%%  RAM %s%%' \"$cpu\" \"$mem\""]
    stdout: SplitParser {
      onRead: data => shell.systemText = data
    }
  }

  Process {
    id: weather
    command: ["bash", "-lc", "location=$(jq -r '.shell.weather.location // empty' ~/.config/parm/config.json); if [[ -z $location ]]; then printf 'Set weather location'; else location=${location// /+}; curl -fsS --max-time 3 \"https://wttr.in/${location}?format=%c+%t\" || printf 'Weather unavailable'; fi"]
    stdout: SplitParser {
      onRead: data => shell.weatherText = data
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: stats.running = true
  }

  Timer {
    interval: 900000
    running: shell.config.shell.weather.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: weather.running = true
  }

  IpcHandler {
    target: "parm.shell"
    function ping(): string { return "pong" }
    function reloadTheme(): void { shell.reloadTheme() }
    function toggleLauncher(): void { shell.launcherVisible = !shell.launcherVisible }
    function showSettings(): void { Quickshell.execDetached(["parmctl", "settings"]) }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar
      required property var modelData
      screen: modelData
      color: "transparent"
      implicitHeight: shell.config.shell.bar.height
      anchors {
        top: shell.config.shell.bar.position === "top"
        bottom: shell.config.shell.bar.position === "bottom"
        left: true
        right: true
      }

      Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 18
        color: shell.colors.surface_container
        border.width: 1
        border.color: shell.colors.outline

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Rectangle {
            implicitWidth: 40
            implicitHeight: 30
            radius: 14
            color: shell.colors.primary

            Text {
              anchors.centerIn: parent
              text: "Pm"
              color: shell.colors.on_primary
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            MouseArea {
              anchors.fill: parent
              onClicked: Quickshell.execDetached(["parmctl", "settings"])
            }
          }

          Repeater {
            model: [1, 2, 3, 4, 5]

            Rectangle {
              required property int modelData
              implicitWidth: 30
              implicitHeight: 30
              radius: 15
              color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                ? shell.colors.primary
                : "transparent"

              Text {
                anchors.centerIn: parent
                text: parent.modelData
                color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === parent.modelData
                  ? shell.colors.on_primary
                  : shell.colors.on_surface_variant
                font.pixelSize: 13
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached([
                  "hyprctl", "dispatch",
                  "hl.dsp.focus({ workspace = \"" + parent.modelData + "\" })"
                ])
              }
            }
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            implicitWidth: clockText.implicitWidth + 24
            implicitHeight: 30
            radius: 15
            color: shell.colors.surface_container_high

            Text {
              id: clockText
              anchors.centerIn: parent
              text: Qt.formatDateTime(clock.date, shell.config.shell.bar.clockFormat)
              color: shell.colors.on_surface
              font.pixelSize: 13
              font.weight: Font.Medium
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            visible: shell.config.shell.weather.enabled
            text: shell.weatherText
            color: shell.colors.on_surface_variant
            font.pixelSize: 12
          }

          Text {
            text: shell.systemText
            color: shell.colors.on_surface_variant
            font.pixelSize: 12
          }

          Rectangle {
            implicitWidth: 38
            implicitHeight: 30
            radius: 15
            color: shell.colors.surface_container_high
            Text {
              anchors.centerIn: parent
              text: "⚙"
              color: shell.colors.primary
              font.pixelSize: 16
            }
            MouseArea {
              anchors.fill: parent
              onClicked: Quickshell.execDetached(["parmctl", "settings"])
            }
          }
        }
      }
    }
  }

  LazyLoader {
    active: shell.launcherVisible

    PanelWindow {
      id: launcher
      anchors.top: true
      exclusionMode: ExclusionMode.Ignore
      implicitWidth: 560
      implicitHeight: 100
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        anchors.margins: 12
        radius: 24
        color: shell.colors.surface_container
        border.width: 1
        border.color: shell.colors.outline

        Text {
          anchors.centerIn: parent
          text: "Parm launcher · application search arrives in the next shell revision"
          color: shell.colors.on_surface
          font.pixelSize: 15
        }
      }
    }
  }
}
