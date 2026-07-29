import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "local.media-wave"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property bool hasMedia: mediaService ? !!mediaService.hasMedia : false
  readonly property bool isPlaying: activePlayer ? !!activePlayer.isPlaying : false
  readonly property bool canPrevious: activePlayer ? !!activePlayer.canGoPrevious : false
  readonly property bool canNext: activePlayer ? !!activePlayer.canGoNext : false
  readonly property bool canToggle: activePlayer
    ? !!(activePlayer.canTogglePlaying || activePlayer.canPlay || activePlayer.canPause)
    : false
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "Unknown title") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
  readonly property string mediaUrl: activePlayer && activePlayer.metadata
    ? String(activePlayer.metadata["xesam:url"] || "")
    : ""
  readonly property string effectiveArtUrl: artUrl || youtubeThumbnail(mediaUrl)
  readonly property bool showArtwork: {
    var configured = setting("showArtwork", true)
    return configured !== false && String(configured).toLowerCase() !== "false"
  }
  readonly property real metadataDurationSeconds: activePlayer && activePlayer.metadata
    ? Math.max(0, (Number(activePlayer.metadata["mpris:length"]) || 0) / 1000000)
    : 0
  readonly property real reportedDurationSeconds: activePlayer && activePlayer.lengthSupported
    ? Math.max(0, Number(activePlayer.length) || 0)
    : 0
  readonly property real positionSeconds: activePlayer
    ? Math.max(0, Number(activePlayer.position) || 0)
    : 0
  readonly property real durationSeconds: Math.max(metadataDurationSeconds, reportedDurationSeconds)
  readonly property bool canSeek: activePlayer
    ? !!(activePlayer.canSeek && activePlayer.positionSupported && durationSeconds > 0)
    : false
  readonly property real progressRatio: durationSeconds > 0
    ? Math.max(0, Math.min(1, positionSeconds / durationSeconds))
    : 0
  readonly property bool opened: popupOpen

  property bool popupOpen: false

  visible: hasMedia
  implicitWidth: hasMedia ? controls.implicitWidth : 0
  implicitHeight: barSize

  function close() {
    popupOpen = false
  }

  function open() {
    popupOpen = true
    refreshTiming()
    Qt.callLater(refreshTiming)
  }

  function runAction(action) {
    if (!mediaService || !activePlayer) return
    mediaService.runAction(action, false, mediaService.playerKey(activePlayer))
  }

  function refreshTiming() {
    if (activePlayer && activePlayer.positionSupported) activePlayer.positionChanged()
  }

  function formatTime(seconds) {
    var total = Math.max(0, Math.floor(Number(seconds) || 0))
    var hours = Math.floor(total / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    var secs = total % 60
    if (hours > 0)
      return hours + ":" + String(minutes).padStart(2, "0") + ":" + String(secs).padStart(2, "0")
    return minutes + ":" + String(secs).padStart(2, "0")
  }

  function youtubeVideoId(url) {
    var value = String(url || "")
    var patterns = [
      /youtube\.com\/shorts\/([A-Za-z0-9_-]{6,})/,
      /[\?&]v=([A-Za-z0-9_-]{6,})/,
      /youtu\.be\/([A-Za-z0-9_-]{6,})/,
      /youtube\.com\/embed\/([A-Za-z0-9_-]{6,})/
    ]
    for (var i = 0; i < patterns.length; i++) {
      var match = value.match(patterns[i])
      if (match) return match[1]
    }
    return ""
  }

  function youtubeThumbnail(url) {
    var videoId = youtubeVideoId(url)
    return videoId ? "https://i.ytimg.com/vi/" + videoId + "/hqdefault.jpg" : ""
  }

  function seekToRatio(ratio) {
    if (!canSeek || !activePlayer || durationSeconds <= 0) return
    activePlayer.position = Math.max(0, Math.min(durationSeconds, durationSeconds * ratio))
    activePlayer.positionChanged()
  }

  onHasMediaChanged: {
    if (!hasMedia) close()
  }

  onActivePlayerChanged: Qt.callLater(refreshTiming)

  Timer {
    interval: 500
    repeat: true
    running: root.popupOpen && root.isPlaying && root.activePlayer && root.activePlayer.positionSupported
    onTriggered: root.refreshTiming()
  }

  Row {
    id: controls
    anchors.centerIn: parent
    spacing: 0

    BarIconButton {
      bar: root.bar
      text: "󰒮"
      slotSize: Style.space(18)
      opticalSize: Style.space(12)
      fontSize: Style.font.caption
      tooltipText: "Previous"
      interactive: root.canPrevious
      dimmed: !root.canPrevious
      onPressed: root.runAction("previous")
    }

    BarIconButton {
      id: waveButton
      bar: root.bar
      slotSize: Style.space(24)
      opticalSize: Style.space(18)
      tooltipText: "Media controls"
      interactive: root.hasMedia
      dimmed: false
      active: root.isPlaying
      useActiveColor: false
      onPressed: root.popupOpen ? root.close() : root.open()

      iconComponent: Component {
        Item {
          Row {
            anchors.centerIn: parent
            spacing: Style.spaceReal(1.5)

            Repeater {
              model: [
                { low: 4, high: 9, duration: 260 },
                { low: 6, high: 15, duration: 190 },
                { low: 3, high: 11, duration: 230 },
                { low: 5, high: 14, duration: 170 },
                { low: 4, high: 8, duration: 280 }
              ]

              Rectangle {
                id: waveBar
                required property var modelData

                property real animatedHeight: Style.spaceReal(modelData.low)
                readonly property real lowHeight: Style.spaceReal(modelData.low)
                readonly property real highHeight: Style.spaceReal(modelData.high)

                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(1.5, Style.spaceReal(2))
                height: root.isPlaying ? animatedHeight : lowHeight
                radius: width / 2
                color: root.bar ? root.bar.foreground : Color.foreground
                opacity: root.isPlaying ? 1 : 0.62

                Behavior on opacity {
                  NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                  }
                }

                SequentialAnimation on animatedHeight {
                  running: root.isPlaying
                  loops: Animation.Infinite

                  NumberAnimation {
                    to: waveBar.highHeight
                    duration: waveBar.modelData.duration
                    easing.type: Easing.InOutSine
                  }

                  NumberAnimation {
                    to: waveBar.lowHeight
                    duration: waveBar.modelData.duration + 70
                    easing.type: Easing.InOutSine
                  }
                }
              }
            }
          }
        }
      }
    }

    BarIconButton {
      bar: root.bar
      text: "󰒭"
      slotSize: Style.space(18)
      opticalSize: Style.space(12)
      fontSize: Style.font.caption
      tooltipText: "Next"
      interactive: root.canNext
      dimmed: !root.canNext
      onPressed: root.runAction("next")
    }
  }

  PopupCard {
    id: popup
    anchorItem: waveButton
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(380))
    contentHeight: popup.fittedContentHeight(popupContent.implicitHeight)

    Item {
      id: popupContent
      anchors.fill: parent
      implicitHeight: Style.space(96)

      Row {
        anchors.fill: parent
        spacing: Style.space(12)

        BorderSurface {
          id: artwork
          width: Style.space(96)
          height: Style.space(96)
          visible: root.showArtwork
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
          clip: true

          Image {
            id: coverImage
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.effectiveArtUrl
            visible: status === Image.Ready && source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: coverImage.status !== Image.Ready
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
            opacity: 0.72
          }
        }

        Item {
          id: mediaDetails
          width: root.showArtwork
            ? parent.width - artwork.width - parent.spacing
            : parent.width
          height: parent.height

          Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Style.space(45)

            Column {
              anchors.left: parent.left
              anchors.right: playSurface.left
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                width: parent.width
                text: root.title
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: root.artist || root.album
                color: Qt.darker(root.bar.foreground, 1.35)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            BorderSurface {
              id: playSurface
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(42)
              height: width
              radius: width / 2
              color: playMouse.pressed
                ? Style.pressedFillFor(root.bar.foreground, Color.accent)
                : playMouse.containsMouse
                  ? Style.hoverFillFor(root.bar.foreground, Color.accent)
                  : Style.selectedFillFor(root.bar.foreground, Color.accent)
              borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
              opacity: root.canToggle ? 1 : 0.4

              Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.iconLarge
              }

              MouseArea {
                id: playMouse
                anchors.fill: parent
                enabled: root.canToggle
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.runAction("playPause")
              }
            }
          }

          Text {
            id: timeLabel
            anchors.left: parent.left
            anchors.top: header.bottom
            anchors.topMargin: Style.space(2)
            text: root.formatTime(root.positionSeconds) + " / " + root.formatTime(root.durationSeconds)
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            visible: root.durationSeconds > 0
          }

          Row {
            id: transport
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Style.space(26)
            spacing: Style.space(6)

            Item {
              width: Style.space(18)
              height: parent.height
              opacity: root.canPrevious ? 1 : 0.35

              Text {
                anchors.centerIn: parent
                text: "󰒮"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                anchors.fill: parent
                enabled: root.canPrevious
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.runAction("previous")
              }
            }

            Item {
              id: waveProgress
              width: transport.width
                - Style.space(36)
                - transport.spacing * 2
              height: parent.height

              Canvas {
                id: progressCanvas
                anchors.fill: parent

                property real progress: root.progressRatio
                property color foreground: root.bar ? root.bar.foreground : Color.foreground

                onProgressChanged: requestPaint()
                onForegroundChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                function drawWave(ctx) {
                  var middle = height / 2
                  var amplitude = Math.max(2, height * 0.16)
                  var steps = Math.max(24, Math.floor(width))

                  ctx.beginPath()
                  for (var i = 0; i <= steps; i++) {
                    var x = i / steps * width
                    var phase = i / steps
                    var envelope = 0.45 + 0.55 * Math.sin(Math.PI * phase)
                    var y = middle
                      + Math.sin(phase * Math.PI * 10) * amplitude * envelope
                      + Math.sin(phase * Math.PI * 4) * amplitude * 0.35
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                  }
                  ctx.stroke()
                }

                onPaint: {
                  var ctx = getContext("2d")
                  ctx.clearRect(0, 0, width, height)
                  ctx.lineWidth = Math.max(1.5, Style.spaceReal(2))
                  ctx.lineCap = "round"
                  ctx.lineJoin = "round"
                  ctx.strokeStyle = foreground

                  ctx.save()
                  ctx.globalAlpha = 0.28
                  drawWave(ctx)
                  ctx.restore()

                  if (progress > 0) {
                    ctx.save()
                    ctx.beginPath()
                    ctx.rect(0, 0, width * progress, height)
                    ctx.clip()
                    ctx.globalAlpha = 0.92
                    drawWave(ctx)
                    ctx.restore()
                  }
                }
              }

              Rectangle {
                visible: root.durationSeconds > 0
                x: Math.max(0, Math.min(parent.width - width, parent.width * root.progressRatio - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: Style.spaceReal(4)
                height: width
                radius: width / 2
                color: root.bar.foreground
                opacity: root.canSeek ? 0.85 : 0.35
              }

              MouseArea {
                anchors.fill: parent
                enabled: root.canSeek
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: function(mouse) {
                  root.seekToRatio(mouse.x / width)
                }
                onWheel: function(wheel) {
                  var step = wheel.angleDelta.y > 0 ? 5 : -5
                  root.seekToRatio((root.positionSeconds + step) / root.durationSeconds)
                }
              }
            }

            Item {
              width: Style.space(18)
              height: parent.height
              opacity: root.canNext ? 1 : 0.35

              Text {
                anchors.centerIn: parent
                text: "󰒭"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                anchors.fill: parent
                enabled: root.canNext
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.runAction("next")
              }
            }
          }
        }
      }
    }
  }
}
