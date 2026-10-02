# PhoneMirror

Mirror an Android handset over wireless ADB from the quick toggles, as a
Caelestia plugin.

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

1. **USB ADB** when the handset is plugged into Mirai. USB always wins, even if
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
