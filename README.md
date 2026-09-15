# Omarchy World Clock

One native desktop widget showing multiple time zones together. A compact city-and-time board inspired by Bloomberg Launchpad, hosted by [Omarchy Widget Core](https://github.com/tcballard/omarchy-widget-core).

**Experimental 0.1.0 · Core API 1.** This is a widget package with `widget.json`, not a Quattro plugin. Core owns its window, placement, theme scaling and persistent settings.

Default cities: London, New York, Chicago, Amsterdam, Tokyo and Sydney. Every row shows 24-hour local time and date. Date differences are relative to your computer's local date. Wide size also shows UTC offsets. Bright dots indicate 07:00–18:59 local time; they are an approximate daytime cue, not sunrise/sunset or market-open status. Scroll to see additional cities in smaller sizes.

## Install

Install and enable Widget Core first, then run:

```bash
git clone https://github.com/tcballard/omarchy-widget-worldclock.git
cd omarchy-widget-worldclock
bash install-local
```

This copies the package, adds its single desktop placement and refreshes Core. It refuses to overwrite an installed snapshot. Requires Omarchy Quattro with Core 0.1.0, Bash, GNU coreutils and the system `tzdata` package. No network, account, API key or compiled widget helper is required.

Open the manager to hide or arrange the clock:

```bash
omarchy-shell io.github.tcballard.widget-core manage
```

Use Core's Arrange controls to move the card, select compact/standard/wide or switch monitors.

## Choose cities

Settings belong to this single widget. Keep between one and twelve cities, in display order, using IANA timezone IDs. Custom labels are supported. Configure through Core:

```bash
"$HOME/.config/omarchy/plugins/io.github.tcballard.widget-core/bin/omarchy-widget" configure io.github.tcballard.worldclock '{"cities":[{"label":"London","zone":"Europe/London"},{"label":"New York","zone":"America/New_York"},{"label":"Tokyo","zone":"Asia/Tokyo"}]}'
omarchy-shell io.github.tcballard.widget-core refresh
```

A city can also be a timezone string such as `"Europe/Amsterdam"`. Core replaces the entire settings object. An empty list shows an empty state; entries after the first twelve are ignored. Invalid timezones display an error in their own row. There is no in-widget city editor in this version.

## How it works

All rows are sampled at one UTC instant, using the machine's timezone database and GNU `date`. Daylight saving and unusual offsets follow that database. A fixed Bash script receives argv values without evaluating user shell text. It validates zone names, performs at most twelve conversions and produces a bounded result. Core API 1 copies package files without executable bits, so Quickshell invokes this script explicitly through Bash.

The widget updates on minute changes while active. Core unloads it when hidden or its monitor's workspace is fullscreen. Requests have a timeout, cannot overlap, and old settings generations cannot overwrite newer ones. Failed updates retain the previous rows with a stale-data message and retry at the next minute. Refreshing Core reloads the widget immediately. Times depend on the accuracy of your system clock and installed tzdata.

## Verify

```bash
node tests/model.cjs
python3 -m pip install 'PySide6==6.11.2'
python3 tests/qml_smoke.py
```

Model tests exercise real timezone conversion, UK DST transitions, staggered US/UK DST, half-hour offsets, date rollover, invalid zones and settings bounds. The native Qt test loads the production widget with explicit theme and process fixtures. It does not run the real Quickshell process or Wayland compositor.

Before calling this desktop-verified: install it through Core on Omarchy, check all sizes, configure/reorder cities, change theme, restart the shell, and confirm hide/fullscreen stops updates and saved settings survive. No live Omarchy test has been performed in this build environment.

To replace a snapshot, follow Core's documented hide/refresh/remove/install flow and back up settings first; Core 0.1.0 has no settings-preserving package upgrade operation.

MIT licensed.
