# dotfiles

Personal Cyberdream dev setup managed with nix-darwin, Home Manager, and a small WSL transfer path.

## What You Get

- macOS defaults: dark mode, fast key repeat, clean Finder/Dock defaults, tap-to-click.
- Homebrew casks: WezTerm and Nerd Font fallbacks.
- Nix user packages: Neovim, Starship, Codex, Claude Code, Herdr, ripgrep, fd, fzf, jq, lazygit, yazi, lsd, vivid, bat, delta, and tree-sitter.
- Terminal/editor style: Cyberdream dark palette, blurred/translucent WezTerm, transparent Neovim, glass-friendly Herdr.
- CLI theming: Cyberdream Starship, Bat, Delta, LazyGit, Yazi, LSD, and Vivid.
- Workflow helpers: Treehouse aliases/functions and Herdr aliases.
- Herdr help: `h` starts or reattaches, `Ctrl-b ?` shows all bindings, and `docs/herdr.md` has a short cheatsheet.

## Terminal Stack

| Category | Tool | Purpose |
| --- | --- | --- |
| Shell | Zsh | Interactive command-line shell. |
| Shell plugins | Zsh Autosuggestions, Zsh Syntax Highlighting | Suggest commands from history and highlight shell syntax. |
| Prompt | Starship | Show the current directory, Git state, language versions, and command duration. |
| Terminal emulator | WezTerm | Provide terminal windows, panes, fonts, transparency, and keyboard shortcuts. |
| Workspace and session manager | Herdr | Manage terminal sessions and coding agents. |
| Git worktree manager | Treehouse | Create, lease, and return isolated Git worktrees. |
| Editor | Neovim | Edit code in the terminal. |
| Editor plugin manager | lazy.nvim | Install and update Neovim plugins. |
| Theme | Cyberdream | Keep a consistent color palette across the terminal, editor, and CLI tools. |
| Package and configuration managers | Nix, nix-darwin, Home Manager, Homebrew | Install tools and configure macOS declaratively. |
| Coding agents | Codex, Claude Code | Provide AI-assisted development workflows. |
| CLI utilities | Bat, Delta, fd, fzf, jq, LazyGit, LSD, ripgrep, Tree-sitter, Vivid, Yazi | Improve file viewing, search, Git, JSON processing, syntax parsing, colors, and navigation. |

## Shortcut Reference

The shortcuts have three layers:

| Prefix | Owner | Use it for |
| --- | --- | --- |
| `Ctrl-b` | Herdr | Terminal panes, tabs, workspaces, resizing, and session control. |
| `Space` | Neovim leader | Files, search, Git, plugins, saving, and editor actions. |
| `Ctrl-w` | Neovim | Moving between windows inside Neovim, such as the editor and file tree. |

For a sequence such as `Ctrl-b v`, press `Ctrl-b`, release it, and then press `v`. Before using Neovim shortcuts, press `Esc` to return to Normal mode.

### Herdr: `Ctrl-b`

| Shortcut | Action |
| --- | --- |
| `Ctrl-b ?` | Show every active Herdr binding. |
| `Ctrl-b v` | Split the focused pane to the right. |
| `Ctrl-b -` | Split the focused pane downward. |
| `Ctrl-b h/j/k/l` | Focus the pane left/down/up/right. |
| `Ctrl-b z` | Zoom or unzoom the focused pane. |
| `Ctrl-b r` | Enter pane resize mode; use `h/j/k/l`, then `Esc`. |
| `Ctrl-b x` | Close the focused pane. |
| `Ctrl-b c` | Create a tab. |
| `Ctrl-b n/p` | Go to the next/previous tab. |
| `Ctrl-b 1..9` | Jump to a numbered tab. |
| `Ctrl-b w` | Open workspace navigation. |
| `Ctrl-b b` | Toggle the sidebar. |
| `Ctrl-b [` | Enter copy mode. |
| `Ctrl-b q` | Detach while leaving panes running. |

### Neovim leader: `Space`

| Shortcut | Action |
| --- | --- |
| `Space e` | Toggle the file explorer. |
| `Space w` | Save the current file. |
| `Space q` | Close the current Neovim window. |
| `Space f f` | Find files. |
| `Space f g` | Search text across the project. |
| `Space f b` | Find an open buffer. |
| `Space f h` | Search Neovim help. |
| `Space g s` | List Git-changed files. |
| `Space g g` | Open LazyGit. |
| `Space s r` | Open project-wide search and replace. |
| `Space r` | Apply replacements inside Grug Far. |
| `Space l` | Open the lazy.nvim plugin manager. |

