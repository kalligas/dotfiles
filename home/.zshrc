if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

export EDITOR="nvim"
export VISUAL="nvim"
export BAT_THEME="cyberdream"

if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate cyberdream)"
fi

alias ls="lsd"
alias ll="lsd -lah"
alias la="lsd -a"
alias lt="lsd --tree"

alias t="tmux"
alias tls="tmux ls"
alias tn="tmux new -s"
alias ta="tmux attach -t"

alias th="treehouse"
alias thsh="treehouse"
alias ths="treehouse status"
alias thp="treehouse prune"
alias thpa="treehouse prune --all"

export TREEHOUSE_LEASE_HOLDER="${TREEHOUSE_LEASE_HOLDER:-${USER:-user}@${HOST%%.*}}"

thcd() {
  local holder="${1:-$TREEHOUSE_LEASE_HOLDER}"
  local path

  path="$(treehouse get --lease --lease-holder "$holder")" || return
  cd "$path" || return

  print "Leased Treehouse worktree: $path"
  print "Run 'thr' from this worktree when you are done."
}

thr() {
  treehouse return "${1:-$PWD}"
}

thnvim() {
  thcd "${1:-nvim:${PWD:t}}" || return
  nvim .
}

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
