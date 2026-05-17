{
  description = "Debian 13 system configuration via system-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, system-manager, ... }: {
    overlays.default = final: prev: {
      panel-1panel = import ./pkgs/1panel {
        inherit (prev) stdenv fetchurl lib;
      };
    };

    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        {
          nixpkgs.overlays = [ self.overlays.default ];
        }
        ./config/system.nix
      ];
    };
  };
}
