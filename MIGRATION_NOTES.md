# Migration Notes — Pop!_OS → NixOS

Generated 2026-05-23. Source: `artifacts/inventory.json` + `artifacts/classification.json`.
This file replaces the Phase-3 draft and reflects all Phase-4 fixes.

- **Source system:** Pop!_OS 24.04 LTS, COSMIC desktop, kernel 6.18.7-76061807-generic, LUKS+LVM+ext4 root, zram swap, NVMe x86_64.
- **Targets:** two machines, both running NixOS unstable with GNOME on Wayland (GDM).
  - `home-hpone` — personal (the inventoried machine; this is its successor).
  - `work-dell` — employer-owned; currently a stub that inherits everything from `modules/common.nix`.
- **Dotfiles** stay yadm-managed (`https://github.com/scottfrederick/yadm`).
- **Toolchains** (sdkman, cargo, krew, go, zig, JetBrains Toolbox) stay user-installed via yadm bootstrap.

## Classification summary (323 items)

| Disposition           | Count |
|-----------------------|------:|
| translate             |  110  |
| translate-with-review |   19  |
| preserve-verbatim     |   48  |
| drop-candidate        |  144  |
| yadm-instead          |    2  |
| flag-for-manual       |    0  |

Drop-candidate breakdown:

| Reason | Count |
|---|---:|
| Pattern-matched (kernel-image, l10n, multilib :i386, versioned llvm/icu placeholders, hyphen/mythes/hunspell, language-pack-*, libreoffice-help/l10n) | 87 |
| Ubuntu/Pop tooling (apport, ua, gpu-manager, dkms, init, rsyslog, ufw, software-properties-common, sessioninstaller, isc-dhcp-common, distro-info, cdbs, kpartx-boot, libnetplan0, pop-*, system76-*, com.system76.*, hp-vendor) | 24 |
| User-deferred 2026-05-23 (virtualbox, cron, logrotate, flox, gcm/python-3.10/niche libs, ssh keys, LUKS-on-flake) | 17 |
| Haskell-fuzzy-miss transitive C-libs (user-decided to drop) | 11 |
| Other (libpop-*, pop-container-*, libnss-mdns:i386) | 4 |
| Pre-existing multi-user Nix install | 1 |

## ✅ Confidently translated

