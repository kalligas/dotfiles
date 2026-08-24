#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "bootstrap.sh is for macOS. Use wsl/setup-wsl.sh inside WSL."
  exit 1
fi

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm

  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
ln -sfn "$DIR" "$HOME/.dotfiles"

echo "==> Step 3: configure the machine-local username"
REAL_USER="$(whoami)"
MACHINE_USER_FILE="$DIR/.machine/user"
mkdir -p "$(dirname "$MACHINE_USER_FILE")"
if [[ ! -f "$MACHINE_USER_FILE" ]]; then
  printf '%s\n' "$REAL_USER" > "$MACHINE_USER_FILE"
fi
DOTFILES_USER="$(head -n1 "$MACHINE_USER_FILE")"
if [[ "$DOTFILES_USER" != "$REAL_USER" ]]; then
  echo "    $MACHINE_USER_FILE contains \"$DOTFILES_USER\", but you are \"$REAL_USER\"."
  echo "    Update that gitignored file before continuing."
  exit 1
fi
export DOTFILES_USER
echo "    Using gitignored machine user \"$DOTFILES_USER\"."

echo "==> Step 4: Treehouse"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
if command -v treehouse >/dev/null 2>&1; then
  echo "    treehouse already installed, skipping"
else
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

echo "==> Step 5: first darwin-rebuild switch"
NIX_BIN="$(command -v nix)"
sudo env DOTFILES_USER="$DOTFILES_USER" "$NIX_BIN" \
  run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake "$HOME/.dotfiles#mac" --impure

echo "==> Done. Use ./rebuild.sh for future changes."
