{
  description = "scripts for metadir";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    gojq.url = "github:itchyny/gojq";
    gojq.flake = false;
  };

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
          buildInputs = [
            pkgs.ripgrep
            pkgs.coreutils
            pkgs.parallel
            pkgs.file
            pkgs.moreutils
          ];
          buildPhase = ''
            mkdir scripts
            ${pkgs.emacs}/bin/emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "beams.org")'
          '';
          installPhase = ''
            mkdir -p $out/bin/
            cp scripts/* $out/bin/
            chmod +x $out/bin/*
          '';
        };
        puma =
          pkgs.writeShellScriptBin "puma" (builtins.readFile "${beams}/puma");
        lookup = pkgs.writeShellScriptBin "lookup"
          (builtins.readFile "${beams}/lookup");
        gojq = pkgs.buildGoModule {
          src = inputs.gojq;
          name = "gojq";
          vendorSha256 = "sha256-1wN1nMpvkkrKISuI9tCxX8nL73TQr9snHS9A1UWCArQ=";
        };
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            beams
            pkgs.ripgrep
            pkgs.coreutils
            pkgs.parallel
            pkgs.file
            pkgs.moreutils
            gojq
          ];
        };
        packages = { inherit beams puma lookup; };
        defaultPackage = beams;
      });
}
