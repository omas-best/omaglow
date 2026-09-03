# Development

## Repository layout

| Path | Purpose |
| --- | --- |
| `manifest.json` | Omarchy Shell plugin manifest. |
| `OmaglowService.qml` | Service lifecycle and `configreloaded` listener. |
| `scripts/omaglowctl` | Config validation and batched Hyprland runtime control. |
| `config/default.conf` | Tasteful default palette and dimensions. |
| `.codex-plugin/plugin.json` | Codex plugin metadata for this repository. |
| `tests/test_omaglowctl.sh` | Shell-level automated checks with a fake Hyprland control command. |

## Automated checks

From the repository root:

```bash
./tests/test_omaglowctl.sh
./scripts/omaglowctl check
python3 /path/to/plugin-creator/scripts/validate_plugin.py .
```

When developing on Omarchy 4, also run:

```bash
omarchy plugin validate .
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml OmaglowService.qml
```

The last command comes from Arch's `qt6-declarative` package. The explicit import path resolves the Quickshell modules installed by Omarchy.

## Local iteration

Copy the checkout using the steps in `docs/INSTALL.md`. Omarchy watches installed plugin files and reloads changed QML. For script-only changes, copy the file and run the installed `omaglowctl apply` command.

Watch the Omarchy Shell log while changing lifecycle code. Confirm that one apply happens at service load and one apply follows each real `configreloaded` event. There must be no repeated apply loop.

## Manual test matrix

The prototype needs a real Omarchy 4.0.1 session with Hyprland 0.56.2 before release. Record the monitor layout, scale, refresh rate, GPU, package versions, and result for each case. Do not turn an unrun row into a compatibility claim.

- Change focus between two tiled windows.
- Change focus between tiled and floating windows.
- Move and resize a floating window.
- Resize tiles and change layouts.
- Close the focused window and leave a workspace empty.
- Test maximized and both Hyprland fullscreen modes.
- Move a window across monitors.
- Test two monitors with the same scale.
- Test mixed fractional scales, including 1.0 and 1.5 or 2.0.
- Reload Hyprland and confirm Omaglow reapplies once.
- Disable Omaglow and compare all affected settings with the Lua config.
- Restart Omarchy Shell and confirm the effect returns.
- Suspend and resume.

## Performance measurement

Hyprland documents that looped angle animations redraw at the monitor refresh rate. Measure the compositor, not the shell script. Compare an idle desktop for at least 60 seconds with Omaglow disabled and enabled under the same monitor refresh rate and window arrangement. Record GPU busy time, package power if available, and `Hyprland` CPU usage. Repeat at 60 Hz and the display's highest refresh rate.

No performance number is included yet because this repository has not run that hardware test.

## Release checklist

- Run the shell tests.
- Run both manifest validators.
- Run QML lint with Omarchy's import paths.
- Complete the manual matrix on supported hardware.
- Replace the concept preview with a real screenshot or GIF and label the tested versions.
- Confirm the published repository URL in the install instructions.
- Tag a semantic version matching both manifests.
