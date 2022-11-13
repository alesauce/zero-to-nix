{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    }:

    let
      overlays = [
        (self: super: {
          nodejs = super.nodejs-18_x;
          pnpm = super.nodePackages.pnpm;
        })
      ];
    in
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit overlays system; };

      common = with pkgs; [ nodejs pnpm python38 ];
      scripts = with pkgs; [
        (writeScriptBin "clean" ''
          rm -rf dist
        '')

        (writeScriptBin "setup" ''
          clean
          pnpm install
        '')

        (writeScriptBin "build" ''
          setup
          pnpm run build
        '')

        (writeScriptBin "dev" ''
          setup
          pnpm run dev
        '')

        (writeScriptBin "preview" ''
          build
          python3 -m http.server -d out 3000
        '')
      ];

      runLocal = pkgs.writeScriptBin "run-local" ''
        rm -rf .next out
        pnpm install
        pnpm run build
        python3 -m http.server -d out 3000
      '';
    in
    {
      devShells.default = pkgs.mkShell
        {
          buildInputs = common ++ scripts;
        };

      apps.default = flake-utils.lib.mkApp {
        drv = runLocal;
      };
    });
}
