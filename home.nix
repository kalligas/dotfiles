{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/${path}";
  forceLink = path: {
    source = link path;
    force = true;
  };
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    bat
    delta
    fd
    fzf
    jq
    lazygit
    lsd
    neovim
    ripgrep
    starship
    tmux
    tree-sitter
    vivid
    yazi
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BAT_THEME = "cyberdream";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      include.path = "~/.config/delta/themes/cyberdream.gitconfig";
      delta = {
        features = "cyberdream";
        "line-numbers" = true;
        navigate = true;
      };
      merge.conflictstyle = "zdiff3";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ./home/.zshrc;
  };

  home.activation.removeExistingZshrc =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -rf -- "${config.home.homeDirectory}/.zshrc"
    '';

  home.file.".config/wezterm" = forceLink ".config/wezterm";
  home.file.".config/nvim" = forceLink ".config/nvim";
  home.file.".config/tmux" = forceLink ".config/tmux";
  home.file.".config/starship.toml" = forceLink ".config/starship.toml";
  home.file.".config/bat" = forceLink ".config/bat";
  home.file.".config/delta" = forceLink ".config/delta";
  home.file.".config/lazygit" = forceLink ".config/lazygit";
  home.file.".config/lsd" = forceLink ".config/lsd";
  home.file.".config/vivid" = forceLink ".config/vivid";
  home.file.".config/yazi" = forceLink ".config/yazi";
  home.file.".config/treehouse" = forceLink ".config/treehouse";
}
