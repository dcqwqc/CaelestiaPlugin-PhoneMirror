# PhoneMirror

Mirror an Android handset over wireless ADB from the quick toggles, as a
Caelestia plugin.

When the mirror is running, its single quick-toggle slot expands into a three-way control: **disconnect | PIN guide | fullscreen phone mode**. Fullscreen uses the existing immersive mirror path and the bottom-left exit overlay returns to the normal mirror without disconnecting.

PhoneMirror uses Hyprland’s Lua dispatcher-object IPC on 0.55+ for deterministic fullscreen set/unset, with a legacy dispatcher fallback for older Hyprland versions.

SSH persistence is dual-supervised: runit owns the real `sshd` master and restarts it on exit, while a separate runit watchdog verifies that the configured SSH port is actually listening and restarts the service if it becomes wedged. A `finish` hook prevents hot restart loops, and logs stay on-device instead of becoming desktop notifications.

Every healthy wireless ADB target refreshes the cached native TLS port, so a later LAN change can immediately reconnect through the handset’s Tailscale IP without rediscovering the port first.

The toggle follows the mirror rather than guessing at it: it reads the running
scrcpy window off the compositor, so closing the mirror from its own window — or
the handset dropping off wifi — switches the toggle off on its own.

With no handset configured the toggle becomes the way in. It shows
`phonelink_setup` and opens the pairing flow in a terminal instead of pretending
to be a switch over nothing.

## Requires

