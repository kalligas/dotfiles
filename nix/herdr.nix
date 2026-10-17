{ herdr, lib }:

assert lib.assertMsg (herdr.version == "0.8.2")
  "Rebase the focused-pane background patch before upgrading Herdr.";

herdr.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ../patches/herdr-focused-pane-background.patch ];
  doCheck = true;
  cargoTestFlags = [ "--bin" "herdr" "focused_pane_background" ];
})
