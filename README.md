# Omarchy World Clock

One native desktop widget showing multiple cities, inspired by Bloomberg Launchpad. City columns, a theme-coloured home clock, and digital or analogue time. Only Core’s shared settings gear sits above the clocks; there is no title bar, display toggle or city editor inside the widget.

**Experimental 0.1.2 · requires Widget Core API 3.** This is a desktop widget package, not a shell plugin. Core owns the window, fixed sizes, theme, sandbox and persistent settings. Live Quickshell/Hyprland acceptance remains outstanding.

The experimental [shared-renderer variant](experimental/declarative/README.md) is available for opt-in evaluation; it does not replace the four QML clock designs.

## Install or update

Install [Widget Core](https://github.com/tcballard/omarchy-widget-core) v0.0.2 first, then:

```bash
git clone https://github.com/tcballard/omarchy-widget-worldclock.git
cd omarchy-widget-worldclock
bash install-local
```

For an existing installation, use `bash install-local --update`. The installer stages runtime files only, then asks Core to validate and update the immutable package. Core preserves existing cities, placement and instance settings and retains the previous version for rollback. It does not hide/show all widgets or modify the registry directly. Finish unsaved settings edits before updating.

Requires Bash, GNU coreutils and system tzdata. No account, network or API key is needed. Use `omarchy-widget manage` for placement, size and monitor controls.

## Settings

Click the **gear in the top-right** to open Core's separate settings window:

- Choose **Digital** or **Analogue** for all cities in this widget instance.
- Choose the home city for the accent, timezone offsets and relative dates.
- Add, rename, reorder or remove cities. Search the catalogue or enter an IANA timezone ID. Up to twelve cities are supported.
- Core's **Save** commits the complete draft; **Cancel** discards it. Conflicts and failed saves remain in Core's settings window.

Existing settings default to digital with London as home when present, otherwise the first valid clock. The editor preserves unrelated settings such as appearance. Removing the selected home city chooses the first remaining city. Unknown timezone IDs show an error in their clock.

## Clock layout

Digital mode shows 24-hour times. Analogue mode uses hour and minute hands, with a Day/Night label to distinguish the halves of the day. The hour hand includes minute progress. Both modes use the same sampled instant and update once per minute while active; there is no continuously animated second hand.

The home city is labelled **Home** and takes the active theme's accent. Other clocks show offsets from home, including half-hour and quarter-hour differences. Day differences are also relative to home, rather than the computer's timezone.

City columns scroll horizontally when they exceed the available width. Core's small, medium and large families stay unchanged. Compact heights omit the date and day strip to retain legible clocks. The wide reference is a design direction, not a new Core size.

Day/Night and the subtle day strip use **07:00–18:59 local time**, an approximate daytime cue, not sunrise/sunset or market hours. Colours and fonts come from Core's active theme. Core can still show its own arrangement controls while arranging widgets.

## Reliability and verification

A bounded Bash helper samples every city at one UTC instant using GNU date and system tzdata. It validates timezone names and never evaluates them as shell code. Requests cannot overlap, have a deadline and discard obsolete settings generations. Failed updates show a stale-time warning and retry on the next minute. Accurate system time and current tzdata remain necessary.

```bash
node tests/model.cjs
python3 tests/update.py
python3 -m pip install 'PySide6==6.11.2'
python3 tests/qml_smoke.py
bash -n install-local scripts/times
```

Timezone tests use the real conversion helper, including DST boundaries, fractional offsets and home-relative date rollover. Qt tests render production QML in both modes at all Core content sizes and light/dark palettes. They exercise the gear callback, settings drafts, city operations and settings reload. The installer test checks delegation, staging and refusal after failed validation.

Qt process/theme fixtures do not establish live Quickshell, Wayland, Core save acknowledgement or compositor compatibility. On Omarchy, verify opening the settings window, Save/Cancel, mode persistence after restart, scrolling all cities, theme changes and package update/rollback before calling this desktop-verified.

MIT licensed.


### Widget Core implementation stack

The original API 2 integration was the first milestone of the Widget Core implementation
stack. Embedded city settings forward Escape to Core's Cancel handling; the
standalone editor retains its own Cancel signal. `tests/qml_smoke.py` checks this
keyboard propagation alongside the existing rendering and draft checks.

The companion Core foundation PR adds a two-instance integration check using this
package's real settings editor, Core's production settings controller and the
Rust registry. It covers Save/Cancel, stale revisions, independent cities,
workspace preservation and fresh-process disk reopening. This remains portable
Qt evidence: live Quickshell settings windows, reboot, scaling and monitor
acceptance are outstanding.

This revision requires **Core API 3** and uses its shared settings gear. Older API 2 hosts reject installation. The declared helper commands are bash, date and timeout. Qt 6.11.2 component tests are separate from live Omarchy acceptance.

Core API 3 owns the small settings gear at the top-right corner. The gear overlays
that corner without reserving a header band; the clock keeps its content height.
Core's capture tool supports this package's Quickshell imports with inert stubs,
so a portable preview shows the inactive/loading surface. Live clock screenshots
and keyboard focus still require a real Omarchy session.
