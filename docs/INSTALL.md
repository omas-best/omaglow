# Installation and removal

## Install from git

Omarchy 4 installs third-party shell plugins from git repositories:

```bash
omarchy plugin add https://github.com/omas-best/omaglow.git --enable
```

Omaglow uses Omarchy's supported plugin command and does not write into Omarchy's managed source tree.

Review the repository before enabling it. Omarchy Shell plugins run as the current user without a sandbox.

## Install this checkout

Run these commands from the Omaglow repository root:

```bash
target="$HOME/.config/omarchy/plugins/community.omaglow"
mkdir -p "$target"
cp -a ./. "$target/"
omarchy plugin validate "$target"
omarchy-shell shell rescanPlugins
omarchy plugin enable community.omaglow
```

This is a copy, not a symlink. Omarchy's validator rejects symlinks inside plugin folders.

## Update a development copy

Disable the service before replacing its files so it restores the user's Hyprland settings:

```bash
omarchy plugin disable community.omaglow
target="$HOME/.config/omarchy/plugins/community.omaglow"
cp -a ./. "$target/"
omarchy plugin validate "$target"
omarchy-shell shell rescanPlugins
omarchy plugin enable community.omaglow
```

For a git installation, use `omarchy plugin update community.omaglow`.

## Disable

```bash
omarchy plugin disable community.omaglow
```

The service reloads Hyprland once if it had applied an override. This restores decoration values from the user's Lua configuration.

## Uninstall

For an Omarchy-managed installation:

```bash
omarchy plugin remove community.omaglow
```

Omarchy disables the plugin first. You may also remove the optional user configuration:

```bash
rm ~/.config/omaglow/config.conf
rmdir ~/.config/omaglow 2>/dev/null || true
```

The last two commands remove only Omaglow's config file and its directory if empty.
