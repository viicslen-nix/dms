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
  }: let
    hmModule = {
      config,
      lib,
      pkgs,
      options,
      ...
    }:
      import ./hm.nix {
        inherit config lib pkgs options inputs;
      };

    nixosModule = {
      config,
      lib,
      options,
      ...
    }:
      import ./nixos.nix {
        inherit config lib options inputs self;
      };
  in {
    homeManagerModules = {
      default = hmModule;
      dms = hmModule;
    };

    nixosModules = {
      default = nixosModule;
      dms = nixosModule;
    };
  };
}
