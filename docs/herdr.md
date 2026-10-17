# Herdr Cheatsheet

Prefix means: press `Ctrl-s`, release, then press the next key.

## Start

```sh
herdr          # start or reattach
h             # alias for herdr
```

Herdr keeps panes running when you detach, close the terminal, or reconnect later.

## Help

```text
Prefix ?       show every active Herdr binding
```

## Daily Keys

```text
Prefix c       new tab
Prefix v       split right
Prefix -       split down
Prefix h/j/k/l move between panes
Prefix w       workspace navigation
Prefix q       detach
```

## Panes

```text
Prefix z       zoom/unzoom focused pane
Prefix x       close focused pane
Prefix r       resize mode
Prefix [       copy mode
```

## Tabs

```text
Prefix n       next tab
Prefix p       previous tab
Prefix 1..9    jump to tab
Prefix Shift-t rename tab
Prefix Shift-x close tab
```

## Workspaces

```text
Prefix Shift-n new workspace
Prefix Shift-w rename workspace
Prefix Shift-d close workspace
Prefix b       toggle sidebar
Prefix g       goto picker
```

## Copy Mode

```text
Prefix [       enter copy mode
h/j/k/l        move
v or Space     start selection
y or Enter     copy selection
q or Esc       leave copy mode
```

Mouse selection, pane focus, pane resizing, and sidebar navigation are first-class in Herdr too.

## Pane Appearance

Herdr uses borderless panes with a blank gap between panes. Each borderless pane
reserves two columns on each side and one row above and below the terminal
content. Panes smaller than eight columns or four rows omit the padding.
Padding stays the same when focus moves between panes.

The custom Herdr package shades the focused pane's default background gray
(`#24272b`) when a tab contains multiple panes. Filled corner glyphs round the
shaded area inside the padding. Application backgrounds and selection colors
keep their own colors. A tab with one pane keeps the terminal's transparent
background.

WezTerm loads the four corner glyphs from
`home/.config/wezterm/fonts/HerdrPaneCorners.ttf`. The small font contains
original outlines with JetBrains Mono's cell metrics. Regenerate or verify the
font with:

```sh
uv run home/.config/wezterm/fonts/generate_corners.py
uv run home/.config/wezterm/fonts/generate_corners.py --check
```

The Nix package applies `patches/herdr-focused-pane-background.patch` to Herdr
0.8.2. The package build checks padding, rounded corners, stable terminal sizes
across focus changes, application colors, single-pane transparency, and terminal
output updates. The version check in `nix/herdr.nix` requires rebasing the patch
before a Herdr upgrade.

Build and test the custom package:

```sh
nix build .#herdr --out-link .machine/herdr-focus-result
```

Run `./rebuild.sh` to install the custom package through Home Manager.
