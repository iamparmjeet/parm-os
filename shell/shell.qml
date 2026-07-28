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
    function launcherState(): string {
      return (shell.launcherVisible ? "visible" : "hidden")
        + (launcherLoader.item ? ":loaded" : ":unloaded")
    }
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
    id: launcherLoader
    active: shell.launcherVisible

    PanelWindow {
      id: launcher
      visible: true
      screen: Quickshell.screens[0]
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      WlrLayershell.namespace: "parm-launcher"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      property var entries: []
      property int selectedIndex: 0

      function searchText(entry) {
        return [
          entry.name || "",
          entry.genericName || "",
          entry.comment || "",
          entry.id || ""
        ].join(" ").toLowerCase()
      }

      function score(entry, query) {
        var name = String(entry.name || "").toLowerCase()
        var id = String(entry.id || "").toLowerCase()
        if (!query) return 0
        if (name.indexOf(query) === 0) return 3000 - name.length
        if (id.indexOf(query) === 0) return 2500 - id.length
        var nameIndex = name.indexOf(query)
        if (nameIndex >= 0) return 2000 - nameIndex
        var searchIndex = searchText(entry).indexOf(query)
        return searchIndex >= 0 ? 1000 - searchIndex : -1
      }

      function rebuild() {
        var query = searchInput.text.trim().toLowerCase()
        var applications = DesktopEntries.applications.values || []
        var matches = []
        for (var i = 0; i < applications.length; i++) {
          var entry = applications[i]
          if (!entry || entry.noDisplay || !entry.name) continue
          var entryScore = score(entry, query)
          if (entryScore >= 0)
            matches.push({ entry: entry, score: entryScore })
        }
        matches.sort(function(left, right) {
          if (query && left.score !== right.score)
            return right.score - left.score
          return String(left.entry.name).localeCompare(String(right.entry.name))
        })
        entries = matches.slice(0, 100).map(function(match) { return match.entry })
        selectedIndex = entries.length === 0
          ? 0
          : Math.min(selectedIndex, entries.length - 1)
        Qt.callLater(function() {
          if (entries.length > 0)
            results.positionViewAtIndex(selectedIndex, ListView.Contain)
        })
      }

      function moveSelection(delta) {
        if (entries.length === 0) return
        selectedIndex = (selectedIndex + delta + entries.length) % entries.length
        results.positionViewAtIndex(selectedIndex, ListView.Contain)
      }

      function close() {
        shell.launcherVisible = false
      }

      function launch(index) {
        var entry = entries[index]
        if (!entry) return
        close()
        entry.execute()
      }

      function iconSource(icon) {
        var value = String(icon || "")
        if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0)
          return value
        if (value.charAt(0) === "/")
          return "file://" + value
        var resolved = Quickshell.iconPath(value || "application-x-executable", true)
        return resolved || Quickshell.iconPath("application-x-executable", true)
      }

      Component.onCompleted: {
        rebuild()
        Qt.callLater(function() { searchInput.forceActiveFocus() })
      }

      Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { launcher.rebuild() }
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
          shell.colors.background.r,
          shell.colors.background.g,
          shell.colors.background.b,
          0.62
        )
      }

      MouseArea {
        anchors.fill: parent
        onClicked: launcher.close()
      }

      Rectangle {
        id: launcherCard
        width: Math.min(640, launcher.width - 32)
        height: Math.min(470, launcher.height - 64)
        anchors.centerIn: parent
        radius: 28
        color: shell.colors.surface_container
        border.width: 1
        border.color: shell.colors.outline
        clip: true

        MouseArea {
          anchors.fill: parent
          onClicked: {}
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 18
          spacing: 10

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 27
            color: shell.colors.surface_container_high

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 18
              anchors.verticalCenter: parent.verticalCenter
              text: "⌕"
              color: shell.colors.primary
              font.pixelSize: 25
            }

            TextInput {
              id: searchInput
              anchors {
                left: parent.left
                leftMargin: 52
                right: parent.right
                rightMargin: 18
                verticalCenter: parent.verticalCenter
              }
              color: shell.colors.on_surface
              selectionColor: shell.colors.primary
              selectedTextColor: shell.colors.on_primary
              font.pixelSize: 17
              clip: true
              onTextChanged: {
                launcher.selectedIndex = 0
                launcher.rebuild()
              }

              Text {
                anchors.fill: parent
                visible: !searchInput.text
                text: "Search applications"
                color: shell.colors.on_surface_variant
                font: searchInput.font
                verticalAlignment: Text.AlignVCenter
              }

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  launcher.close()
                  event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                  launcher.moveSelection(1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  launcher.moveSelection(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  launcher.launch(launcher.selectedIndex)
                  event.accepted = true
                }
              }
            }
          }

          ListView {
            id: results
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: launcher.entries
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              id: appRow
              required property int index
              required property var modelData
              width: ListView.view.width
              height: 58
              radius: 16
              color: index === launcher.selectedIndex
                ? shell.colors.surface_container_high
                : "transparent"

              Image {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                source: launcher.iconSource(appRow.modelData.icon)
                sourceSize.width: 30
                sourceSize.height: 30
                asynchronous: true
                fillMode: Image.PreserveAspectFit
              }

              Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                  width: parent.width
                  text: appRow.modelData.name
                  color: appRow.index === launcher.selectedIndex
                    ? shell.colors.primary
                    : shell.colors.on_surface
                  font.pixelSize: 16
                  font.weight: Font.Medium
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  visible: text.length > 0
                  text: appRow.modelData.genericName || appRow.modelData.comment || ""
                  color: shell.colors.on_surface_variant
                  font.pixelSize: 12
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: launcher.selectedIndex = appRow.index
                onClicked: launcher.launch(appRow.index)
              }
            }
          }

          Text {
            Layout.fillWidth: true
            visible: launcher.entries.length === 0
            text: "No applications found"
            horizontalAlignment: Text.AlignHCenter
            color: shell.colors.on_surface_variant
            font.pixelSize: 15
          }

          Text {
            Layout.fillWidth: true
            text: "↑ ↓ navigate    Enter launch    Esc close"
            horizontalAlignment: Text.AlignHCenter
            color: shell.colors.on_surface_variant
            font.pixelSize: 11
          }
        }
      }
    }
  }
}
