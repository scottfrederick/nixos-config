# Match GNOME Config to Ubuntu Reference Desktop — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the NixOS GNOME desktop (themes, fonts, extensions, dconf settings) reproduce this Ubuntu 26.04 / GNOME Shell 50.1 reference laptop, declaratively.

**Architecture:** Two layers. (1) System module `modules/desktop-gnome.nix` installs the Yaru theme and the GNOME-extension *code* packages so the shell can load them. (2) A new home-manager file `home/sfrederick/gnome.nix` carries all per-user `dconf.settings` (enabled extensions, theme/font selection, favorites, mutter flags, and per-extension config). dconf writes to the binary dconf DB, not to yadm-tracked dotfiles, so it is safe alongside the intentionally-thin yadm-owned home profile.

**Tech Stack:** Nix flakes, home-manager (`dconf.settings` + `lib.hm.gvariant`), nixpkgs-unstable `gnomeExtensions.*` and `yaru-theme`.

---

## Reference: verification command on this machine

This is an **Ubuntu** box (not NixOS), flakes are disabled by default, and there is no `nixos-rebuild`. Use this prefix for every Nix command:

```bash
nix --extra-experimental-features 'nix-command flakes' <subcommand>
```

We cannot `switch`. The achievable verification is **evaluation + dry build** of the flake's NixOS configurations:

```bash
nix --extra-experimental-features 'nix-command flakes' eval .#nixosConfigurations.home-hpone.config.system.build.toplevel.drvPath
```

This forces full evaluation of the module set (catching type errors, bad attr names, GVariant mistakes) without needing the target hardware. All eight package attrs (`yaru-theme`, `gnomeExtensions.{tiling-shell,caffeine,weather-oclock,spotify-controller,extension-list,tweaks-in-system-menu,dash-to-dock}`) have already been confirmed to resolve against the pinned nixpkgs rev `2991645`.

---

## File Structure

- **Modify** `modules/desktop-gnome.nix` — add `yaru-theme` + the 7 extension code packages to `environment.systemPackages`.
- **Create** `home/sfrederick/gnome.nix` — all `dconf.settings`.
- **Modify** `home/sfrederick/default.nix` — add `./gnome.nix` to `imports`.

Commit after each task.

---

## Task 1: Install Yaru theme + extension code packages (system module)

**Files:**
- Modify: `modules/desktop-gnome.nix:37` (the `environment.systemPackages` line)

- [ ] **Step 1: Verify current state**

Run:
```bash
grep -n "environment.systemPackages" /home/scott/Projects/tools/nixos-config/modules/desktop-gnome.nix
```
Expected: one line — `environment.systemPackages = [ pkgs.file-roller ];`

- [ ] **Step 2: Replace the single-line systemPackages with the expanded list**

Replace this exact line:
```nix
  environment.systemPackages = [ pkgs.file-roller ];
```
with:
```nix
  environment.systemPackages = with pkgs; [
    file-roller

    # Yaru theme/icons/cursor — selected via dconf in home/sfrederick/gnome.nix.
    yaru-theme

    # GNOME extension *code* (per-user enablement + settings live in
    # home/sfrederick/gnome.nix). ubuntu-dock has no nixpkgs equivalent;
    # dash-to-dock is its upstream and the reference machine's dock settings
    # already live under the dash-to-dock dconf schema.
    gnomeExtensions.tiling-shell
    gnomeExtensions.caffeine
    gnomeExtensions.weather-oclock
    gnomeExtensions.spotify-controller
    gnomeExtensions.extension-list
    gnomeExtensions.tweaks-in-system-menu
    gnomeExtensions.dash-to-dock
  ];
```

- [ ] **Step 3: Verify the file parses (evaluation will run in Task 4; here just confirm Nix syntax)**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config && nix-instantiate --parse modules/desktop-gnome.nix >/dev/null && echo PARSE_OK
```
Expected: `PARSE_OK`

- [ ] **Step 4: Commit**

```bash
cd /home/scott/Projects/tools/nixos-config
git add modules/desktop-gnome.nix
git commit -m "desktop-gnome: install Yaru theme + GNOME extension packages

