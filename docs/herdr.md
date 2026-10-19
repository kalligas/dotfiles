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

The custom Herdr package shades the focused pane's default background with a
translucent gray. Filled corner glyphs round the shaded area inside the
padding. Application backgrounds and selection colors keep their own colors.
A tab with one pane also shades that pane, so every tab shows the same focused
surface. The patch `patches/herdr-single-pane-background.patch` extends the
shading to single-pane tabs.

The translucent near-black is `rgba(0, 9, 17, 0.7)`, so WezTerm's blurred window
background shows through the focused pane. The WezTerm window background is
`#3d3d3d` at 0.70 opacity, lighter than the selected surfaces, so the focused
pane, selected tab, and active sidebar entry read darker than the rest of the
window. Terminal escape sequences carry no
alpha, so Herdr paints the surface with palette index 235, and
`home/.config/wezterm/wezterm.lua` maps index 235 to the translucent gray.
WezTerm also ignores alpha in ordinary glyph colors, so the corner glyphs carry
the same gray as a color-font layer. `SURFACE_RGBA` in
`home/.config/wezterm/fonts/generate_corners.py` must match the index 235
entry. FreeType premultiplies color-glyph pixels, and WezTerm blends them as
unpremultiplied, so the generator stores each channel divided by alpha. For
that reason no color channel may exceed the alpha: at alpha 0.25 (64 of 255),
each channel stays at or below 63. WezTerm also crops color-glyph bitmaps one
column and one row short and scales the glyph's top offset by the cropped
height. Each corner glyph therefore carries a throwaway pixel to the right of
the cell and far below the baseline: the crop removes that pixel instead of
the corner's edge, and the tall bitmap keeps the top offset error below
0.05 px. The outlines cover WezTerm's 26 px above and 8 px below the baseline
at 25 px per em, so the corners meet the fill without a gap. Applications that use palette index 235 as a background also become
translucent. A running WezTerm keeps its loaded copy of the font after the file
changes, so restart WezTerm after regenerating the font.

When the tab bar is visible, a blank row separates the tab bar from the panes.
The blank row keeps the selected tab from touching the shaded pane. The patch
`patches/herdr-tab-bar-gap.patch` adds the row, and
`patches/herdr-translucent-surfaces.patch` switches the surfaces to palette
index 235.

WezTerm loads the four pane corners and two rounded tab ends from
`home/.config/wezterm/fonts/HerdrPaneCorners.ttf`. The small font contains
original outlines with JetBrains Mono's cell metrics. Each curve has equal
horizontal and vertical radii; the four corners mirror the same circular shape.
The fallback family is `Herdr Rounded UI`.

WezTerm rounds cell widths up to whole pixels. On a 2x display (144 DPI) a
cell is exactly 15 px, or 600 font units. On a 1x display (72 DPI) a 7.5 px
cell rounds up to 8 px, or 640 font units. One scalable outline cannot fill
both cells, so `HerdrPaneCorners1x.ttf` (family `Herdr Rounded UI 1x`)
carries 640-unit outlines for 1x displays. `wezterm.lua` checks each window's
DPI when the window opens and when the window moves to another display, and
picks the 1x family below 96 DPI. At 96 DPI, which Windows uses at 100%
scaling, a cell is exactly 10 px, so the default family fits.

`wezterm ls-fonts --text` cannot preview the corner glyphs: the tall bitmaps
exceed its fixed texture and it stops with "Texture Size exceeded". The
terminal window grows its texture and draws the glyphs normally.

Regenerate or verify both fonts with:

```sh
uv run home/.config/wezterm/fonts/generate_corners.py
uv run home/.config/wezterm/fonts/generate_corners.py --check
```

The Nix package applies `patches/herdr-focused-pane-background.patch` to Herdr
0.8.2. The package build checks padding, rounded corners, stable terminal sizes
across focus changes, application colors, single-pane shading, and terminal
output updates. The version check in `nix/herdr.nix` requires rebasing the patches
before a Herdr upgrade.

Build and test the custom package:

```sh
nix build .#herdr --out-link .machine/herdr-focus-result
```

Run `./rebuild.sh` to install the custom package through Home Manager.

## Spaces and Agents

Spaces lists workspaces. A workspace holds tabs and a pane layout. Clicking a
workspace switches to that layout while the workspace's processes keep running.
A workspace label can follow a repository name, but each pane can run in a
different directory. For example, an `infrastructure` workspace can contain
one agent in Infrastructure and another agent in Data Platform.

Agents lists individual agents across workspaces. Clicking an agent focuses the
agent's pane. The Agents header control switches between `priority`, which sorts
agents by attention needed, and `grouped`, which groups agents by workspace.

## Agent Labels and Tabs

The Agents sidebar shows each agent's repository in pale blue, branch in pale
purple, task title in white, and agent type in gray. Separate rows leave room
for repository and branch names in the narrow sidebar. The rows and colors live
in `home/.config/herdr/config.toml` under `[ui.sidebar.agents]`.

The custom package also applies `patches/herdr-agent-context.patch`. The patch
provides the reserved `$repo` and `$branch` agent tokens from each terminal's
foreground working directory, with the terminal's directory as a fallback.
Git discovery runs in the existing background refresh every 1.5 seconds.
Linked worktrees show the original repository name and the worktree's branch.
A directory change hides the previous labels until fresh results arrive.
Directories outside Git repositories omit both labels; a detached HEAD omits
the branch. Terminal titles remain task labels.

The same patch renders inactive numbered tabs with the normal light foreground
and removes dimming. Inactive tabs keep the terminal's transparent background.
The package build checks per-agent identities, branch and directory changes,
linked worktrees, stale results, configured label colors, and inactive tab
readability alongside the pane appearance checks.

The selected tab uses the same translucent gray as the focused pane, with a
bold light label and circular corners at both ends. The patch
`patches/herdr-rounded-tabs.patch` places the rounded ends inside the existing
tab padding. Tab widths, spacing, and mouse targets stay the same. The
`Herdr Rounded UI` font supplies two end glyphs in Unicode's plane-16 private-use
area, outside the Nerd Font icon ranges. The package build also checks selected
and inactive tab styles, selection changes, narrow tabs, and wide labels.

The patch `patches/herdr-rounded-sidebar.patch` gives active Spaces and Agents
entries the same gray background and rounded corners. Multirow entries use
the pane corners; single-row entries use the tab ends. Sidebar labels reserve
the rightmost column for the curves, and workspace group controls sit one
column inside the right edge. Configured label colors remain visible.

The same patch centers selected tab labels with equal padding on both sides.
When the available padding has an odd number of cells, the extra cell stays
outside the shaded tab. Tab positions and click targets keep their original
sizes. The package build checks padding, focused sidebar entries, token colors,
narrow cards, and transparent corners.

The terminal theme's `overlay0` color is pale gray (`#b4bfd6`) so muted sidebar
headings and controls remain readable over the transparent background. The
color lives in `home/.config/herdr/config.toml` under `[theme.custom]`. Reload
appearance changes without restarting panes:

```sh
herdr --session wiki server reload-config
```
