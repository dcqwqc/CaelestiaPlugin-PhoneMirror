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

`scrcpy`, `android-tools`, `avahi` (for mDNS discovery), and the `phone` helper
from [kagami](https://github.com/dcqwqc/kagami) on `PATH` or in `~/.local/bin`.

## Setup

    phone pair     # Android 11+ wireless debugging: address, code, done
    phone setup    # writes ~/.config/kagami/phone.conf from a connected handset

`phone.conf` holds the handset's *identity* — which phone, how to recognise it
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
