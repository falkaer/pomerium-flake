#!/usr/bin/env bash
set -euo pipefail

# Get latest version from GitHub
echo "Fetching latest version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/pomerium/pomerium/releases/latest | jq -r .tag_name)
CURRENT_VERSION=$(nix eval --raw .#pomerium.version 2> /dev/null || echo "unknown")

echo "Current version: $CURRENT_VERSION"
echo "Latest version: $LATEST_VERSION"

if [[ $CURRENT_VERSION == "$LATEST_VERSION"   ]]; then
    echo "Already up to date"
    exit 0
fi

# Update version in flake.nix
echo "Updating version to $LATEST_VERSION..."
sed -i "s/version = \".*\";/version = \"$LATEST_VERSION\";/" flake.nix

# Fetch and update hash for each platform
declare -A PLATFORMS=(
      ["x86_64-linux"]="pomerium-linux-amd64.tar.gz"
      ["aarch64-linux"]="pomerium-linux-arm64.tar.gz"
)

for PLATFORM in "${!PLATFORMS[@]}"; do
    ARTIFACT="${PLATFORMS[$PLATFORM]}"
    URL="https://github.com/pomerium/pomerium/releases/download/$LATEST_VERSION/$ARTIFACT"

    echo "Fetching hash for $PLATFORM..."
    HASH=$(nix-prefetch-url "$URL" 2> /dev/null)
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

    # Find and replace the hash for this platform
    sed -i "/$PLATFORM = pkgs.fetchurl/,/hash = \"sha256-/s|hash = \"sha256-[^\"]*\";|hash = \"$SRI_HASH\";|" flake.nix

    echo "  $PLATFORM: $SRI_HASH"
done

echo "Update complete"