ubuntu-dock has no nixpkgs equivalent; install dash-to-dock (its upstream)
instead. Per-user enablement and dconf settings follow in home-manager.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Create the home-manager GNOME dconf module

**Files:**
- Create: `home/sfrederick/gnome.nix`

The GVariant typing rules used below:
- plain strings → Nix strings; booleans → Nix bools; signed ints → Nix ints.
- `uint32` dconf values (tilingshell `inner-gaps`/`outer-gaps`) → `lib.hm.gvariant.mkUint32`.
- cleared keybindings (empty `as`) → `[ ]`.
- string arrays → Nix lists of strings.

- [ ] **Step 1: Create `home/sfrederick/gnome.nix` with the full content below**

```nix
{ lib, ... }:
let
  inherit (lib.hm.gvariant) mkUint32;
in
{
  # ============================================================
  # GNOME desktop state, captured from the Ubuntu 26.04 reference
  # laptop (GNOME Shell 50.1) on 2026-05-30. See
  #   docs/superpowers/specs/2026-05-30-gnome-match-ubuntu-desktop-design.md
  #
  # dconf.settings writes to the binary dconf DB (~/.config/dconf/user),
  # NOT to individual dotfiles, so it does NOT collide with the
  # yadm-owned $HOME checkout. This is the one place GNOME per-user
  # config is allowed in this otherwise-thin HM profile.
  #
  # Notes on intentional deviations from the reference machine:
  #  - ubuntu-dock@ubuntu.com  -> dash-to-dock@micxgx.gmail.com
  #    (no nixpkgs ubuntu-dock; dash-to-dock is upstream, shares schema)
  #  - dropped stale enabled-but-uninstalled extensions
  #    quick-settings-audio-panel@rayzeq.github.io and
  #    system-monitor-next@paradoxxx.zero.gmail.com
  #  - dropped custom media-key bindings (ulauncher <Super>z, Zoom dbus
  #    hotkey): neither app is declared in this repo.
  # ============================================================
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Yaru-dark";
      icon-theme = "Yaru-dark";
      cursor-theme = "Yaru";
      font-name = "Ubuntu Sans 11";
      monospace-font-name = "Ubuntu Sans Mono 11";
      document-font-name = "Sans 11";
      enable-animations = true;
      clock-show-weekday = true;
      clock-show-seconds = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":minimize,maximize,close";
      titlebar-font = "Ubuntu Sans Bold 11";
    };

    # Cleared by tilingshell (it owns tiling); keep consistent.
    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      unmaximize = [ ];
    };

    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" "xwayland-native-scaling" ];
      dynamic-workspaces = true;
    };

    "org/gnome/shell" = {
      # user-theme name is empty on the reference machine (default shell theme).
      enabled-extensions = [
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "extension-list@tu.berry"
        "tilingshell@ferrarodomenico.com"
        "caffeine@patapon.info"
        "weatheroclock@CleoMenezesJr.github.io"
        "spotify-controller@narkagni"
        "tweaks-system-menu@extensions.gnome-shell.fifi.org"
        "dash-to-dock@micxgx.gmail.com"
      ];
      favorite-apps = [
        "org.ferdium.Ferdium.desktop"
        "com.slack.Slack.desktop"
        "brave-browser.desktop"
        "com.mitchellh.ghostty.desktop"
        "jetbrains-idea-0e3cda8e-27ff-4d69-81eb-da0afdc58281.desktop"
        "org.gnome.Nautilus.desktop"
        "net.cozic.joplin_desktop.desktop"
        "1password.desktop"
      ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "";
    };

    "org/gnome/shell/extensions/tilingshell" = {
      inner-gaps = mkUint32 2;
      outer-gaps = mkUint32 2;
      cycle-layouts-backward = [ "<Shift>" ];
      window-use-custom-border-color = false;
      last-version-name-installed = "17.0";
      selected-layouts = [ [ "10250844" "Layout 1" ] [ "10250844" "Layout 1" ] ];
      layouts-json = ''[{"id":"Layout 1","tiles":[{"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[2,3]},{"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},{"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}]},{"id":"Layout 2","tiles":[{"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},{"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"Layout 4","tiles":[{"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},{"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}]},{"id":"17354848","tiles":[{"x":0,"y":0,"width":1,"height":1,"groups":[]}]},{"id":"10250844","tiles":[{"x":0,"y":0,"width":0.5,"height":1,"groups":[1]},{"x":0.5,"y":0,"width":0.4999999999999998,"height":1,"groups":[1]}]}]'';
      overridden-settings = ''{"org.gnome.mutter.keybindings":{"toggle-tiled-right":"@as []","toggle-tiled-left":"@as []"},"org.gnome.desktop.wm.keybindings":{"maximize":"@as []","unmaximize":"@as []"},"org.gnome.mutter":{"edge-tiling":"false"}}'';
    };

    "org/gnome/shell/extensions/caffeine" = {
      cli-toggle = true;
      countdown-timer = 0;
      enable-fullscreen = false;
      indicator-position-max = 5;
      restore-state = true;
      show-indicator = "only-active";
      toggle-state = true;
      user-enabled = true;
    };

    "org/gnome/shell/extensions/system-monitor" = {
      layout = "vertical";
      position = "right";
      load-meter = true;
      network-meter = false;
      show-download = false;
      show-upload = false;
      storage-meter = false;
    };

    # ubuntu-dock's settings live under this schema; carried to dash-to-dock.
    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = false;
      background-opacity = 0.8;
      dash-max-icon-size = 56;
      dock-fixed = false;
      dock-position = "BOTTOM";
      extend-height = false;
      height-fraction = 0.64;
      icon-size-fixed = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-3";
      require-pressure-to-show = false;
      show-mounts = true;
      show-mounts-network = false;
      show-mounts-only-mounted = true;
    };
  };
}
```

