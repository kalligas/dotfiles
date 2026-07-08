#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "setup-wsl.sh is for Linux/WSL."
  exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y build-essential ca-certificates curl file git procps zsh
fi

if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew update
brew install neovim starship bat git-delta lazygit yazi lsd vivid ripgrep fd tree-sitter tmux fzf jq zsh

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v treehouse >/dev/null 2>&1; then
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

ln -sfn "$repo_dir" "$HOME/.dotfiles"

link_home() {
  local source_path="$repo_dir/home/$1"
  local target_path="$HOME/$1"
  local target_dir

  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    mv "$target_path" "$target_path.backup-$(date +%Y%m%d-%H%M%S)"
  fi

  ln -sfn "$source_path" "$target_path"
}

link_home ".zshrc"
link_home ".config/nvim"
link_home ".config/tmux"
link_home ".config/starship.toml"
link_home ".config/bat"
link_home ".config/delta"
link_home ".config/lazygit"
link_home ".config/lsd"
link_home ".config/vivid"
link_home ".config/yazi"
link_home ".config/treehouse"

git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global include.path "~/.config/delta/themes/cyberdream.gitconfig"
git config --global delta.features cyberdream
git config --global delta.line-numbers true
git config --global delta.navigate true
git config --global merge.conflictstyle zdiff3

bat cache --build || true
nvim --headless "+Lazy! sync" +qa

if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
  chsh -s "$(command -v zsh)" || true
fi

echo "Cyberdream WSL setup complete. Restart Ubuntu/WSL, then open WezTerm."
