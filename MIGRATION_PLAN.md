# Migration Plan — Pop!_OS → NixOS

Concrete steps to get this flake running on a new machine. Read `MIGRATION_NOTES.md` first for context on what's in the flake and what's intentionally not.

## Stage 0 — before you touch any new machine

Some of these are one-time prep that should happen on the **source** (current Pop!_OS) machine while it's still your daily driver.

- [ ] **Commit and push pending yadm changes.** Phase 1-3 of the migration touched three of your yadm-tracked files:
  ```sh
  cd && yadm status
  # Should show: M .config/yadm/bootstrap.d/15-shell.sh
  #              M .config/yadm/bootstrap.d/50-flatpak-apps.sh
  #              M .config/yadm/bootstrap.d/60-linux-manual.sh
  yadm add -u
  yadm commit -m "bootstrap: make flatpak/shell/linux-manual steps NixOS-aware"
  yadm push
  ```
  Until you push, a fresh `yadm clone` on the new machine will get the old (apt-only) bootstrap.

- [ ] **Commit and push `~/.setup/install-yadm-nixos.sh`.** It's new and currently untracked in the setup repo:
  ```sh
  cd ~/.setup && git status   # shows: ?? install-yadm-nixos.sh
  git add install-yadm-nixos.sh
  git commit -m "Add NixOS pre-bootstrap counterpart to install-yadm.sh"
  git push
  ```

- [ ] **Push this flake somewhere you can clone from on the new machine.** Right now it lives at `~/nixos-config/` on the source box as a local git repo with 3 commits:
  ```
  99b5659 phase 4: flatpak-repo network-online dep + smoketest harness fixes
  f68e024 phase 4: fixes from flake check
  8352ead phase 3 generated flake
  ```
  Create `github.com/scottfrederick/nixos-config` (or similar), then on this box:
  ```sh
  cd ~/nixos-config
  git remote add origin git@github.com:scottfrederick/nixos-config.git
  git push -u origin main
  ```

- [ ] **(Recommended)** Boot the smoketest VM image one more time on this machine so you've seen it work before depending on it. The image already exists at `/tmp/home-hpone-vm-smoketest/bin/run-home-hpone-vm`; otherwise rebuild with:
  ```sh
  cd ~/nixos-config
  nix --extra-experimental-features 'nix-command flakes' build \
    .#nixosConfigurations.home-hpone-smoketest.config.system.build.vm \
    --out-link /tmp/home-hpone-vm
  /tmp/home-hpone-vm/bin/run-home-hpone-vm -m 4096 -smp 2 -nographic
  # Watch boot to login prompt. Ctrl-A then X to kill QEMU.
  ```

- [ ] **Decide encryption.** Source machine has LUKS+LVM+ext4 root. Default in the placeholder `hosts/home-hpone/hardware-configuration.nix` is plain ext4. If you want encryption on the new machine, you'll choose at install time (Stage 2 below).

- [ ] **Decide whether to dual-boot or full-replace.** This plan assumes full-replace (a separate machine being repurposed). If you want dual-boot on the same disk as Pop, that's a different procedure — partition shrink + separate ESP entry; not covered here.

## Stage 1 — try the VM on real hardware (optional but recommended)

You already have a working smoketest VM image. Run it once on the actual hardware destined for `home-hpone` (just for sanity — checks that the kernel boots on that CPU/firmware):

```sh
# Copy the .nix-store closure for the VM to a USB drive, or just rebuild
# on the new machine after installing Nix temporarily.
```

In practice this step is rarely worth the effort — Stage 2 (the actual install) takes about as long. Skip unless you suspect hardware-specific kernel issues.

## Stage 2 — first install on the target machine

This is the actual cutover. Plan ~1-2 hours per machine (mostly download time and waiting for nixos-install).

1. **Boot the NixOS installer ISO** (minimal or graphical, doesn't matter — we don't use the GUI). Download from `nixos.org/download` if you don't have one.

