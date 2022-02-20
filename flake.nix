{
  description = "scripts for metadir";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { ${system} = ret.${key}; };
                in attrs // {
                  ${key} = (attrs.${key} or { })
                    // (appendSystem key system ret);
                };
            in builtins.foldl' op attrs (builtins.attrNames ret);
        in builtins.foldl' op { } systems;
      defaultSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in eachSystem defaultSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        beams = pkgs.stdenv.mkDerivation {
          name = "beams";
          src = ./.;
          propagatedBuildInputs = [
            pkgs.coreutils
            pkgs.file
            pkgs.gawk
            pkgs.jq
            pkgs.moreutils
            pkgs.parallel
            pkgs.ripgrep
          ];
          buildPhase = ''
            mkdir scripts tests
            ${pkgs.emacs}/bin/emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "beams.org")'
          '';
          installPhase = ''
            mkdir -p $out/bin/
            cp scripts/* $out/bin/
            chmod +x $out/bin/*
          '';
        };
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.bash_unit
            pkgs.coreutils
            pkgs.file
            pkgs.gawk
            pkgs.jq
            pkgs.moreutils
            pkgs.parallel
            pkgs.ripgrep
          ];
        };
        packages = { inherit beams; };
        defaultPackage = beams;
      });
}