Pressing `Space` and waiting briefly opens Which Key with the available leader shortcuts.

### Neovim windows: `Ctrl-w`

| Shortcut | Action |
| --- | --- |
| `Ctrl-w h/j/k/l` | Focus the Neovim window left/down/up/right. |
| `Ctrl-w w` | Cycle through Neovim windows. |
| `Ctrl-w =` | Make Neovim windows equal in size. |
| `Ctrl-w q` | Close the focused Neovim window. |

`Ctrl-b h` crosses into another Herdr pane; `Ctrl-w h` moves to another window inside the current Neovim pane.

### Common Neovim and file-tree keys

| Context | Keys |
| --- | --- |
| Editing | `i` enters Insert mode; `Esc` returns to Normal mode and saves; `u` undoes; `Ctrl-r` redoes. |
| Movement | `h/j/k/l`, `w`, `b`, `0`, `$`, `gg`, and `G`. |
| Current-file search | `/text` searches; `n`/`N` move to the next/previous match; `Esc` clears highlighting. |
| File explorer | `j/k` move, `Enter` opens, `h/l` collapse/expand, `a` creates, `r` renames, `d` deletes, and `g?` opens help. |
| Shell suggestion | `Right Arrow` or `Ctrl-f` accepts progressively; `End` or `Fn-Right Arrow` accepts the full suggestion. |

## Fresh macOS Setup

Clone this repo, review the files, then run:

```sh
./bootstrap.sh
```

`bootstrap.sh` installs Determinate Nix if needed, symlinks this repo to `~/.dotfiles`, records your macOS username in the gitignored `.machine/user` file, installs Treehouse into `~/.local/bin` if missing, and runs the first nix-darwin switch.

After the first setup, edit files in this repo and apply changes with:

```sh
./rebuild.sh
```

## Validate Without Applying

Once Nix is installed, load the machine-local username and use impure evaluation:

```sh
export DOTFILES_USER="$(cat .machine/user)"
nix flake check --no-build --impure
nix build .#darwinConfigurations.mac.system --dry-run --impure
```

## Make It Yours

- `flake.nix` keeps `michaliskalligas` as its portable fallback. Each Mac overrides it through the gitignored `.machine/user` file created by `bootstrap.sh`.
- Host label is `mac`; keep `flake.nix`, `bootstrap.sh`, and `rebuild.sh` in sync if you rename it.
- CPU target is Apple Silicon: `aarch64-darwin`.
- Git defaults to `kalligas <mkalligas1997@gmail.com>`. Override it per machine in the gitignored `.machine/gitconfig`:

```gitconfig
[user]
  name = Your Name
  email = you@example.com
```

## Homebrew Cleanup Warning

`configuration.nix` uses:

```nix
homebrew.onActivation.cleanup = "zap";
```

Anything installed through Homebrew but not listed in `configuration.nix` can be removed during a rebuild. CLI/dev tools are intentionally managed by Nix through `home.nix`; use Homebrew only for GUI apps, fonts, and macOS-native casks that are listed in `configuration.nix`.

Home Manager links are forced. If a managed file or directory already exists, the repo-managed version replaces it during activation instead of creating another backup. The WSL setup script uses the same overwrite-first behavior for managed symlinks.

## WSL Setup

On Windows, first install WSL:

```powershell
wsl --install -d Ubuntu
```

Then from PowerShell inside this repo:

```powershell
.\windows\setup-windows.ps1
```

Inside Ubuntu/WSL, clone or copy this repo and run:

```sh
bash wsl/setup-wsl.sh
```

The WSL script installs Linuxbrew if needed, installs the CLI toolchain, symlinks this repo to `~/.dotfiles`, links the shared configs, configures Git/Delta without setting your identity, builds the Bat cache, syncs Neovim plugins, and tries to switch your shell to zsh.

## Repo Tour

- `flake.nix`: nix-darwin, Home Manager, and nix-homebrew wiring.
- `configuration.nix`: macOS defaults and Homebrew casks.
- `home.nix`: user packages, zsh, Git/Delta behavior, and config symlinks.
- `home/`: live app config files.
- `bootstrap.sh`: first macOS setup.
- `rebuild.sh`: daily macOS apply command.
- `wsl/` and `windows/`: Windows/WSL transfer helpers.