2. **Partition the disk and create filesystems.** If encrypting:
   ```sh
   # Example for a single NVMe drive at /dev/nvme0n1
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

   cryptsetup luksFormat /dev/nvme0n1p2
   cryptsetup open /dev/nvme0n1p2 cryptroot
   mkfs.ext4 -L nixos /dev/mapper/cryptroot
   mkfs.fat -F 32 -n boot /dev/nvme0n1p1
   ```
   If not encrypting, skip the cryptsetup lines and mkfs straight onto p2.

3. **Mount:**
   ```sh
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

4. **Generate hardware-configuration.nix from this machine:**
   ```sh
   nixos-generate-config --root /mnt
   ```
   This writes `/mnt/etc/nixos/hardware-configuration.nix` with the right `fileSystems.*`, kernel modules, and firmware for this hardware.

5. **Pull the flake:**
   ```sh
   cd /mnt/etc/nixos
   rm configuration.nix              # not needed — flake-based install
   nix-shell -p git
   git clone https://github.com/scottfrederick/nixos-config.git .
   # Replace the placeholder hardware-configuration.nix:
   cp /mnt/etc/nixos/hardware-configuration.nix hosts/home-hpone/hardware-configuration.nix
   # (or hosts/work-dell/ if installing the work machine)
   ```
   If you chose LUKS in step 2, also append to `hosts/home-hpone/default.nix`:
   ```nix
     boot.initrd.luks.devices.cryptroot = {
       device = "/dev/disk/by-uuid/$(blkid -s UUID -o value /dev/nvme0n1p2)";
       allowDiscards = true;
     };
   ```
   (Substitute the actual UUID; don't use shell substitution in the .nix file.)

6. **Install the system:**
   ```sh
   nixos-install --flake .#home-hpone --no-root-password
   ```
   - `--no-root-password` because we set `users.users.sfrederick` with `wheel`; root login isn't needed.
   - First run downloads ~14 GB from cache.nixos.org. About 15–30 minutes on a typical connection.
   - At the end you'll be prompted to set a password — set one for `sfrederick`:
     ```sh
     nixos-enter --root /mnt -c 'passwd sfrederick'
     ```

7. **Reboot:**
   ```sh
   umount -R /mnt
   reboot
   ```

8. **First boot.** GDM should come up. Log in as `sfrederick`.

## Stage 3 — restore $HOME and toolchains

After the first login, $HOME is empty. yadm + bootstrap rebuilds it:

1. **Open a terminal** (Ctrl-Alt-T, or pick GNOME Terminal / Ghostty if you symlinked it).

2. **Run the NixOS install-yadm script:**
   ```sh
   curl -fsSL https://raw.githubusercontent.com/scottfrederick/setup/main/install-yadm-nixos.sh -o /tmp/install-yadm-nixos.sh
   chmod +x /tmp/install-yadm-nixos.sh
   /tmp/install-yadm-nixos.sh home-hpone     # or work-dell
   ```
   What this does:
   - Verifies we're on NixOS (refuses to run on Ubuntu).
   - Verifies `yadm` and `git` are on PATH (installed by the flake).
   - Runs `yadm clone --bootstrap=no https://github.com/scottfrederick/yadm`.
   - Sets `yadm config local.class home-hpone` (or `work-dell`).
   - Runs `yadm alt` so class-dependent alternates get linked.
   - Runs `yadm bootstrap`, which runs every `~/.config/yadm/bootstrap.d/[0-9]*-*.sh` in order:
     - `10-base-system.sh` — no-op on NixOS (apt-gated).
     - `15-shell.sh` — no-op for the apt path; **does** clone oh-my-zsh + zsh-snap into $HOME (distro-agnostic now).
     - `25-setup-repo.sh` — clones ~/.setup.
     - `30-apt-core.sh`, `40-apt-apps.sh`, `50-flatpak-apps.sh` (apt parts) — no-op on NixOS.
     - `50-flatpak-apps.sh` (flatpak parts) — installs GIMP/Joplin/Slack/Spotify/Ferdium via `flatpak install`.
     - `60-linux-manual.sh` — installs sdkman, jetbrains-toolbox, krew into $HOME. `jetbrains-fonts.sh` skipped on NixOS (font already installed declaratively).
     - `70-scripts-repo.sh` — clones ~/.scripts.

