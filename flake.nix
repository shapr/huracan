{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, unstable, ... }@inputs: {
    nixosConfigurations.huracan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit unstable; };
      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        (import ./configuration.nix inputs)
        {nixpkgs.overlays = [ ];
        }

      ];
    };
  };
}
