{
  description = "DankMaterialShell, its plugins and greeter, wired for NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The greeter moved out of DankMaterialShell into its own repo.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];

    treefmtEval =
      forAllSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix);

    hmModule = {
      config,
      lib,
      pkgs,
      options,
      # Absent on a standalone home-manager eval; hm.nix reads the shell selection from it.
      osConfig ? {},
      ...
    }:
      import ./hm.nix {
        inherit config lib pkgs options inputs osConfig;
      };

    nixosModule = {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
      import ./nixos.nix {
        inherit config lib options pkgs inputs self;
      };
  in {
    homeManagerModules = {
      default = hmModule;
      dms = hmModule;
    };

    nixosModules = {
      default = nixosModule;
      dms = nixosModule;
      greeter = inputs.dank-greeter.nixosModules.default;
    };

    formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

    checks = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      treefmt = treefmtEval.${system}.config.build.check self;
      # statix fix (what treefmt runs) skips lints it cannot fix, such as repeated keys.
      statix = pkgs.runCommandLocal "statix-check" {} ''
        ${pkgs.lib.getExe pkgs.statix} check ${./.} && touch $out
      '';
    });
  };
}