3. **Open a fresh terminal** so $PATH picks up the new SDKMAN / krew / JetBrains bins.

4. **Restore flatpaks** (services.flatpak.enable is on, flatpak-repo.service registered flathub; just install the apps):
   ```sh
   flatpak install -y flathub \
     com.brave.Browser com.slack.Slack com.spotify.Client \
     net.cozic.joplin_desktop org.ferdium.Ferdium \
     org.gimp.GIMP org.gimp.GIMP.HEIC org.siril.Siril \
     org.winehq.Wine.DLLs.dxvk org.winehq.Wine.gecko org.winehq.Wine.mono \
     us.zoom.Zoom org.freedesktop.Sdk.Extension.ziglang
   ```

5. **Apply GNOME dconf settings (optional):**
   ```sh
   cd ~/nixos-config-artifacts    # wherever you copied artifacts/
   dconf load / < raw/desktop_dconf.ini
   ```
   Skip if you'd rather start fresh.

6. **Restore NetworkManager profiles (optional, if you want WiFi creds preserved):**
   On the source machine: `sudo tar czf /tmp/nm.tar.gz -C /etc/NetworkManager/system-connections .`
   On the new machine: `sudo tar xzf /tmp/nm.tar.gz -C /etc/NetworkManager/system-connections && sudo systemctl restart NetworkManager`

7. **Install Flox (deferred — not in the flake):**
   Follow current instructions at `flox.dev`.

8. **Re-initialize SDKMAN candidates:**
   ```sh
   sdk install java       # picks default; or `sdk install java <version>`
   sdk install maven
   ```

9. **Re-initialize krew plugins** if you used any:
   ```sh
   kubectl krew install <plugin>
   ```

## Stage 4 — verify

Quick checks to confirm the migration worked:

```sh
# System health
systemctl is-system-running
systemctl --failed
journalctl -p err --no-pager -b

# Expected services
systemctl is-active NetworkManager bluetooth chrony docker
systemctl is-enabled flatpak-repo

# Login shell
echo "$SHELL"                                  # /run/current-system/sw/bin/zsh
getent passwd $USER | cut -d: -f7

# Dotfiles
yadm status                                    # should be clean
ls ~/.zshrc ~/.gitconfig ~/.vimrc              # all present

# Toolchains (after a fresh shell)
which java mvn jetbrains-toolbox kubectl-krew
nix --version
flox --version

# Flatpak apps
flatpak list --app

# Yadm class is set
yadm config local.class

# Bluetooth & WiFi visible in GNOME Settings
```

## Stage 5 — second machine

When ready to do `work-dell`:

1. **Inventory the work machine first** (re-run the Phase 1-2 process there). Most importantly: check GPU vendor (NVIDIA?), screen DPI, peripheral list, any corp-mandated software.

2. **Diff the inventory** against what's already in `modules/common.nix`. Anything specific to work-dell goes in `hosts/work-dell/default.nix` (which currently has commented examples).

3. **Follow Stages 2–4** above, substituting `work-dell` for `home-hpone` everywhere.

The `home-hpone` configuration is untouched by any work-dell changes; the shared `modules/` get whatever you add for work, but per-host overrides keep the two coherent.

## Rollback

If something goes wrong post-cutover:

- **Boot a previous generation:** at the systemd-boot menu, pick a `NixOS — Configuration <N-1>` entry. NixOS keeps every generation until you GC. Boots into the prior known-good state.
- **From a running NixOS:** `nixos-rebuild switch --rollback` switches the running system back one generation without rebooting.
- **From a borked first install:** the source Pop machine is still your fallback until you wipe it. Do not wipe the source machine until you've used the new NixOS install for at least a week.

## What you don't need to do

- Don't migrate `/nix/store` from the source machine. NixOS will rebuild it from cache.nixos.org.
- Don't try to preserve the multi-user Nix daemon scaffolding (`nixbld1..32` users). NixOS handles that natively.
- Don't copy `~/.cache/`, `~/.mozilla/`, browser profiles, etc. unless you want to — those are user-data decisions, not migration decisions.
- Don't worry about `/etc` modifications; the flake captures everything system-side that matters.
