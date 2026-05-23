{ config, pkgs, lib, ... }:
{
  # Test-only overlay for Phase 4 smoke-testing. Imports the real host
  # config and adds an autologin + smoke-test runner that writes its
  # results to the shared virtfs directory and powers off.
  #
  # Do NOT import this from hosts/home-hpone/default.nix. It is
  # consumed only by the VM smoke-test build:
  #
  #   nix build .#nixosConfigurations.home-hpone-smoketest.config.system.build.vm
  #
  # The flake.nix exposes home-hpone-smoketest as a sibling derivation.

  imports = [ ./default.nix ];

  # ----- Autologin so the smoke test can run unattended -----
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.initialPassword = "smoketest";

  # ----- Disable services we don't need during the test -----
  # Skip the GDM/GNOME startup so boot reaches the runner faster.
  # NOTE: this only affects the smoketest variant; real home-hpone
  # still brings up GNOME.
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.enable = lib.mkForce false;

  # Flatpak service tries to talk to the system bus before it's ready
  # during the rushed smoke-test boot; not needed for what we're checking.
  services.flatpak.enable = lib.mkForce false;

  # ----- The smoke test itself -----
  systemd.services.smoketest = {
    description = "Phase 4 smoke test runner";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      TimeoutStartSec = "180s";   # hard cap so the VM can never wedge
    };
    path = with pkgs; [ coreutils systemd util-linux gnugrep gnused which ];
    script = ''
      # NOTE: don't set -e — we want every probe to run even if some fail.
      OUT=/tmp/xchg/smoketest.txt
      mkdir -p /tmp/xchg
      exec > >(tee -a "$OUT") 2>&1

      echo "===== SMOKETEST START $(date -Iseconds) ====="
      echo
      echo "--- hostname ---"
      cat /etc/hostname
      echo
      echo "--- kernel ---"
      uname -a
      echo
      echo "--- systemd is-system-running (60s timeout) ---"
      timeout 60 systemctl is-system-running --wait || echo "(is-system-running timed out or returned non-zero)"
      echo
      echo "--- failed units ---"
      systemctl --failed --no-legend --no-pager || true
      echo
      echo "--- expected services up? ---"
      for svc in \
          NetworkManager.service \
          systemd-resolved.service \
          systemd-udevd.service \
          dbus-broker.service \
          chronyd.service \
          bluetooth.service \
          docker.service \
          flatpak-repo.service \
          ; do
        active=$(systemctl is-active "$svc" 2>&1 || true)
        enabled=$(systemctl is-enabled "$svc" 2>&1 || true)
        printf '  %-32s active=%-12s enabled=%s\n' "$svc" "$active" "$enabled"
      done
      echo
      echo "--- user account exists? ---"
      if grep -q "^sfrederick:" /etc/passwd; then
        grep "^sfrederick:" /etc/passwd
      else
        echo "  ABSENT"
      fi
      echo
      echo "--- user groups ---"
      groups sfrederick 2>&1 || true
      echo
      echo "--- zsh on /etc/shells? ---"
      grep -E "/zsh" /etc/shells || echo "  ABSENT"
      echo
      echo "--- selected binaries in /run/current-system/sw/bin/ ---"
      SYS_BIN=/run/current-system/sw/bin
      for bin in git yadm zsh docker code gnome-tweaks 1password git-credential-manager; do
        if [ -x "$SYS_BIN/$bin" ]; then
          printf '  %-28s %s\n' "$bin" "$SYS_BIN/$bin"
        else
          printf '  %-28s %s\n' "$bin" "MISSING"
        fi
      done
      echo
      echo "--- nix-ld present? ---"
      ls -l /run/current-system/sw/share/nix-ld/lib 2>/dev/null | head -5 || echo "  no nix-ld dir"
      echo
      echo "--- /etc/machine-id ---"
      cat /etc/machine-id
      echo
      echo "===== SMOKETEST END $(date -Iseconds) ====="
      sync
      # Power off after a beat so the file write completes.
      sleep 2
      systemctl poweroff
    '';
  };
}
