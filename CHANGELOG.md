# Changelog

Versions follow [Semantic Versioning](https://semver.org). Until 1.0, a minor version
may change how things work.

## 0.1.0 - 2026-10-24

The first release.

- The theme: the Twilight palette, six presets, colors taken from the wallpaper, and palettes of your own in `theme.toml`.
- `ConfigFile`: settings in TOML in `~/.config/twilight-shell/`, made from a defaults file, reloaded when edited, written back with comments kept.
- A TOML reader and writer (`Toml`): tables, arrays of tables, inline tables, setting and removing keys.
- `Palette`, for swatches and palette editors.
- The sticker UI kit (`Sticker`, `Tap`, `StyledText`, `Toggle`, `StarSlider`, `RollText`), the decorations (`Moon`, `Starfield`, `SparkleBurst`), `Icons`, `Astro` and `Ticker`.
- Tests for the TOML reader and writer and for the palettes.
