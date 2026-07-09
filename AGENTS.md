# Project notes for agents

Deliberate decisions in this repo:

- `homebrew.onActivation.cleanup = "zap"` is intentional. Keep Homebrew declarative and list anything that should survive a rebuild.
- Do not add Git `user.name`, `user.email`, tokens, SSH keys, API keys, or machine-local secrets to this repo.
- Files under `home/` are intended to be live config sources through Home Manager symlinks on macOS and repo symlinks on WSL.
- Keep the Cyberdream blurred/translucent visual style consistent across WezTerm, Neovim, Herdr, Starship, and CLI tools.
