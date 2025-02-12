{

  description = "My first flake!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

  };
  
  outputs = {self, nixpkgs, home-manager, agenix, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}; 
    in {
    nixosConfigurations = {
      raddservernix = lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [ 
          ./configuration.nix agenix.nixosModules.default
        ];
      };
    };
    homeConfigurations = {
      callumleach = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
  };

}