System level (in `modules/`):
- **GNOME on Wayland via GDM** (`services.desktopManager.gnome.enable`, `services.displayManager.gdm.enable` — no `wayland=true`, removed in GNOME 50).
- **NetworkManager** with iwd backend; `networking.firewall.enable = true` (no open ports by default).
- **PipeWire audio** with 32-bit support; replaces PulseAudio.
- **Printing via CUPS + hplip + Avahi (mDNS open in firewall)**.
- **Bluetooth** (`hardware.bluetooth.enable`, blueman) — verified inactive in QEMU (no controller), will activate on real hardware.
- **chrony, systemd-resolved, AppArmor, switcheroo-control, udisks2**.
- **zram swap on** (matches Pop's `pop-default-settings-zram`).
- **32-bit graphics + Pipewire 32-bit** (replaces ~29 :i386 apt libs from the source).
- **Locale en_US.UTF-8**, console keymap `us-acentos`, X/Wayland `xkb.layout=us, variant=intl`.
- **Flatpak runtime** (`services.flatpak.enable`) + `flatpak-repo.service` oneshot that registers Flathub after `network-online.target` (Phase 4 fix: was racing DNS).
- **1Password** GUI + CLI via dedicated `programs._1password{,-gui}` module.
- **Fonts**: Noto + Noto-CJK-{sans,serif} + Noto-Color-Emoji + Liberation + DejaVu + JetBrains Mono + Fira Code + Source Code Pro + Arphic ukai/uming.
- **ibus** input methods: libpinyin, chewing, table, table-others (CJK/Cangjie/Wubi).
- **Nix flakes** experimental features enabled, weekly GC, auto-optimise-store.
- **VS Code, git-credential-manager, gnome-tweaks** — added in the yadm-bootstrap-analysis pass to match what bootstrap installs on Ubuntu.
- **Docker** declarative (`virtualisation.docker.enable`, weekly autoPrune) + `docker` group on user.
- **nix-ld** enabled with common runtime libs (zlib, fuse3, icu, nss, openssl, curl, expat, libxml2) — required for SDKMAN-Java + JetBrains Toolbox + krew to find their interpreter on NixOS.
- **User `sfrederick`** (UID 1000, zsh shell) with groups `wheel networkmanager video audio input dialout docker`. SSH keys not pre-populated (deferred to yadm/manual).
- **41 apt packages** mapped 1:1 to confirmed Nixpkgs attrs (full list in `modules/base.nix`).
- **+17 translate-with-review apt packages** included with `# REVIEW:` comments in `modules/base.nix`.

Per-user (`home/sfrederick/`):
- Home Manager profile is intentionally thin. Only `pkgs.yadm` in `home.packages` and `programs.home-manager.enable`. **No `programs.zsh`, no `programs.bash`, no `programs.git`** — those would write rc files that conflict with yadm's clone. (See the long comment in `home/sfrederick/programs.nix`.)

## ⚠️ Needs review

System level:
- **dconf snapshot** at `artifacts/raw/desktop_dconf.ini` (66 GNOME-app sections from Pop's GNOME fallback apps). Apply selectively via `programs.dconf` or `dconf load / < ...` after first login.
- **Keymap us-acentos** — translated to console + X/Wayland us+intl. Verify dead-key behavior matches what you had on Pop.
- **Timezone** — set to `America/Denver` in `modules/locale.nix`; source system's TZ wasn't captured in the inventory. Confirm or change.
- **Supported locales** — only en_US.UTF-8 active. 10 other locales commented out in `modules/locale.nix`; uncomment any you actually want.

apt-package translations with fuzzy matches (in `modules/base.nix` with `# REVIEW:` comments):

| apt name | Nix attr | Why review |
|---|---|---|
| libbpf0 | libbpf | suffix `-0` stripped — likely correct |
| libdc1394-25 | libdc1394 | suffix `-25` stripped |
| libestr0 | libestr | suffix `-0` stripped |
| libfastjson4 | libfastjson | suffix `-4` stripped |
| libffado2 | libffado | suffix `-2` stripped |
| libltc11 | libltc | suffix `-11` stripped |
| libmodplug1 | libmodplug | suffix `-1` stripped |
| libmpcdec6 | libmpcdec | suffix `-6` stripped |
| libmysofa1 | libmysofa | suffix `-1` stripped |
| libunistring2 | libunistring | suffix `-2` stripped |
| libxcb-cursor0 | libxcb-cursor | suffix `-0` stripped |
| network-manager-pptp-gnome | **pptpd** | fuzzy — wrong direction; `networkmanager-pptp` is the right attr if you need PPTP at all. Delete unless you actually use a PPTP VPN. |
| libwpe-1.0-1 | **saxon** | fuzzy — wrong; saxon is a Java XSLT processor. Real attr is `wpebackend-fdo`/`libwpe`. Delete if not needed. |
| libwpebackend-fdo-1.0-1 | **saxon** | same as above. |
| netcat-openbsd | **snicat** | fuzzy — wrong; the real attr is `netcat-openbsd` or `libressl-netcat`. Likely just delete (NixOS includes a netcat by default). |
| timgm6mb-soundfont | **soundfont-ydp-grand** | fuzzy — wrong; `timgm6mb-soundfont` doesn't exist in Nixpkgs. If you need SF2 fonts, pick one explicitly. |
| nautilus-sendto | **sushi** | fuzzy — wrong; sushi is the file previewer. `nautilus` already supports send-to via Online Accounts. Delete. |

Recommendation: open `modules/base.nix`, search for `# REVIEW:`, delete the 6 obviously-wrong ones (pptpd, two saxons, snicat, soundfont-ydp-grand, sushi) unless you actually want them. The 11 soname-stripped ones are probably correct.

## ❌ Manual TODO (deliberately not in the flake)

Per user decision 2026-05-23, install on the new machine when needed:

- **VirtualBox** — add `virtualisation.virtualbox.host.enable = true` and uncomment `vboxusers` in `modules/users.nix`. Source had VBox 7.2.6 active.
- **Disk encryption (LUKS+LVM)** — handled by `nixos-generate-config` on the target machine during install. Placeholder `hardware-configuration.nix` assumes plain ext4. If you want encryption, also add `boot.initrd.luks.devices.<name> = { device = "/dev/disk/by-uuid/..."; }` after the install.
- **Flox** — not in Nixpkgs. Install via Flox's own installer on first boot (`curl -fsSL https://downloads.flox.dev/by-env/stable/linux-x86_64/flox.tar.gz | ...` — check flox.dev for current method).
- **cron** — use `services.cron.enable = true` if you want it; NixOS prefers systemd timers.
- **logrotate** — `services.logrotate.enable = true`.
- **SSH `authorized_keys`** — either yadm-restored (if you start tracking `.ssh/`) or copy manually from the source machine.
- **GNOME Online Accounts** — bundled into `gnome-control-center`; configure via Settings → Online Accounts.
- **Python 3.10** — NixOS unstable defaults to 3.13. For per-project pinning use a `flake.nix` devShell or a Flox env.
- **Niche apt items** (ser-player, indi-asi, libavtp0, fxload) — add explicitly if needed.

Source-system files captured for reference:
- `artifacts/raw/dotfiles/` — copies of `.bashrc`, `.zshrc`, `.gitconfig`, `.vimrc`, `.profile`, `.zshenv`.
- `artifacts/raw/cosmic_config_values/` — sampled COSMIC RON config (archive only).
- `artifacts/raw/desktop_dconf.ini` — full GNOME dconf dump (321 lines, 66 sections).
- `artifacts/raw/yadm_files.txt` — list of yadm-tracked files (80 entries).
- `artifacts/raw/pkg_apt_manual.txt` — original `apt-mark showmanual` (235 entries).
- `artifacts/raw/yadm_bootstrap.txt` — the old (stale) yadm bootstrap; replaced by your in-tree `~/.config/yadm/bootstrap.d/*.sh`.

## 🔄 Behavioral differences from Pop!_OS

- **Init / logging:** no rsyslog, no `/var/log/syslog`. Use `journalctl`.
- **Kernel:** `pkgs.linuxPackages_latest` (currently 7.0.9), not Pop's two-kernel scheme. Override per host with `boot.kernelPackages = pkgs.linuxPackages_lts` if you want LTS.
- **Bootloader:** systemd-boot directly. No kernelstub wrapper. No `/recovery` partition.
- **Firewall:** on by default with no open ports. (Pop's ufw was inactive.)
- **PATH:** all system binaries under `/run/current-system/sw/bin/`. Scripts that hard-code `#!/usr/bin/python3` won't work; use `#!/usr/bin/env python3`. `#!/bin/bash` is fine (NixOS keeps that symlink).
- **`/usr/local/bin`, `/opt`:** writable but mostly empty. yadm-bootstrap installers that drop binaries here (jetbrains-fonts.sh) are skipped on NixOS via the bootstrap.d gating you added.
- **Display manager:** GDM Wayland. cosmic-greeter, lightdm, sddm — none.
- **Desktop:** GNOME 50+. COSMIC's `~/.config/cosmic/*` is dead config; the snapshot at `artifacts/raw/cosmic_config_values/` is for archive only.
- **dconf:** GNOME-fallback dconf settings from Pop carry forward via the snapshot. COSMIC's RON config does not.
- **No Pop tooling:** pop-shop, pop-upgrade, system76-power, system76-scheduler, com.system76.* daemons, hp-vendor — all gone. Use `nixos-rebuild switch` for upgrades.
- **Multi-user Nix scaffolding** (`/nix/store`, `nixbld1..32`) — NixOS owns this natively; the source-system multi-user install is irrelevant on the new box.
- **Login shell setup:** `programs.zsh.enable = true` (system-side, in `modules/users.nix`) puts zsh in `/etc/shells`; `users.users.sfrederick.shell = pkgs.zsh` sets it as the login shell. yadm restores `.zshrc` and all of `zshrc.d/*.zsh`.
- **Home Manager owns:** the HM profile dir under `~/.nix-profile/`, the `yadm` binary install, and nothing else. **Yadm owns** `.zshrc`, `.bashrc`, `.gitconfig`, `.vimrc`, `.config/ghostty/config`, `zshrc.d/`, `.zsh_plugins.{txt,zsh}`, `.flox/`, `~80 other files`.

## Flatpaks to restore post-install

Handled by `yadm bootstrap` (`50-flatpak-apps.sh` → `~/.setup/flatpak/*.sh`). The bootstrap calls `flatpak install -y` for each app, gated by `local.class` where appropriate. `flatpak-repo.service` (from `modules/flatpak.nix`) registers Flathub on first boot, so by the time bootstrap runs the remote is already in place.

**Shared (installed on every machine):**
- `com.brave.Browser` (brave.sh)
- `org.ferdium.Ferdium` (ferdium.sh)
- `com.github.tchx84.Flatseal` (flatseal.sh) — flatpak permission inspector
- `org.gimp.GIMP` (gimp.sh)
- `net.cozic.joplin_desktop` (joplin.sh)
- `com.slack.Slack` (slack.sh)
- `com.spotify.Client` (spotify.sh)

**home-hpone only:**
- `org.siril.Siril` (siril.sh) — astrophotography stacker
- `org.winehq.Wine` + DXVK/gecko/mono extensions (wine.sh) — registers the `flathub-beta` remote since Wine isn't in standard Flathub

**Excluded (per user decision 2026-05-23):**
- `us.zoom.Zoom` — dropped from restore list
- `org.freedesktop.Sdk.Extension.ziglang` — dropped (not needed)
- `io.github.cosmic_utils.*` — COSMIC-only (target is GNOME)

**Not handled by bootstrap; install manually if needed:**
- `org.gimp.GIMP.HEIC` — GIMP HEIC plugin extension

## Phase 4 validation evidence

- Toplevel system closure built clean for `home-hpone` (~14 GB pulled from cache.nixos.org).
- VM boot reached `multi-user.target` in 80 seconds.
- All expected services active (NetworkManager, systemd-resolved, dbus-broker, chrony, docker, flatpak-repo, systemd-udevd). Bluetooth inactive only because QEMU has no controller.
- All expected binaries present in `/run/current-system/sw/bin/` (git, yadm, zsh, docker, code, gnome-tweaks, 1password, git-credential-manager).
- User `sfrederick` provisioned correctly with all 7 expected groups including `docker`.
- nix-ld active at `/run/current-system/sw/share/nix-ld/lib`.
- Failed-units list empty.

Full report: `artifacts/validation-report.json`. Raw VM output: `artifacts/smoketest-output.txt`.

## Things not exercised in QEMU (verify on real hardware)

- GDM + GNOME graphical session (smoketest variant disables them for boot speed; the real `home-hpone` build evaluated and compiled fine).
- Bluetooth (no controller in QEMU).
- PipeWire audio (no audio device).
- 32-bit graphics / multilib.
- nvidia/intel/amd GPU drivers (none in QEMU; configure per-host in `hosts/<name>/default.nix`).
- Real disk encryption / LUKS unlock at boot.
- Printer auto-discovery via Avahi/CUPS.
- USB / Bluetooth peripherals.
