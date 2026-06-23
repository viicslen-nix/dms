{
  lib,
  config,
  options,
  pkgs,
  inputs,
  self,
  ...
}: {
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
      programs.dank-material-shell = {
        enable = true;
        quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    })
    (lib.mkIf (options ? home-manager) {
      home-manager.sharedModules = [
        self.homeManagerModules.default
      ];
    })
  ];
}