`scrcpy` and `android-tools`. `avahi` is only needed for local-LAN mDNS fallback.
For the preferred remote transport, the phone runs Termux SSH over Tailscale and
provides `adb-mdns-discover` from
[android-adb-helpers](https://github.com/rebroad/android-adb-helpers).

## Connection order

PhoneMirror prefers the simplest available transport automatically:

1. **USB ADB** when the handset is plugged into the host computer. USB always wins, even if
   an older wireless ADB endpoint is still connected.
2. **Tailscale + native Wireless Debugging** using the phone-side SSH discovery
   helper.
3. **LAN mDNS Wireless Debugging** as the final `auto` fallback.

Wireless Debugging requires Android to be connected to Wi-Fi; USB mirroring does
not, so PhoneMirror continues to work while the handset is cellular-only.

## Secure PIN guide

Android may intentionally black out the secure PIN surface in scrcpy. PhoneMirror
includes a visual-only PIN guide for that case:

- enable the dialpad quick toggle while the mirror is open;
- a transparent keypad guide follows the scrcpy window;
- its input region is empty, so clicks and touch pass directly through to scrcpy;
- it never stores, reads, or automatically submits a PIN;
- it hides automatically when the mirror closes.

## Setup

    phone pair     # Android 11+ native Wireless Debugging pairing
    phone setup    # records the connected handset
    phone connect  # reconnect without opening scrcpy

For the preferred remote setup, configure the handset's
`~/.config/caelestia/phone-mirror/device.conf` with:

    transport = tailscale
    tailscale_ip = 100.x.y.z
    ssh_host = phone-ssh-alias

The SSH alias should point at Termux on the handset over Tailscale. PhoneMirror
asks `adb-mdns-discover` on the handset for Android's current random
`_adb-tls-connect._tcp` port and then connects Android's native paired/TLS
Wireless Debugging endpoint through Tailscale. It does not use a fixed legacy
`adb tcpip 5555` listener.

`device.conf` holds the handset's *identity* — which phone, how to recognise it
in `adb devices -l`, optionally an exact serial. It is per-machine and stays out
of the settings UI on purpose.

## Settings

Stream preferences, from the Plugins page: maximum size, bitrate, frame rate
cap, whether to blank the handset's own screen, and whether to keep it awake.
They are persisted by the shell into `~/.config/caelestia/plugins.json`, and
`phone` reads them from there — so the mirror behaves the same whether it was
started from the toggle or the command line.

## Status

Caelestia's plugin loader is not released yet — it lives on upstream's unmerged
`feat/plugins` branch, and the Plugins page there is a mockup rendering four
fake cards. So this needs a shell that carries the loader:

- **On upstream Caelestia**, wait for that branch to merge.
- **On a fork that has cherry-picked it** (`plugin/src/Caelestia/Plugins`, plus a
  Plugins page and the quick-toggle / bar-entry hooks), it loads and is managed
  from Nexus → Plugins today.

The manifest and entry points are built against that branch's own parser rather
than a guess at it, so the shape is the real one.

## Install

Clone into Caelestia's plugin directory:

    git clone https://github.com/dcqwqc/CaelestiaPlugin-PhoneMirror ~/.local/share/caelestia/plugins/phone-mirror

Or clone anywhere and add the parent to `path` in
`~/.config/caelestia/plugins.json`.

## Licence

GPL-3.0-or-later, matching Caelestia.

## PIN guide vertical alignment

PhoneMirror's plugin settings include a live **Y position** control for the
click-through PIN guide. The position is locked by default; tap the lock beside
the slider to edit it, align the guide while it is visible, then lock it again.
`0%` keeps the calibrated default, negative values move the overlay upward and
positive values move it downward.

## Interactive PIN guide

While the guide is enabled, only the keypad region captures pointer input; the rest of the mirror remains click-through. Digit taps are sent directly to the already-connected Android handset, the preview exists only in memory, and backspace removes the last preview digit. Closing the guide clears the preview.

## Persistent phone SSH

PhoneMirror can diagnose the whole path with `phone doctor`. For the preferred
Tailscale transport it expects the phone-side Termux SSH server to be reachable.
Once SSH is running, `phone persist-ssh` installs
`~/.termux/boot/00-phone-mirror-ssh` plus supervised `sshd` and
`phone-ssh-watchdog` services on the handset. The boot hook acquires a Termux wake
lock, starts the runit supervisor, retries service activation while Android is
still settling after boot, and leaves both services self-healing. It also keeps a stable `~/.termux/boot/start-mirai-ssh.sh` compatibility entry point for existing Tasker automations.

Reboot persistence requires the separate **Termux:Boot** app to be installed and
opened once on Android. Android battery/background restrictions can still kill
Termux, so set Termux, Termux:Boot and Tailscale to unrestricted background use
for a truly always-available remote path.

The launcher also caches the last working native Wireless Debugging TLS port.
That lets an existing ADB-over-Tailscale connection recover even when Termux
SSH has temporarily died, as long as Android has not changed the ADB TLS port.

## Always-ready reconnect

Mirai can keep the configured handset's wireless ADB transport warm with the
included `phone-mirror-autoconnect.service`. The service is intentionally quiet:
it checks local ADB state, sleeps while connected, and uses `phone ensure` only
when the handset disappears. `phone ensure` performs the same USB/Tailscale/mDNS
recovery as `phone connect` without desktop notifications.

Install on a systemd-user host with:

    ln -sfn ~/.local/share/caelestia/plugins/phone-mirror/systemd/phone-mirror-autoconnect.service ~/.config/systemd/user/phone-mirror-autoconnect.service
    systemctl --user daemon-reload
    systemctl --user enable --now phone-mirror-autoconnect.service

For handset reboot persistence, Termux still needs Termux:Boot installed and
opened once so Android executes `~/.termux/boot/` after boot.

## Immersive phone mode

Fullscreen phone mode uses true-black side gutters around the portrait mirror. While it is active, the existing QuickShell OSD is forced open on the right; PhoneMirror does not implement its own volume or brightness sliders, so any future QuickShell OSD styling or behavior changes are inherited automatically. Leaving fullscreen releases that force and the native OSD animates closed normally. Bottom-left flat controls can leave fullscreen, toggle the physical phone display to black, or close the mirror. The phone-display toggle is persistent; the launcher snapshots Android brightness and brightness mode and restores both whenever the mirror exits.


## Stream quality

The default `best` profile uses native resolution with HEVC/H.265, 40 Mbps and a 120 fps cap. `balanced` uses a 1920 px long edge at 12 Mbps/60 fps, while `data-saver` uses 1280 px at 4 Mbps/30 fps. `custom` exposes size, bitrate, frame-rate and codec controls. Profile changes apply on the next mirror start.
