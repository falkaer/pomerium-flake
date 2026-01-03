{
  description = "Pomerium - Identity-aware access proxy (prebuilt binaries)";
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
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "v0.31.3";

        x86_64-linux = pkgs.fetchurl {
          url = "https://github.com/pomerium/pomerium/releases/download/${version}/pomerium-linux-amd64.tar.gz";
          hash = "sha256-qXRWaTl/2y5aTbWMCNxRGstgfSaXR9BPvGmVv2tZWD8=";
        };

        aarch64-linux = pkgs.fetchurl {
          url = "https://github.com/pomerium/pomerium/releases/download/${version}/pomerium-linux-arm64.tar.gz";
          hash = "sha256-LT823iz3J2AK+4to6scn+1yLqyXB7oPJy7xUD5RXNAo=";
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
            mkdir -p $out/bin
            # The tarball typically contains a single 'pomerium' binary.
            # Using a wildcard to be robust to directory names.
            cp */pomerium $out/bin/
            chmod +x $out/bin/pomerium
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
            maintainers = [ ];
          };
        };

        packages.default = self.packages.${system}.pomerium;

        apps.pomerium = flake-utils.lib.mkApp {
          drv = self.packages.${system}.pomerium;
        };
        apps.default = self.apps.${system}.pomerium;
      }
    );
}
