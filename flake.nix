{
  description = "Nix packages for prebuilt binary releases, maintained with Nushell";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      overlay = final: prev: {
        obsidian = final.callPackage ./obsidian.nix { };
        zed = final.callPackage ./zed.nix { };
      } // prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "x86_64-linux") {
        codex = final.callPackage ./codex.nix { };
      };
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };
      in {
        packages = {
          default = if system == "x86_64-linux" then pkgs.codex else pkgs.obsidian;
          obsidian = pkgs.obsidian;
          zed = pkgs.zed;
        } // pkgs.lib.optionalAttrs (system == "x86_64-linux") { codex = pkgs.codex; };

        apps = {
          default = if system == "x86_64-linux" then
            { type = "app"; program = "${pkgs.codex}/bin/codex"; }
          else
            { type = "app"; program = "${pkgs.obsidian}/bin/obsidian"; };
          obsidian = { type = "app"; program = "${pkgs.obsidian}/bin/obsidian"; };
          zed = { type = "app"; program = "${pkgs.zed}/bin/zed"; };
        } // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          codex = { type = "app"; program = "${pkgs.codex}/bin/codex"; };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nixpkgs-fmt nix-prefetch-git jq nushell zstd ];
        };
      }) // { overlays.default = overlay; };
}
