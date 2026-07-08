# tmux Cheatsheet

Prefix means: press `Ctrl-b`, release, then press the next key.

## Sessions

Outside tmux:

```sh
tn work          # new session named work
tls              # list sessions
ta work          # attach to session named work
tmux kill-session -t work
```

Inside tmux:

```text
Prefix d         detach from session
Prefix r         reload tmux config
Prefix ?         show every tmux key binding
Prefix /         show this cheatsheet
```

## Windows

Think of windows as tmux tabs inside one session.

```text
Prefix c         new window in current directory
Prefix n         next window
Prefix p         previous window
Prefix 1..9      jump to window number
Prefix ,         rename current window
Prefix &         close current window
```

## Panes

Think of panes as splits inside one window.

```text
Prefix |         split left/right
Prefix -         split top/bottom
Prefix h/j/k/l   move left/down/up/right
Prefix H/J/K/L   resize left/down/up/right
Prefix z         zoom/unzoom current pane
Prefix x         close current pane
Prefix Space     cycle pane layouts
```

Reset to one pane:

```text
Prefix :         open tmux command prompt
kill-pane -a     keep current pane, close the others
```

## Copy Mode

```text
Prefix [         enter copy mode
v                start selection
y                copy selection
q                quit copy mode
```

Mouse selection and pane resizing are enabled.

## Good Daily Flow

```sh
cd ~/project
tn project
nvim .
```

Detach with `Prefix d`; resume later with `ta project`.
