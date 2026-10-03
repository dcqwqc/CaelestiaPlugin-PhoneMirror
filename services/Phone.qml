pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import qs.services

// The scrcpy mirror of the handset, as a quick toggle.
//
// This used to be a .desktop entry in the app launcher, which could only ever
// start it. A toggle has to answer "is it up?" as well, and has to keep
// answering: the mirror is closed from its own window, or dies when the phone
// leaves wifi, at least as often as it is switched off from here.
//
// So the state is not polled -- it is read off the compositor. The launcher
// pins a fixed window title on scrcpy, so the mirror's toplevel appearing IS
// the connection coming up and it vanishing IS the connection going away, with
// no interval in which the toggle disagrees with reality.
Singleton {
    id: root

    // Same reason as RotationLock: the shell is started by the systemd user
    // manager, whose PATH does not carry ~/.local/bin, so the launcher cannot
    // be resolved by name from here.
    readonly property string bin: `${Quickshell.env("HOME")}/.local/share/caelestia/plugins/phone-mirror/scripts/phone`
    // The handset's name, which is also the window title the launcher pins on
    // scrcpy -- so it is what identifies a running mirror below. Read from
    // ~/.config/kagami/phone.conf via `phone status` rather than written here:
    // this file used to name one particular handset, which meant the shell had
    // to be edited to point at a different phone.
    property string windowTitle: ""

    // False until the launcher is found on disk, so the toggle stays hidden on
    // a machine that never had the phone stack installed.
    property bool available: false
    // A launcher with no phone.conf yet. The toggle still appears -- pressing
    // it starts the pairing workflow instead of a mirror, which is how you
    // find out the workflow exists.
    property bool configured: false
    property int displayWidth: 1080
    property int displayHeight: 2400
    readonly property real displayAspect: {
        const w = Math.max(1, Math.min(displayWidth, displayHeight));
        const h = Math.max(1, Math.max(displayWidth, displayHeight));
        return w / h;
    }

    readonly property Toplevel toplevel: {
        // qmllint disable unqualified
        if (!root.windowTitle)
            return null;
        const list = ToplevelManager.toplevels.values;
        for (const t of list)
            if (t.title === root.windowTitle)
                return t;
        return null;
    }
    readonly property bool running: !!toplevel

    // Observe the real compositor state so the toggle also follows fullscreen
    // changes made outside this plugin.
    readonly property HyprlandToplevel hyprToplevel: {
        if (!root.windowTitle)
            return null;
        return Hypr.toplevels.values.find(t => t.title === root.windowTitle) ?? null;
    }
    readonly property bool fullscreenActive:
        Number(hyprToplevel?.lastIpcObject?.fullscreen ?? 0) > 1

    // The launcher browses mDNS for the handset before scrcpy ever starts,
    // which takes a few seconds; hold the toggle on for that window so it does
    // not snap back under the cursor.
    property bool connecting: false
    property string pendingAction: ""

    // Visual-only guide for Android's secure PIN surface. It is deliberately
    // manual and never stores, reads or submits the PIN.
    property bool pinGuideVisible: false
    property var pinKeyQueue: []

    function sendPinKey(key: string): void {
        if (!root.running)
            return;
        root.pinKeyQueue = root.pinKeyQueue.concat([key]);
        root.flushPinKeyQueue();
    }

    function flushPinKeyQueue(): void {
        if (pinInput.running || root.pinKeyQueue.length === 0)
            return;
        const key = root.pinKeyQueue[0];
        root.pinKeyQueue = root.pinKeyQueue.slice(1);
        pinInput.command = [root.bin, "input-key", key];
        pinInput.running = true;
    }

    function togglePinGuide(): void {
        if (!root.running) {
            root.pinGuideVisible = false;
            return;
        }
        root.pinGuideVisible = !root.pinGuideVisible;
    }

    function setFullscreen(enabled: bool): void {
        if (!root.running)
            return;
        if (enabled)
            root.pinGuideVisible = false;
        Quickshell.execDetached([root.bin, "fullscreen", enabled ? "on" : "off"]);
    }

    function toggleFullscreen(): void {
        root.setFullscreen(!root.fullscreenActive);
    }

    function setPhysicalScreenBlack(enabled: bool): void {
        if (!root.running)
            return;
        Quickshell.execDetached([root.bin, "display", enabled ? "black" : "restore"]);
    }

    function restorePhysicalScreen(): void {
        Quickshell.execDetached([root.bin, "display", "restore"]);
    }

    onRunningChanged: {
        if (!running) {
            pinGuideVisible = false;
            pinKeyQueue = [];
        }

        if (running) {
            connecting = false;
            root.refresh();
            if (pendingAction === "start") {
                Toaster.toast(qsTr("Phone mirror enabled"), windowTitle ? qsTr("Mirroring %1").arg(windowTitle) : qsTr("The phone mirror is running"), "smartphone");
                pendingAction = "";
            }
        } else if (pendingAction === "stop") {
            Toaster.toast(qsTr("Phone mirror disabled"), windowTitle ? qsTr("Disconnected from %1").arg(windowTitle) : qsTr("The phone mirror has stopped"), "phonelink_off");
            pendingAction = "";
        }
    }

    function toggle(): void {
        if (!configured) {
            setUp();
            return;
        }
        if (running || connecting)
            stop();
        else
            start();
    }

    // Pairing is a conversation -- it asks for the address and code the handset
    // is showing -- so it needs a terminal rather than a detached process. It
    // also finishes on its own schedule, so watch for the config appearing
    // rather than asking the user to restart the shell.
    function setUp(): void {
        Quickshell.execDetached(["kitty", "-e", root.bin, "pair"]);
        pairWatch.attempts = 0;
        pairWatch.restart();
    }

    // Polls only while a pairing is plausibly in progress, and stops the moment
    // one lands. Five minutes is longer than reading a code off a phone.
    Timer {
        id: pairWatch

        property int attempts

        interval: 3000
        repeat: true
        onTriggered: {
            if (root.configured || ++attempts > 100) {
                pairWatch.stop();
                return;
            }
            root.refresh();
        }
    }

    function start(): void {
        if (root.running)
            return;
        root.pendingAction = "start";
        root.connecting = true;
        // Detached on purpose: the mirror must outlive a shell restart.
        Quickshell.execDetached([root.bin]);
        settle.attempts = 0;
        settle.restart();
    }

    function stop(): void {
        const wasRunning = root.running;
        root.connecting = false;
        settle.stop();
        if (wasRunning) {
            root.pendingAction = "stop";
            // Start restoring the physical handset before scrcpy exits. The
            // launcher also restores in a finally block, so manual closes and
            // crashes are covered too.
            root.restorePhysicalScreen();
            root.toplevel.close();
        } else if (!killer.running) {
            // Nothing on screen yet -- this is aborting a start still stuck in
            // discovery, so the process has to be reached directly.
            killer.running = true;
            root.pendingAction = "";
            Toaster.toast(qsTr("Phone mirror cancelled"), qsTr("Stopped connecting to %1").arg(root.windowTitle || qsTr("the phone")), "phonelink_off");
        }
    }

    Process {
        id: probe

        running: true
        command: ["test", "-x", root.bin]
        onExited: code => {
            root.available = code === 0;
            if (root.available)
                status.running = true;
        }
    }

    // Who the handset is, and whether one is configured at all.
    //
    // Re-read on demand, not once at startup. Pairing happens in a terminal
    // while the shell is running, so a status read that never repeats leaves
    // the toggle offering setup for a phone that is already set up -- which is
    // exactly what it did.
    function refresh(): void {
        if (root.available && !status.running)
            status.running = true;
    }

    Process {
        id: status

        command: [root.bin, "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.configured = !!data.configured;
                    root.windowTitle = data.title ?? "";
                    const width = Number(data.display_width ?? 0);
                    const height = Number(data.display_height ?? 0);
                    if (width > 0 && height > 0) {
                        root.displayWidth = width;
                        root.displayHeight = height;
                    }
                } catch (e) {
                    root.configured = false;
                }
            }
        }
    }

    Process {
        id: killer

        command: ["pkill", "-f", `window-title=${root.windowTitle}`]
    }

    Process {
        id: pinInput

        running: false
        onExited: root.flushPinKeyQueue()
    }

    // Only guards a start that never lands; it does not sample state.
    Timer {
        id: settle

        property int attempts

        interval: 1000
        repeat: true
        onTriggered: {
            // ~20s covers a cold mDNS discovery; past that the launcher has
            // given up and notified on its own.
            if (++attempts > 20 || !root.connecting) {
                root.connecting = false;
                root.pendingAction = "";
                settle.stop();
            }
        }
    }
}
