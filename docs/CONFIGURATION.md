# Configuration

Omaglow reads its bundled defaults first, then overrides them with `~/.config/omaglow/config.conf` when that file exists. The format is strict `key=value` text. Blank lines and comments beginning with `#` are allowed.

Create a user config from the installed defaults:

```bash
mkdir -p ~/.config/omaglow
cp ~/.config/omarchy/plugins/community.omaglow/config/default.conf \
  ~/.config/omaglow/config.conf
```

## Settings

| Key | Default | Valid value | Effect |
| --- | --- | --- | --- |
| `enabled` | `true` | `true` or `false` | Applies the effect or restores the Hyprland config. |
| `colors` | `00d9ff,3388ff,9b5de5,00d9ff` | 2 to 8 comma-separated six-digit RGB values | Sets both active border and glow gradients. Repeating cyan closes the loop smoothly. |
| `speed` | `4.5` | 0.5 to 60 seconds | Sets one full border and glow rotation. |
| `intensity` | `0.70` | 0 to 1 | Multiplies the glow alpha. |
| `radius` | `8` | integer from 0 to 100 | Sets Hyprland's inner glow range in layout pixels. |
| `border_size` | `2` | integer from 1 to 20 | Sets the window border thickness in layout pixels. |
| `opacity` | `0.90` | 0 to 1 | Sets border alpha and also caps glow alpha. |

The parser does not execute the file as shell code. Quotes are not needed and become part of the value, so do not add them.

## Example

```ini
enabled=true
colors=00e5ff,2979ff,9c4dff,00e5ff
speed=6
intensity=0.55
radius=6
border_size=2
opacity=0.85
```

Apply changes to an installed copy:

```bash
~/.config/omarchy/plugins/community.omaglow/scripts/omaglowctl apply
```

Check the file without changing the compositor:

```bash
~/.config/omarchy/plugins/community.omaglow/scripts/omaglowctl check
```

Inspect the exact batched Hyprland Lua:

```bash
~/.config/omarchy/plugins/community.omaglow/scripts/omaglowctl print
```

## Restore stock settings

Set `enabled=false` and run `apply`, disable the Omarchy plugin, or run:

```bash
~/.config/omarchy/plugins/community.omaglow/scripts/omaglowctl reset
```

Reset uses `hyprctl reload`. This restores the user's saved Lua configuration and also clears unrelated runtime-only Hyprland overrides.
