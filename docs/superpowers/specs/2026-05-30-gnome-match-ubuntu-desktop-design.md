# Match NixOS GNOME config to the Ubuntu reference desktop

**Date:** 2026-05-30
**Status:** Approved (design)

## Goal

The NixOS configuration in this repo was generated from an old Pop!_OS machine.
The user wants the **GNOME desktop experience** to instead match *this* Ubuntu
26.04 laptop (GNOME Shell 50.1). Only the desktop/GNOME layer is in scope —
**hardware is explicitly out of scope** (a second host config will be added
later for this machine's hardware).

The match must be faithful: theme, fonts, GNOME extensions (shipped +
third-party), and per-extension / interface dconf settings, all declarative via
home-manager `dconf.settings`.

## Source of truth

Live `gsettings`/`dconf` values read from the running Ubuntu session (NOT the
stale `~/dconf-dump` tracked by yadm — that is a years-old full-system archival
snapshot containing Unity/Compiz/Tilix cruft and is not reapplied).

### Appearance (org.gnome.desktop.interface + wm + shell user-theme)
| Key | Value |
|-----|-------|
| color-scheme | `prefer-dark` |
| gtk-theme | `Yaru-dark` |
| icon-theme | `Yaru-dark` |
| cursor-theme | `Yaru` |
| font-name | `Ubuntu Sans 11` |
| monospace-font-name | `Ubuntu Sans Mono 11` |
| document-font-name | `Sans 11` |
| wm titlebar-font | `Ubuntu Sans Bold 11` |
| wm button-layout | `:minimize,maximize,close` |
| clock-show-weekday | `true` |
| clock-show-seconds | `false` |
| shell user-theme name | `''` (default shell theme; user-theme ext enabled but no custom shell theme) |
| mutter experimental-features | `['scale-monitor-framebuffer','xwayland-native-scaling']` |
| mutter dynamic-workspaces | `true` |

### Extensions — enabled & actually installed
**Shipped with GNOME / Ubuntu (provided by nixpkgs `gnome-shell-extensions` or the desktop itself):**
`workspace-indicator`, `launch-new-instance`, `native-window-placement`,
`user-theme`, `places-menu`, `drive-menu`, `apps-menu`, `auto-move-windows`,
`system-monitor` (the gcampax one), and Ubuntu's `ubuntu-dock`.

**Third-party (must be packaged from nixpkgs `gnomeExtensions.*`):**
| UUID | Package (nixpkgs) |
|------|-------------------|
| `tilingshell@ferrarodomenico.com` | `gnomeExtensions.tiling-shell` |
| `caffeine@patapon.info` | `gnomeExtensions.caffeine` |
| `weatheroclock@CleoMenezesJr.github.io` | `gnomeExtensions.weather-oclock` |
| `spotify-controller@narkagni` | `gnomeExtensions.spotify-controller` *(verify name at impl time)* |
| `extension-list@tu.berry` | `gnomeExtensions.extension-list` |
| `tweaks-system-menu@extensions.gnome-shell.fifi.org` | `gnomeExtensions.tweaks-in-system-menu` *(verify)* |

### Dropped (enabled in gsettings but NOT installed on disk — stale entries)
`quick-settings-audio-panel@rayzeq.github.io`, `system-monitor-next@paradoxxx.zero.gmail.com`.
These will be omitted from the NixOS `enabled-extensions` list.

### Dock mapping decision
This Ubuntu machine runs `ubuntu-dock@ubuntu.com` (Canonical's fork of
dash-to-dock). NixOS does not package ubuntu-dock. The standard NixOS
equivalent is **`dash-to-dock`** (`gnomeExtensions.dash-to-dock`), which is the
upstream the Ubuntu fork derives from. Dash-to-dock's full settings are already
present in this machine's dconf (under `org.gnome.shell.extensions.dash-to-dock`)
because the keys are shared. We will:
- Install `gnomeExtensions.dash-to-dock`
- Enable `dash-to-dock@micxgx.gmail.com` in `enabled-extensions` (in place of `ubuntu-dock`)
- Apply the captured dash-to-dock dconf (BOTTOM position, 56px icons, 0.8 opacity,
  intellihide=FOCUS_APPLICATION_WINDOWS, show-mounts, etc.)

### Per-extension dconf to capture
- **tilingshell**: gaps (inner/outer=2), `layouts-json`, `selected-layouts`,
  `overridden-settings`, `cycle-layouts-backward`.
- **caffeine**: `restore-state=true`, `show-indicator='only-active'`,
  `toggle-state=true`, `user-enabled=true`, `cli-toggle=true`, `enable-fullscreen=false`.
- **dash-to-dock**: see dock mapping above.
- **system-monitor** (gcampax): `layout='vertical'`, `load-meter=true`,
  `position='right'`, network/storage meters off.

### Keybindings to capture
- `org.gnome.desktop.wm.keybindings`: `maximize=[]`, `unmaximize=[]`
  (cleared by tilingshell — keep consistent).
- Media-keys custom keybindings: `<Super>z` → `ulauncher-toggle`, and the Zoom
  hotkey. **DECISION: drop the Zoom dbus hotkey** (app-specific, fragile,
  references a running Zoom service). **Keep** the ulauncher `<Super>z` binding
  only if ulauncher is being installed — otherwise drop it too. Implementation
  will check the package set; default is to **drop both** custom media-keys
  since neither ulauncher nor Zoom are declared in this repo, and note it.

### Favorites (dash / app grid)
`favorite-apps`: Ferdium, Slack, Brave, Ghostty, IntelliJ IDEA, Nautilus,
Joplin, 1Password — all `.desktop` IDs that resolve to **Flatpak** apps already
managed by `modules/flatpak.nix` (plus 1password native). Capture verbatim.
The IntelliJ id is a JetBrains-Toolbox-generated UUID; note it may differ on
NixOS and need adjustment after first launch.

## Architecture

### Where things live
- **`modules/desktop-gnome.nix`** (system module): already enables GNOME/GDM/
  PipeWire/portals. Add:
  - `services.gnome.gnome-keyring` etc. left as-is.
  - Install Yaru theme + icon + cursor packages system-wide so they're available
    to GDM and all users: `pkgs.yaru-theme`.
  - Install `gnomeExtensions.*` packages via `environment.systemPackages` so the
    extension code exists on disk for the shell to load.
  - Keep the existing `excludePackages` / `programs.gnome-disks` etc.
- **`home/sfrederick/`** (home-manager): currently *intentionally thin* because
  `$HOME` is yadm-owned. **`dconf.settings` is safe here** — it writes to the
  dconf database (`~/.config/dconf/user`, a binary blob), NOT to individual
  tracked dotfiles, so it does not collide with yadm's file checkout. Add a new
  file `home/sfrederick/gnome.nix` imported by `default.nix`, containing all
  `dconf.settings` blocks. This keeps the thin-profile comment intact and
  isolates the GNOME dconf in one reviewable unit.

### Why split system vs home
- Extension *code* and themes must exist system-wide (shell loads them, GDM uses
  theme) → system module.
- Extension *enablement* and *settings* are per-user dconf → home-manager.
- This mirrors standard NixOS GNOME practice.

### New/changed files
1. `modules/desktop-gnome.nix` — add yaru-theme + gnomeExtensions packages.
2. `home/sfrederick/gnome.nix` — NEW: all `dconf.settings`.
3. `home/sfrederick/default.nix` — add `./gnome.nix` to imports.

## dconf.settings shape (illustrative)
```nix
dconf.settings = {
  "org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Yaru-dark";
    icon-theme = "Yaru-dark";
    cursor-theme = "Yaru";
    font-name = "Ubuntu Sans 11";
    monospace-font-name = "Ubuntu Sans Mono 11";
    document-font-name = "Sans 11";
    clock-show-weekday = true;
    clock-show-seconds = false;
  };
  "org/gnome/shell" = {
    enabled-extensions = [ /* installed list, ubuntu-dock -> dash-to-dock */ ];
    favorite-apps = [ /* captured */ ];
  };
  "org/gnome/shell/extensions/tilingshell" = { /* gaps, layouts-json, ... */ };
  "org/gnome/shell/extensions/caffeine" = { /* ... */ };
  "org/gnome/shell/extensions/dash-to-dock" = { /* BOTTOM, 56px, ... */ };
  "org/gnome/shell/extensions/system-monitor" = { /* vertical, right ... */ };
  "org/gnome/mutter" = {
    experimental-features = [ "scale-monitor-framebuffer" "xwayland-native-scaling" ];
    dynamic-workspaces = true;
  };
  "org/gnome/desktop/wm/preferences" = {
    button-layout = ":minimize,maximize,close";
    titlebar-font = "Ubuntu Sans Bold 11";
  };
  "org/gnome/desktop/wm/keybindings" = { maximize = [ ]; unmaximize = [ ]; };
};
```
Note: GVariant types — `uint32` gaps use `lib.hm.gvariant.mkUint32 2`; cleared
keybindings use `[ ]` (empty `as`). Implementation must use the
`lib.hm.gvariant` helpers where the type isn't a plain string/bool/int/list.

## Out of scope
- Hardware (separate future host config).
- The `desktop-gnome.nix` keyboard/ibus section — leave as-is (already matches
  intent; user can trim ibus engines independently).
- yadm-tracked dotfiles (zsh, git, ghostty, etc.) — untouched.
- ulauncher / Zoom custom keybindings — dropped (not declared in repo); noted in
  implementation output.

## Testing / verification
- `nix flake check` and `nixos-rebuild build` (dry build, no switch — this is
  not a NixOS machine) for `home-hpone` and `work-dell` to confirm the config
  *evaluates* and all `gnomeExtensions.*` attrs resolve.
- Manual cross-check: each captured dconf key appears in `gnome.nix` with the
  correct GVariant type.
- Confirm `home/sfrederick/default.nix` still has no `programs.*` that write
  yadm-tracked files.

## Risks
- **Extension version vs GNOME 50:** nixpkgs-unstable `gnomeExtensions.*` are
  built against nixpkgs' GNOME (also 50 on unstable). Low risk, but a
  third-party extension attr might be renamed/dropped — verify each resolves at
  impl time; if one is missing, note it and leave the extension uninstalled
  rather than failing the build.
- **dash-to-dock vs ubuntu-dock behavior:** not byte-identical, but closest
  upstream; settings transfer because keys are shared.
- **IntelliJ favorite `.desktop` id** is Toolbox-generated and won't match on
  NixOS until IDEA is launched there — cosmetic, noted.
