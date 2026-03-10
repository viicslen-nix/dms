{
  description = "Niri desktop environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    dms,
    dms-plugin-registry,
    ...
  }: {
    homeManagerModules = let
      module = {
        config,
        lib,
        pkgs,
        options,
        ...
      }:
        import ./hm.nix {
          inherit config lib pkgs options inputs;
        };
    in {
      default = module;
      dms = module;
    };
  };
}
