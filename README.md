# World Clock

A declarative World Clock for Omarchy Widget Core. Small, medium and large widgets share Core’s renderer and minute clock service; this package launches no QML process, shell helper or Wayland proxy of its own.

**Experimental development build.** Requires Core with `declarative-v1` support (Core PR #14). The previous QML runtime has desktop evidence; this new rendering path does not yet have a Hyprland or resource capture. No near-zero memory claim is made.

## Install or update

Install the matching Core branch first, then from this checkout:

```bash
# Existing clock (preserves instances and settings):
bash install-local --update
omarchy-widget restart

# First installation instead:
# bash install-local
```

The installer stages only widget.json and LICENSE. Core validates the contract before making any registry changes. No merge is needed for local testing.

## Contract

`widget.json` declares bounded text/clock layouts and generated settings. Select digital or analogue mode, edit label/IANA timezone pairs, and choose a home timezone. Small displays the home city when present; medium displays the first three cities, large the first six. Lists may hold up to 12 cities. There are no seconds hands or animations. The small family reserves the Core gear corner.

Settings version 2 preserves existing cities and mode and fills missing displayMode/homeZone. Unknown timezone names or settings beyond the new limits block migration without overwriting the installed package. Save/Cancel and stale-revision conflicts are handled by Core. Use `omarchy-widget rollback io.github.tcballard.worldclock` before further settings edits to restore the previous QML package and checkpoint.

The older QML files remain in the source history/checkout for reference; the declarative installer does not package or execute them. The default package has no custom-code entry point or command dependencies. Advanced QML remains a separate Core authoring option.

## Verification

CI validates the actual manifest using pinned Core, renders all three families, checks the staged installer and runs Core's migration/settings integration tests. Offscreen tests do not establish compositor behavior or memory savings. Compare a new 60-second single-clock capture and a multi-package capture against the recorded isolated-renderer baseline.

Preview clocks show an em dash because the capture fixture supplies no live time data. The actual renderer uses the shared Core clock service.

Licence: MIT; see LICENSE.
