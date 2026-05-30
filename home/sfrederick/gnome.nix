{ lib, ... }:
let
  inherit (lib.hm.gvariant) mkUint32 mkInt32;
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
      countdown-timer = mkInt32 0;
      enable-fullscreen = false;
      indicator-position-max = mkInt32 5;
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
      dash-max-icon-size = mkInt32 56;
      dock-fixed = false;
      dock-position = "BOTTOM";
      extend-height = false;
      height-fraction = 0.64;
      icon-size-fixed = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      preferred-monitor = mkInt32 (-2);
      preferred-monitor-by-connector = "DP-3";
      require-pressure-to-show = false;
      show-mounts = true;
      show-mounts-network = false;
      show-mounts-only-mounted = true;
    };
  };
}
