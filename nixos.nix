{
  lib,
  config,
  options,
  pkgs,
  inputs,
  self,
  ...
}: let
  cfg = config.programs.dank-material-shell;
  pinentry-dms = inputs.dank-pinentry.packages.${pkgs.stdenv.hostPlatform.system}.pinentry-dms;

  # Speaks askpass to sudo and Assuan to pinentry-dms; falls back while DMS or the plugin is down.
  askpass = pkgs.writeShellScript "dms-askpass" ''
    PATH=${lib.makeBinPath [cfg.package cfg.quickshell.package pinentry-dms pkgs.gnugrep pkgs.gnused]}

    if ! dms ipc list 2>/dev/null | grep -qE '^[[:space:]]+dankPinentry[[:space:]]'; then
      exec ${options.modules.desktop.askpass.default} "$@"
    fi

    desc=''${1//%/%25}
    out=$(printf 'SETTITLE sudo\nSETDESC %s\nSETPROMPT Password:\nGETPIN\nBYE\n' "$desc" | pinentry-dms)
    pin=$(printf '%s\n' "$out" | sed -n 's/^D //p')
    [ -n "$pin" ] || exit 1
    printf '%s\n' "''${pin//%25/%}"
  '';
in {
  imports = [
    inputs.dms.nixosModules.dank-material-shell
  ];

  options.dms.autoEnable =
    lib.mkEnableOption "automatic DankMaterialShell enablement and home-manager module loading"
    // {
      default = true;
    };

  config = lib.mkMerge [
    (lib.mkIf config.dms.autoEnable {
      programs = {
        dank-material-shell = {
          enable = true;
          # Not the module default: that builds with the host pkgs, whose go_1_27 can lag core/go.mod.
          package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
          quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
        # clipShare's region capture goes through KMS, which needs this module's setcap wrapper.
        gpu-screen-recorder.enable = true;
      };
    })
    (lib.mkIf (options ? home-manager) {
      home-manager.sharedModules = [
        self.homeManagerModules.default
      ];
    })
    # Declared by the root repo's desktop preset; absent on any other consumer.
    (lib.optionalAttrs (options ? modules.desktop.askpass) {
      modules.desktop.askpass = lib.mkIf cfg.enable askpass;
    })
  ];
}
