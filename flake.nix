{
  description = "Nomadix: run nomad in NixOS VM";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    system = import (pkgs.path + /nixos) {
      system = "x86_64-linux";
      configuration = import ./configuration.nix;
    };
  in {
    defaultPackage.x86_64-linux = system.vm // { meta.mainProgram = "run-nixos-vm"; };
  };
}
