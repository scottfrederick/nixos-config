{ inputs, ... }:
{
  # ============================================================
  # Claude Desktop for Linux (system-wide).
  #
  # Wraps Anthropic's OFFICIAL Linux .deb via the community flake
  # poeck/claude-desktop-nix-flake. The upstream .deb is repackaged,
  # not the Windows/macOS build — MCP, the Ctrl+Alt+Space quick-entry
  # popup, tray, and Claude Code all work.
  #
  # This is imported ONLY by home-hpone (personal machine). work-dell
  # is Ubuntu and isn't managed by this flake at all, so there's no
  # per-host guard needed — just don't import this from work-dell.
  #
  # Binary-cache note: building an Electron app from source is slow.
  # The flake author publishes a Cachix cache; adding it here means the
  # first `nixos-rebuild switch` pulls a prebuilt binary instead of
  # compiling. Safe to remove if you'd rather build locally.
  # ============================================================
  imports = [ inputs.claude-desktop.nixosModules.default ];

  programs.claude-desktop.enable = true;

  nix.settings = {
    substituters = [ "https://claude-desktop.cachix.org" ];
    trusted-public-keys = [
      "claude-desktop.cachix.org-1:Yx8g/hMizTX+Hd7X6+deGjrmYWLzOI57BFDqp0GXBTk="
    ];
  };
}
