import QtQuick
import Quickshell
import Quickshell.Io
import "TrayModel.js" as TrayModel

// The host hands this widget its `settings` exactly once, imperatively, when
// its Loader finishes (Bar.qml's injectProps()). If shell.json is still
// loading at that instant, Bar.qml's inline-settings fast path (taken
// whenever the layout shape already matches the fallback default) patches
// the live item directly instead of rebuilding it — but only if the item
// has already loaded. Lose that race and `settings` is stuck on the empty
// fallback for the rest of the session: read shell.json ourselves instead of
// trusting that hand-off, with blockLoading so we never race it at all.
Item {
  id: root
  property string pluginId: "io.github.tyrichards.tray"
  property string path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
  property var entry: ({})
  property bool loaded: false

  function reload() { settingsFile.reload() }

  function parse() {
    var raw = ""
    try { raw = String(settingsFile.text() || "") } catch (e) { raw = "" }
    if (raw.trim().length === 0) {
      root.entry = {}
      root.loaded = true
      return
    }
    try {
      var parsed = JSON.parse(raw)
      var layout = parsed && parsed.bar ? parsed.bar.layout : null
      var found = TrayModel.findLayoutEntry(layout, root.pluginId)
      root.entry = (found && found.entry && typeof found.entry === "object") ? found.entry : {}
      root.loaded = true
    } catch (e) {
      console.warn("io.github.tyrichards.tray: cannot read saved settings: " + e)
    }
  }

  FileView {
    id: settingsFile
    path: root.path
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse()
    onLoadFailed: root.parse()
  }

  Component.onCompleted: parse()
}
