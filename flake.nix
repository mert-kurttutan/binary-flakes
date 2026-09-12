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
        codex = final.callPackage ./codex.nix { runtime = "native"; };
        codex-node = final.callPackage ./codex.nix { runtime = "node"; };
        obsidian = final.callPackage ./obsidian.nix { };
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
          default = pkgs.codex;
          codex = pkgs.codex;
          codex-node = pkgs.codex-node;
          obsidian = pkgs.obsidian;
        };

        apps = {
          default = { type = "app"; program = "${pkgs.codex}/bin/codex"; };
          codex = { type = "app"; program = "${pkgs.codex}/bin/codex"; };
          codex-node = { type = "app"; program = "${pkgs.codex-node}/bin/codex-node"; };
          obsidian = { type = "app"; program = "${pkgs.obsidian}/bin/obsidian"; };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nixpkgs-fmt nix-prefetch-git jq nushell zstd ];
        };
      }) // { overlays.default = overlay; };
}
