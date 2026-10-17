{ herdr, lib }:

assert lib.assertMsg (herdr.version == "0.8.2")
  "Rebase the Herdr customization patches before upgrading Herdr.";

herdr.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ../patches/herdr-focused-pane-background.patch
    ../patches/herdr-agent-context.patch
    ../patches/herdr-rounded-tabs.patch
    ../patches/herdr-rounded-sidebar.patch
    ../patches/herdr-tab-bar-gap.patch
    ../patches/herdr-translucent-surfaces.patch
  ];
  doCheck = true;
  cargoTestFlags = [ "--bin" "herdr" "dotfiles_" ];
})
