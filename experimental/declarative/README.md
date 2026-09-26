# Experimental shared-renderer World Clock

The default World Clock package at the repository root retains its four QML designs. This opt-in package exercises Widget Core's `declarative-v1` renderer, using the **same widget ID** so existing instances can be updated and rolled back. Its text/clock layout does not yet reproduce those designs.

Core PR #14 is merged, but live Hyprland and resource comparisons for this path are still outstanding. Install the current QML clock first. To explicitly switch an existing clock:

```bash
bash experimental/declarative/install-local --update
omarchy-widget restart
```

Core validates the staged manifest before the update and retains the previous package for rollback. To return to the QML clock, use `omarchy-widget rollback io.github.tcballard.worldclock` before further settings edits, then restart. The declarative package requires `declarative-v1`, `settings-schema`, and `frame-settings` in Core.

This package uses generated settings and a shared minute clock service. Small, medium and large show 1, 3 and 6 cities; up to 12 can be configured. The source checkout's QML files are not installed by this opt-in update. Preview clocks show an em dash when no time fixture is supplied.

CI covers manifest validation, migrations, staged updates and offscreen previews. It does not establish live compositor behavior or memory savings. Compare a 60-second single-clock capture and a multi-package capture against the isolated-renderer baseline before promoting this to the default package.
