{
  config,
  pkgs,
  user,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/${path}";
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

  home.file.".config/wezterm".source = link ".config/wezterm";
  home.file.".config/nvim".source = link ".config/nvim";
  home.file.".config/tmux".source = link ".config/tmux";
  home.file.".config/starship.toml".source = link ".config/starship.toml";
  home.file.".config/bat".source = link ".config/bat";
  home.file.".config/delta".source = link ".config/delta";
  home.file.".config/lazygit".source = link ".config/lazygit";
  home.file.".config/lsd".source = link ".config/lsd";
  home.file.".config/vivid".source = link ".config/vivid";
  home.file.".config/yazi".source = link ".config/yazi";
  home.file.".config/treehouse".source = link ".config/treehouse";
}
