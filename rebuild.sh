#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"

MACHINE_USER_FILE="$DIR/.machine/user"
if [[ ! -f "$MACHINE_USER_FILE" ]]; then
  echo "Missing $MACHINE_USER_FILE. Run ./bootstrap.sh first." >&2
  exit 1
fi
DOTFILES_USER="$(head -n1 "$MACHINE_USER_FILE")"
if [[ -z "$DOTFILES_USER" ]]; then
  echo "$MACHINE_USER_FILE must contain the local macOS username." >&2
  exit 1
fi
export DOTFILES_USER

if DARWIN_REBUILD="$(command -v darwin-rebuild 2>/dev/null)"; then
  exec sudo env DOTFILES_USER="$DOTFILES_USER" "$DARWIN_REBUILD" \
    switch --flake "$HOME/.dotfiles#mac" --impure
fi

if NIX="$(command -v nix 2>/dev/null)"; then
  exec sudo env DOTFILES_USER="$DOTFILES_USER" "$NIX" \
    run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$HOME/.dotfiles#mac" --impure
fi

echo "Could not find darwin-rebuild or nix in PATH." >&2
exit 1
