{
  description = "hass-light-eww";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        runtimeDependencies = [ ];
        buildDependencies = with pkgs; [
          openssl
        ];
        rpath = with pkgs; lib.makeLibraryPath runtimeDependencies;
      in
      rec {
        packages = {
          default = pkgs.rustPlatform.buildRustPackage {
            version = "0.1.0";
            pname = "hass-light-eww";
            cargoLock.lockFile = ./Cargo.lock;
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            buildInputs = buildDependencies;
            postFixup = ''
              patchelf $out/bin/hass-light-eww --add-rpath "${rpath}"
            '';
            src = pkgs.lib.cleanSourceWith {
              filter =
                name: type:
                let
                  baseName = baseNameOf (toString name);
                in
                !(builtins.elem baseName [
                  "flake.nix"
                  "flake.lock"
                ]);
              src = pkgs.lib.cleanSource ./.;
              name = "hass-light-src";
            };
          };
          docker = pkgs.dockerTools.buildLayeredImage {
            name = "hass-light-eww";
            tag = "latest";
            config = {
              Env = [
                "PATH=/bin:${packages.default}/bin"
              ];
              Entrypoint = [ "${packages.default}/bin/hass-light-eww" ];
            };
          };
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              with pkgs;
              [
                cargo
                pkg-config
              ]
              ++ buildDependencies;
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildDependencies;
          };
          try = pkgs.mkShell {
            buildInputs = [
              packages.default
            ];
          };
        };
      }
    );
}