- [ ] **Step 2: Verify the new file parses**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config && nix-instantiate --parse home/sfrederick/gnome.nix >/dev/null && echo PARSE_OK
```
Expected: `PARSE_OK`

- [ ] **Step 3: Commit**

```bash
cd /home/scott/Projects/tools/nixos-config
git add home/sfrederick/gnome.nix
git commit -m "home: add GNOME dconf settings matching Ubuntu reference desktop

Theme/fonts (Yaru-dark, Ubuntu Sans), enabled extensions, favorites,
mutter scaling flags, and per-extension config (tilingshell, caffeine,
system-monitor, dash-to-dock). dconf writes to the dconf DB, not
yadm-tracked files, so it is safe in the thin HM profile.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Wire `gnome.nix` into the home profile

**Files:**
- Modify: `home/sfrederick/default.nix:3-5` (the `imports` list)

- [ ] **Step 1: Verify current imports**

Run:
```bash
grep -n -A2 "imports" /home/scott/Projects/tools/nixos-config/home/sfrederick/default.nix
```
Expected:
```
  imports = [
    ./programs.nix
  ];
```

- [ ] **Step 2: Add `./gnome.nix` to imports**

Replace:
```nix
  imports = [
    ./programs.nix
  ];
```
with:
```nix
  imports = [
    ./programs.nix
    ./gnome.nix
  ];
```

- [ ] **Step 3: Verify parse**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config && nix-instantiate --parse home/sfrederick/default.nix >/dev/null && echo PARSE_OK
```
Expected: `PARSE_OK`

- [ ] **Step 4: Commit**

```bash
cd /home/scott/Projects/tools/nixos-config
git add home/sfrederick/default.nix
git commit -m "home: import gnome.nix into sfrederick profile

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Evaluate the full flake (dry build) for both hosts

This is the real verification — full module evaluation catches bad attr names, type errors, and GVariant mistakes without target hardware.

- [ ] **Step 1: Evaluate `home-hpone` toplevel derivation**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config
nix --extra-experimental-features 'nix-command flakes' eval \
  .#nixosConfigurations.home-hpone.config.system.build.toplevel.drvPath
```
Expected: a single `/nix/store/....drv` path printed, no errors. (First run fetches nixpkgs; allow several minutes.)

- [ ] **Step 2: Evaluate `work-dell` toplevel derivation**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config
nix --extra-experimental-features 'nix-command flakes' eval \
  .#nixosConfigurations.work-dell.config.system.build.toplevel.drvPath
```
Expected: a single `/nix/store/....drv` path printed, no errors.

