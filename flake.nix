{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          rec {
            default = cardano-signer;
            cardano-signer = pkgs.buildNpmPackage rec {
              pname = "cardano-signer";
              version = "0.0.0";
              src = ./src;
              dontNpmBuild = true;
              npmDepsHash = "sha256-Y2RBTnIgnF3JgyyuSLSZZP09rpckHTkI/xLqXKj7+iQ=";
              NODE_OPTIONS = "--openssl-legacy-provider";
            };
          });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  packages = [ self.packages.${system}.cardano-signer ];
                  languages.nix.enable = true;
                  languages.javascript.enable = true;
                  pre-commit.hooks = {
                    nixpkgs-fmt.enable = true;
                  };
                }
              ];
            };
          });
    };
}
