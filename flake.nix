{
  description = "Niri desktop environment configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.niri-unstable.url = "github:niri-wm/niri/5393902dd22e9d540438ee178775f1e488eea724";
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
