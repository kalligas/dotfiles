# dotfiles

Personal Cyberdream dev setup managed with nix-darwin, Home Manager, and a small WSL transfer path.

## What You Get

- macOS defaults: dark mode, fast key repeat, clean Finder/Dock defaults, tap-to-click.
- Homebrew casks: WezTerm and Nerd Font fallbacks.
- Nix user packages: Neovim, Starship, tmux, ripgrep, fd, fzf, jq, lazygit, yazi, lsd, vivid, bat, delta, and tree-sitter.
- Terminal/editor style: Cyberdream dark palette, blurred/translucent WezTerm, transparent Neovim, glass-friendly tmux.
- CLI theming: Cyberdream Starship, Bat, Delta, LazyGit, Yazi, LSD, and Vivid.
- Workflow helpers: Treehouse aliases/functions and tmux aliases.
- tmux help: `Ctrl-b /` opens `docs/tmux.md` in a popup; `Ctrl-b ?` shows all bindings.

## Fresh macOS Setup

Clone this repo, review the files, then run:

```sh
./bootstrap.sh
```

`bootstrap.sh` installs Determinate Nix if needed, symlinks this repo to `~/.dotfiles`, checks that `flake.nix` matches your macOS username, installs Treehouse into `~/.local/bin` if missing, and runs the first nix-darwin switch.

After the first setup, edit files in this repo and apply changes with:

```sh
./rebuild.sh
```

## Validate Without Applying

Once Nix is installed:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

## Make It Yours

- Username is set once in `flake.nix` as `michaliskalligas`; `bootstrap.sh` can offer to rewrite it.
- Host label is `mac`; keep `flake.nix`, `bootstrap.sh`, and `rebuild.sh` in sync if you rename it.
- CPU target is Apple Silicon: `aarch64-darwin`.
- Git identity is intentionally not managed. Set it per machine:

```sh
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

## Homebrew Cleanup Warning

`configuration.nix` uses:

```nix
homebrew.onActivation.cleanup = "zap";
```

Anything installed through Homebrew but not listed in `configuration.nix` can be removed during a rebuild. CLI/dev tools are intentionally managed by Nix through `home.nix`; use Homebrew only for GUI apps, fonts, and macOS-native casks that are listed in `configuration.nix`.

Home Manager links are forced. If a managed file or directory already exists, the repo-managed version replaces it during activation instead of creating another backup.

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
