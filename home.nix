{
  config,
  lib,
  pkgs,
  user,
  herdrPkgs ? pkgs,
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

  home.packages = (with pkgs; [
    bat
    delta
    fd
    fzf
    jq
    lazygit
    lsd
    neovim
    nodejs
    ripgrep
    starship
    terraform
    tree-sitter
    uv
    vivid
    yazi
  ]) ++ (with herdrPkgs; [
    herdr
  ]);

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
    # Written to ~/.config/git/ignore, which Git reads in every repository.
    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];
    settings = {
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      include.path = [
        "~/.config/delta/themes/cyberdream.gitconfig"
        "~/.dotfiles/home/.config/git/personal.gitconfig"
      ];
      includeIf."gitdir:~/projects/".path = "~/.dotfiles/.machine/gitconfig";
      delta = {
        features = "cyberdream";
        "line-numbers" = true;
        navigate = true;
      };
      merge.conflictstyle = "zdiff3";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "github-wikifarmer" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_wikifarmer";
        IdentitiesOnly = true;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_personal";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };
      "github.com-kalligas" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_personal";
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };
      "github.com-ath26" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_personal";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#b4bfd6";
    };
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ./home/.zshrc;
  };

  home.activation.removeExistingZshrc =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -rf -- "${config.home.homeDirectory}/.zshrc"
    '';

  home.file.".config/wezterm" = forceLink ".config/wezterm";
  home.file.".config/nvim" = forceLink ".config/nvim";
  home.file.".config/herdr" = forceLink ".config/herdr";
  home.file.".config/starship.toml" = forceLink ".config/starship.toml";
  home.file.".config/bat" = forceLink ".config/bat";
  home.file.".config/delta" = forceLink ".config/delta";
  home.file.".config/lazygit" = forceLink ".config/lazygit";
  home.file.".config/lsd" = forceLink ".config/lsd";
  home.file.".config/vivid" = forceLink ".config/vivid";
  home.file.".config/yazi" = forceLink ".config/yazi";
  home.file.".config/treehouse" = forceLink ".config/treehouse";
  home.file.".local/bin/kb".source = link ".local/bin/kb";
  home.file.".local/bin/tokcost".source = link ".local/bin/tokcost";
  home.file."Library/Services/Minimize All Windows.workflow" =
    forceLink "Library/Services/Minimize All Windows.workflow";

  home.activation.minimizeAllWindowsShortcut =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      /usr/bin/defaults write -g NSUserKeyEquivalents -dict-add \
        Minimize '"^~@m"' '"Minimize All Windows"' '"@m"'
      /usr/bin/defaults write pbs NSServicesStatus -dict-add \
        '"(null) - Minimize All Windows - runWorkflowAsService"' \
        '{key_equivalent = "@m"; enabled_context_menu = 1; enabled_services_menu = 1;}'
      /System/Library/CoreServices/pbs -update
    '';
}
