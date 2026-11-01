pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var jobs: []
    readonly property var visibleJobs: jobs.filter(job => !job.dismissed)
    readonly property int runningCount: visibleJobs.filter(job => job.status === "running" || job.status === "queued").length
    readonly property var latest: visibleJobs.length ? visibleJobs[0] : null
    readonly property string badge: runningCount ? runningCount + " running" : latest ? latest.status === "succeeded" ? "✓ Done" : latest.status === "failed" ? "! Failed" : latest.status : ""
    FileView {
        id: index
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/aether/task-jobs/index.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.jobs = JSON.parse(text()); } catch(e) {} }
    }
    Process { running: true; command: [Quickshell.env("HOME") + "/.local/bin/aether-task", "init"]; onExited: index.reload() }
    Process { id: reconcile; command: [Quickshell.env("HOME") + "/.local/bin/aether-task", "init"] }
    Timer { interval: 3000; running: root.runningCount > 0; repeat: true; onTriggered: reconcile.running = true }
    function openLog(id) { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/aether-task", "open", id]); }
    function dismiss(id) { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/aether-task", "dismiss", id]); }
}
