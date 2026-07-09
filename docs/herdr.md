# Herdr Cheatsheet

Prefix means: press `Ctrl-b`, release, then press the next key.

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
