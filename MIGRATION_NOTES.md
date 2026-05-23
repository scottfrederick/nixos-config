# Migration Notes — Pop!_OS → NixOS

Generated 2026-05-23 from `./artifacts/inventory.json` + `./artifacts/classification.json`.

Source system: **Pop!_OS 24.04 LTS**, COSMIC desktop, kernel 6.18.7.
Target system: **NixOS unstable**, GNOME desktop (per user decision).

## Classification summary

| Disposition           | Count |
|-----------------------|-------|
| translate             | 111   |
| translate-with-review | 19   |
| preserve-verbatim     | 48   |
| flag-for-manual       | 0     |
| drop-candidate        | 190      |
| yadm-instead          | 2        |

## ✅ Confidently translated

System-level:
- GNOME on Wayland via GDM (`services.desktopManager.gnome.enable`, `services.displayManager.gdm.{enable,wayland}`)
- NetworkManager (`networking.networkmanager.enable`, iwd backend)
- PipeWire audio (replaces Pop's PulseAudio)
- Printing via CUPS + hplip + Avahi
- Bluetooth (`hardware.bluetooth.enable`, blueman)
- chrony, systemd-resolved, AppArmor, switcheroo-control, udisks2
- zram swap (matches Pop's `pop-default-settings-zram`)
- 32-bit graphics + Pipewire 32-bit (replaces ~29 :i386 apt libs)
- Locale en_US.UTF-8, console keymap us-acentos, X/Wayland xkb us+intl
- Flatpak runtime (47 flatpaks restored manually post-install)
- 1Password GUI + CLI via the dedicated `programs._1password*` module
- Fonts: Noto + CJK + JetBrains Mono + arphic ukai/uming + emoji
- ibus input methods (libpinyin, chewing, table)
- Nix flakes, weekly GC, auto-optimise store
- 47 apt packages mapped to confirmed Nixpkgs attrs (see `modules/base.nix`)
- yadm + zsh as login shell — user dotfiles come from `yadm clone`

## ⚠️ Needs review (translate-with-review)

System-level:
- **dconf snapshot** (`raw/desktop_dconf.ini`, 66 GNOME-app sections). Since target is GNOME, applying these is sensible. Either selectively port into `dconf.settings` or `dconf load / < raw/desktop_dconf.ini` post-install.
- **Keymap us-acentos** — translated to console.keyMap + X xkb.layout=us, variant=intl. Verify dead-key behavior matches what you had on Pop.

apt-package translations with fuzzy matches (full list in `classification.json`, search disposition=translate-with-review). The flake includes them with a `# REVIEW:` comment in `modules/base.nix`. Review before first build:
- `libbpf0` → `libbpf`  (matched after stripping suffix: 'libbpf')
- `libdc1394-25` → `libdc1394`  (matched after stripping suffix: 'libdc1394')
- `libestr0` → `libestr`  (matched after stripping suffix: 'libestr')
- `libfastjson4` → `libfastjson`  (matched after stripping suffix: 'libfastjson')
- `libffado2` → `libffado`  (matched after stripping suffix: 'libffado')
- `libltc11` → `libltc`  (matched after stripping suffix: 'libltc')
- `libmodplug1` → `libmodplug`  (matched after stripping suffix: 'libmodplug')
- `libmpcdec6` → `libmpcdec`  (matched after stripping suffix: 'libmpcdec')
- `libmysofa1` → `libmysofa`  (matched after stripping suffix: 'libmysofa')
- `libunistring2` → `libunistring`  (matched after stripping suffix: 'libunistring')
- `libxcb-cursor0` → `libxcb-cursor`  (matched after stripping suffix: 'libxcb-cursor')
- `network-manager-pptp-gnome` → `pptpd`  (explicit map suggested 'networkmanager-pptp' but only fuzzy )
- `libwpe-1.0-1` → `saxon`  (fuzzy match: 'saxon')
- `netcat-openbsd` → `snicat`  (explicit map suggested 'libressl-netcat' but only fuzzy matc)
- `timgm6mb-soundfont` → `soundfont-ydp-grand`  (fuzzy match: 'soundfont-ydp-grand')
- `nautilus-sendto` → `sushi`  (explicit map suggested 'nautilus-sendto' but only fuzzy matc)


## ❌ Manual TODO

Per user decision 2026-05-23, the following were moved to drop-candidate and intentionally **not** included in the generated flake. Install/configure as you need them on the new machine:

- **VirtualBox** — add `virtualisation.virtualbox.host.enable = true` and `vboxusers` to your user's `extraGroups` if you want it.
- **Disk encryption (LUKS+LVM)** — handled by `nixos-generate-config` on the target during install. Default in the placeholder `hardware-configuration.nix` is plain ext4.
- **Flox** — not in Nixpkgs; install via Flox's own installer (`curl -fsSL https://downloads.flox.dev/by-env/stable/deb/flox.x86_64.tar.gz | ...` — see flox.dev for current method).
- **cron** — use `services.cron.enable = true` if you want it; NixOS prefers systemd timers.
- **logrotate** — use `services.logrotate.enable = true`.
- **SSH authorized_keys** — your `~/.ssh/` either comes back via yadm (if tracked) or copy manually from the old machine.
- **GNOME Online Accounts (gtk)** — bundled in `gnome-control-center`, no separate package needed; configure via Settings → Online Accounts.
- **Python 3.10** — NixOS unstable has Python 3.13 by default. Use `python313` or pin a specific version per-project via Flox/devShells.
- **`~/.config/yadm/bootstrap`** is stale (Homebrew refs). Edit or remove from the yadm repo before cloning on the new machine.

User-installed toolchains (sdkman, cargo/rustup, krew, go, zig, JetBrains Toolbox) — re-run each installer on the new machine. yadm restores their configs.

## 🔄 Behavioral differences from Pop!_OS

- **Kernel:** Pop pinned 6.17.4 and 6.18.7. NixOS uses `pkgs.linuxPackages_latest` — moves with nixos-unstable.
- **Bootloader:** Pop used kernelstub-driven systemd-boot. NixOS uses systemd-boot directly. /recovery partition is Pop-only and goes away.
- **Init / logging:** No upstart/init metapackages or rsyslog — NixOS uses systemd + journald exclusively. `journalctl` replaces `/var/log/syslog`.
- **Firewall:** NixOS default is `networking.firewall.enable = true` with no open ports. Pop's ufw was inactive on the source.
- **Packages:** No PATH /usr/bin pollution. All system bins live in `/run/current-system/sw/bin`. User-installed binaries under `$HOME/.local/bin`, `~/.cargo/bin`, etc. work the same.
- **FHS:** /usr/local/bin and /opt are present but mostly empty. Scripts that hard-code `/bin/bash` or `/usr/bin/env bash` work fine; scripts that hard-code `/usr/bin/python3` will fail — use `#!/usr/bin/env python3`.
- **Display manager:** GDM (Wayland) replaces cosmic-greeter.
- **Desktop:** GNOME 47+ replaces COSMIC. ~/.config/cosmic/* is dead config (snapshot at `artifacts/raw/cosmic_config_values/` for posterity).
- **dconf:** GNOME dconf settings from Pop's GNOME-app fallbacks (~/.config/dconf) carry forward; COSMIC's RON config does not.
- **No Pop tooling:** pop-shop, pop-upgrade, system76-power, system76-scheduler, hp-vendor — all gone. Use `nixos-rebuild` for upgrades.
- **Multi-user Nix:** the existing `/nix/` scaffolding (nixbld1..32) on the source becomes redundant — NixOS owns `/nix` natively.

## Flatpaks to restore (manually after first boot)

```sh
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Apps (47 total on source). Cosmic-remote applets EXCLUDED (target is GNOME):
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub com.slack.Slack
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub io.github.cosmic_utils.sysinfo-applet
flatpak install -y flathub io.github.cosmic_utils.weather-applet
flatpak install -y flathub net.cozic.joplin_desktop
flatpak install -y flathub org.ferdium.Ferdium
flatpak install -y flathub org.freedesktop.Sdk.Extension.ziglang
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.gimp.GIMP.HEIC
flatpak install -y flathub org.gnome.Platform
flatpak install -y flathub org.siril.Siril
flatpak install -y flathub org.winehq.Wine.DLLs.dxvk
flatpak install -y flathub org.winehq.Wine.gecko
flatpak install -y flathub org.winehq.Wine.mono
flatpak install -y flathub us.zoom.Zoom
```

## Source-system data preserved

- `artifacts/raw/dotfiles/` — copies of .bashrc, .zshrc, .gitconfig, .vimrc, .profile, .zshenv
- `artifacts/raw/cosmic_config_values/` — sampled COSMIC config (RON) for archive
- `artifacts/raw/desktop_dconf.ini` — full GNOME dconf dump (321 lines, 66 sections)
- `artifacts/raw/yadm_files.txt` — list of yadm-tracked files
- `artifacts/raw/pkg_apt_manual.txt` — original apt-mark showmanual output
