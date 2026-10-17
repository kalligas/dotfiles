{ herdr, lib }:

assert lib.assertMsg (herdr.version == "0.8.2")
  "Rebase the Herdr customization patches before upgrading Herdr.";

herdr.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ../patches/herdr-focused-pane-background.patch
    ../patches/herdr-agent-context.patch
  ];
  doCheck = true;
  cargoTestFlags = [ "--bin" "herdr" "dotfiles_" ];
})
