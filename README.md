# Omarchy World Clock

One native desktop widget showing multiple time zones together. Choose Solar or Classic at standard/wide size, and Monolith or Twin at compact size, with analogue and digital views. Hosted by [Omarchy Widget Core](https://github.com/tcballard/omarchy-widget-core).

**Experimental 0.1.1 · Core API 1, Core 0.1.1 required for the editor.** This is a widget package with `widget.json`, not a Quattro plugin. Core owns its window, placement, theme scaling and persistent settings.

Default cities: London, New York, Chicago, Amsterdam, Tokyo and Sydney. The designs show up to five cities in Solar, four in Classic and Monolith, or two in Twin. Times are 24-hour; the analogue faces use 06:00–17:59 as daytime. More configured cities remain available when you switch designs.

## Install

Install and enable Widget Core first, then run:

```bash
git clone https://github.com/tcballard/omarchy-widget-worldclock.git
cd omarchy-widget-worldclock
bash install-local
```

This copies the package, adds its single desktop placement and refreshes Core. It refuses to overwrite an installed snapshot. Requires Omarchy Quattro with Core 0.1.0, Bash, GNU coreutils and the system `tzdata` package. No network, account, API key or compiled widget helper is required.

Use the clock header to switch between analogue and digital views, change designs, or edit cities. These choices are saved with the widget settings. The Solar dial places noon at the top and merges hands when configured cities are within 30 minutes; Classic shows four individual faces. Monolith focuses on the first city and Twin compares the first two. The first city is Home for relative offsets and day labels.\n\nOpen the manager to hide or arrange the clock:

```bash
omarchy-shell io.github.tcballard.widget-core manage
```

Use Core's Arrange controls to move the card, select compact/standard/wide or switch monitors.

## Choose cities

Click **Edit cities** in the card. Search the common-city catalogue and click a
timezone to add it, or enter an IANA ID and choose **Add ID**. Edit labels inline,
use the arrows to reorder and × to remove. **Save** persists the list; **Cancel**
discards edits. At most twelve cities are supported. Custom IDs not present in
the local timezone database will show an error in their row after saving.

The editor preserves other settings, including `appearance`. Core's softer
frame and theme-owned appearance options are documented in
[Widget appearance](https://github.com/tcballard/omarchy-widget-core/blob/main/docs/widget-appearance.md).

### Upgrade from 0.1.0

First update Core from its checkout with `git pull --ff-only` and
`bash install-local --update`. Then run the same two commands from this widget's
checkout. The updater keeps cities and placement and retains the old package
in a backup directory printed by the command. It temporarily hides all Core
widgets and shows them after replacement. Finish any unsaved editor work first.

### Command-line configuration

Settings belong to this single widget. Keep between one and twelve cities, in display order, using IANA timezone IDs. Custom labels are supported. Configure through Core:

```bash
"$HOME/.config/omarchy/plugins/io.github.tcballard.widget-core/bin/omarchy-widget" configure io.github.tcballard.worldclock '{"cities":[{"label":"London","zone":"Europe/London"},{"label":"New York","zone":"America/New_York"},{"label":"Tokyo","zone":"Asia/Tokyo"}]}'
omarchy-shell io.github.tcballard.widget-core refresh
```

A city can also be a timezone string such as `"Europe/Amsterdam"`. Core replaces the entire settings object. An empty list shows an empty state; entries after the first twelve are ignored. Invalid timezones display an error in their own row.

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

To replace this widget's snapshot, use `bash install-local --update` as described above. It preserves the separate layout/settings file and retains a backup of the old package. Core's generic install command still refuses replacement.

MIT licensed.
