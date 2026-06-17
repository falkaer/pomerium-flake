{
  description = "Pomerium prebuilt binaries + NixOS module using the flake package";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "v0.32.9";
        x86_64-linux = pkgs.fetchurl {
          url = "https://github.com/pomerium/pomerium/releases/download/${version}/pomerium-linux-amd64.tar.gz";
          hash = "sha256-oB5EGjX0vQA76J5ahhuamIegXFatDJFKZFbVysVLCRA=";
        };
        aarch64-linux = pkgs.fetchurl {
          url = "https://github.com/pomerium/pomerium/releases/download/${version}/pomerium-linux-arm64.tar.gz";
          hash = "sha256-j9t8JPZJ0cFuXfV6qIYD5+Tx1esceWFjxgnxColQHr0=";
        };
      in
      {
        packages.pomerium = pkgs.stdenv.mkDerivation {
          pname = "pomerium";
          inherit version;
          src = { inherit x86_64-linux aarch64-linux; }.${system};
          sourceRoot = ".";
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib ];
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin"
            cp ./pomerium "$out/bin/pomerium"
            chmod +x "$out/bin/pomerium"
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "Pomerium - Identity-aware access proxy";
            homepage = "https://github.com/pomerium/pomerium";
            license = licenses.asl20;
            mainProgram = "pomerium";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
            ];
          };
        };
        packages.default = self.packages.${system}.pomerium;
        apps.pomerium = flake-utils.lib.mkApp { drv = self.packages.${system}.pomerium; };
        apps.default = self.apps.${system}.pomerium;
      }
    )
    // {
      nixosModules.pomerium = import ./pomerium.nix self;
    };
}
