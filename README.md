# dms

**[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), its plugins and greeter, as one flake input.**

[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org)
[![Home Manager](https://img.shields.io/badge/Home_Manager-module-41439A?style=flat-square)](https://github.com/nix-community/home-manager)
[![Quickshell](https://img.shields.io/badge/built_on-Quickshell-E0A458?style=flat-square)](https://github.com/quickshell-mirror/quickshell)

A thin layer over upstream's modules: it enables DMS on NixOS with a current
Quickshell, hands every home-manager user a configured shell (plugins, niri
integration, a Stylix theme), and re-exports the
[dank-greeter](https://github.com/AvengeMedia/dank-greeter) module. Part of
[viicslen-nix/nixos](https://github.com/viicslen-nix/nixos), where it is the
`flakes/dms` submodule.

## Outputs

| Output | What it is |
| --- | --- |
| `nixosModules.default` / `.dms` | Enables `programs.dank-material-shell` and adds the home-manager module to `home-manager.sharedModules` |
| `nixosModules.greeter` | `dank-greeter`'s module, re-exported unchanged (`programs.dms-greeter`) |
| `homeManagerModules.default` / `.dms` | The per-user shell config, for standalone use |
| `formatter.<system>` | treefmt: deadnix, statix, alejandra |
| `checks.<system>.treefmt` | treefmt in check mode |
| `checks.<system>.statix` | `statix check`, which also fails on lints `statix fix` cannot fix |

Systems: `x86_64-linux`, `aarch64-linux`.

## Usage

```nix
# flake.nix
inputs.dms = {
  url = "github:viicslen-nix/dms";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# a NixOS module
{inputs, ...}: {
  imports = [
    inputs.dms.nixosModules.default
    inputs.dms.nixosModules.greeter # optional
  ];

  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
  };
}
```

With home-manager loaded as a NixOS module, nothing else is needed: the
home-manager half is injected through `sharedModules`. Without home-manager on
the system, import `inputs.dms.homeManagerModules.default` in the user's
config yourself.

## What it configures

### NixOS — `nixos.nix`

| Option | Default | Effect |
| --- | --- | --- |
| `dms.autoEnable` | `true` | Sets `programs.dank-material-shell.enable` and points `quickshell.package` at this flake's `quickshell` input |

The home-manager module is added to `home-manager.sharedModules` whenever the
`home-manager` option exists, whatever `dms.autoEnable` says.

When the consuming config declares `modules.desktop.askpass` (the program sudo
runs for a password with no tty), the shell sets it to a `dms-askpass` wrapper
while `programs.dank-material-shell.enable` is on. The wrapper asks through the
`dankPinentry` plugin's modal via `pinentry-dms`. If DMS is not running or the
plugin is not loaded, it hands off to the option's default program instead.
Cancelling the modal fails sudo; it does not fall back.

### Home Manager — `hm.nix`

Imports upstream's `niri` and `dank-material-shell` home modules and the
`dms-plugin-registry` module, then sets:

- **Shell** — `programs.dank-material-shell` with VPN, calendar (khal),
  dynamic theming (matugen), audio visualizer (cava) and system monitoring
  (dgop) widgets, run as a systemd user service.
- **Plugins** — `emojiLauncher`, `dockerManager`,
  `linuxWallpaperEngine`, `dankPinentry`, `dankMenu`, `clipShare`,
  `dmsThemeSync`, `githubNotifier`, `aiOverviewControl`, `claudeCodeUsage`,
  `dmsAgent`, `cliproxyQuota`, `chatManager`, `chatRunner`, `whatsappChat`.
  Plugins that only make sense on one machine stay installed by hand through
  DMS's own plugin manager. `chatManager` and `whatsappChat` are rebuilt with
  their Go daemons compiled into `bin/`, since the registry ships source only;
  bump their `vendorHash` when the registry moves them. The command-line tools
  the plugins call and nothing else installs go in `home.packages`, next to the
  plugin list. `gpu-screen-recorder` is the exception: clipShare needs its
  setcap wrapper, so it is enabled in `nixos.nix`.
- **Moving a hand-installed plugin to home-manager** — uninstall it first.
  DMS's plugin manager installs plugins as symlinks, and home-manager never
  backs up a symlink it does not own, so activation fails with "would be
  clobbered". `dms plugins uninstall <id>` keeps the plugin's settings.
- **niri** — `niri.includes` makes DMS's `binds`, `alttab`, `wpblur`,
  `colors`, `layout`, `outputs` and `windowrules` override niri-flake's
  generated config (renamed to `hm.kdl`).
- **Stylix** — when Stylix is enabled, upstream's Stylix target is turned off
  and a base16-derived theme is written to
  `~/.config/DankMaterialShell/themes/stylix.json` instead.
- **Autostart** — the `dms` user service is bound to `desktop-shell.target`
  (`PartOf` + `WantedBy`), a target the consuming config must declare and its
  compositor must start.

> [!IMPORTANT]
> The shell, its service and the niri includes are only enabled when
> `osConfig.modules.desktop.shell == "dms"` — an option declared by the
> consuming NixOS config, not by this flake. On a standalone home-manager eval
> (no `osConfig`) it defaults to enabled. The wrapper in `flake.nix` must keep
> forwarding `osConfig` to `hm.nix`; drop it and the gate silently reads the
> fallback.

## Inputs

| Input | Source |
| --- | --- |
| `nixpkgs` | `nixos-unstable` |
| `dms` | `AvengeMedia/DankMaterialShell` |
| `dank-greeter` | `AvengeMedia/dank-greeter` (the greeter left the main repo) |
| `dms-plugin-registry` | `AvengeMedia/dms-plugin-registry` |
| `quickshell` | `quickshell-mirror/quickshell` |
| `dank-pinentry` | `pacman99/DankPinentry`, for the `pinentry-dms` binary behind `dms-askpass` |
| `treefmt-nix` | `numtide/treefmt-nix`, for `nix fmt` and the checks |

All of them follow `nixpkgs`.

## Development

```bash
nix fmt            # deadnix, statix, alejandra
nix flake check    # formatting + statix gates
nix flake update   # bump the pins
```

> [!NOTE]
> Inside `viicslen-nix/nixos`, hosts build the **root** lock's pins, not this
> flake's. After bumping here, re-lock it in the root with
> `just update-subflake dms`.