- [ ] **Step 3: Spot-check that the dconf settings landed in the evaluated config**

Run:
```bash
cd /home/scott/Projects/tools/nixos-config
nix --extra-experimental-features 'nix-command flakes' eval --raw \
  .#nixosConfigurations.home-hpone.config.home-manager.users.sfrederick.dconf.settings.\"org/gnome/desktop/interface\".gtk-theme
```
Expected: `Yaru-dark`

- [ ] **Step 4: Confirm no `programs.*` regression in the home profile**

Run:
```bash
grep -rn "programs\." /home/scott/Projects/tools/nixos-config/home/sfrederick/ || echo "NONE (good)"
```
Expected: only `programs.home-manager.enable = true;` in `default.nix` (that one is intentional and does not write yadm-tracked files). No `programs.zsh/bash/git`.

- [ ] **Step 5: If both evals succeeded, no commit needed (verification only).** If an extension attr failed to resolve, remove that one package from `modules/desktop-gnome.nix` AND its UUID from `enabled-extensions` in `home/sfrederick/gnome.nix`, note the omission, and re-run Steps 1–2.

---

## Task 5: Update migration docs

**Files:**
- Modify: `MIGRATION_NOTES.md` (append a section)

- [ ] **Step 1: Append a GNOME-match section to `MIGRATION_NOTES.md`**

Append this block to the end of the file:
```markdown

## GNOME desktop matched to Ubuntu reference laptop (2026-05-30)

The GNOME layer was re-derived from the Ubuntu 26.04 / GNOME Shell 50.1 laptop
(replacing the original Pop!_OS-derived guesses). See
`docs/superpowers/specs/2026-05-30-gnome-match-ubuntu-desktop-design.md`.

- Theme: Yaru-dark (GTK + icons), Yaru cursor, prefer-dark; Ubuntu Sans fonts.
- Extensions: GNOME-shipped set + third-party tilingshell, caffeine,
  weatheroclock, spotify-controller, extension-list, tweaks-system-menu.
- `ubuntu-dock` -> `dash-to-dock` (no nixpkgs ubuntu-dock; dash-to-dock is its
  upstream and shares the dconf schema, so the dock settings carry over).
- Dropped stale (enabled-but-uninstalled) extensions quick-settings-audio-panel
  and system-monitor-next.
- Dropped custom media-key bindings (ulauncher `<Super>z`, Zoom dbus hotkey) —
  neither app is declared in this repo. Re-add under
  `org/gnome/settings-daemon/plugins/media-keys` if those apps are installed.
- All per-user GNOME state is declarative in `home/sfrederick/gnome.nix` via
  `dconf.settings` (safe alongside yadm — writes the dconf DB, not dotfiles).
- The IntelliJ favorite `.desktop` id is JetBrains-Toolbox-generated and will
  need updating after IDEA is first launched on the NixOS host.
```

- [ ] **Step 2: Commit**

```bash
cd /home/scott/Projects/tools/nixos-config
git add MIGRATION_NOTES.md
git commit -m "docs: note GNOME desktop matched to Ubuntu reference laptop

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review notes (resolved)

- **Spec coverage:** theme/fonts (Task 2 interface block), shipped+third-party extensions (Task 1 packages + Task 2 enabled-extensions), dock mapping (Task 1+2 dash-to-dock), dropped stale/custom bindings (Task 2 comments + Task 5 notes), favorites & mutter flags (Task 2), system vs home split (Task 1 vs 2/3), verification (Task 4). All spec sections map to a task.
- **Placeholders:** none — all 8 nixpkgs attrs pre-verified to resolve; all dconf values are concrete captured values.
- **Type consistency:** `mkUint32` used only for tilingshell gaps; cleared keybindings as `[ ]`; floats (`0.8`, `0.64`) and signed int (`-2`) match dconf types; `enabled-extensions` UUIDs match the `gnomeExtensions.*` packages installed in Task 1 (ubuntu-dock UUID intentionally replaced by dash-to-dock UUID).
