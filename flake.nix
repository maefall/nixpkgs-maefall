{
  description = "maefall's custom packages and home-manager modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        pkgs.lib.filesystem.packagesFromDirectoryRecursive {
          callPackage = pkgs.callPackage;
          directory = ./packages;
        }
      );

      homeManagerModules =
        let
          dir = ./modules/home-manager;
          names = builtins.attrNames (builtins.readDir dir);
          toAttr = f: {
            name  = nixpkgs.lib.removeSuffix ".nix" f;
            value = import (dir + "/${f}");
          };
        in builtins.listToAttrs (map toAttr names);

      nixosModules =
        let
          dir = ./modules/nixos;
          names = builtins.attrNames (builtins.readDir dir);
          toAttr = f: {
            name  = nixpkgs.lib.removeSuffix ".nix" f;
            value = import (dir + "/${f}");
          };
        in builtins.listToAttrs (map toAttr names);
    };
}
