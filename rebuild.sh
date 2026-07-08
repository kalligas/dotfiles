#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"

if DARWIN_REBUILD="$(command -v darwin-rebuild 2>/dev/null)"; then
  exec sudo "$DARWIN_REBUILD" switch --flake "$HOME/.dotfiles#mac"
fi

if NIX="$(command -v nix 2>/dev/null)"; then
  exec sudo "$NIX" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$HOME/.dotfiles#mac"
fi

echo "Could not find darwin-rebuild or nix in PATH." >&2
exit 1
