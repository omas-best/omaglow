# Architecture decision

Decision date: 2026-09-03

## Context researched

The target at the time of this decision is [Omarchy 4.0.1](https://github.com/omacom/omarchy/releases/tag/v4.0.1). Omarchy 4 uses Hyprland as its compositor and a single Quickshell process for the desktop shell. Its supported third-party extension format is a git repository with `manifest.json` and a QML entry point, installed with `omarchy plugin add`.

The stock Omarchy 4 look and feel is Lua configuration. In the 4.0.1 source, `default/hypr/looknfeel.lua` sets a 2 px active gradient border, disables shadow and blur, and defines a linear animation curve. User and theme modules load after the defaults, so reloading Hyprland is the reliable way to restore the user's effective configuration.

Hyprland 0.56 has the native pieces Omaglow needs:

- [`general.col.active_border`](https://wiki.hypr.land/0.56.0/Configuring/Basics/Variables/) accepts a gradient.
- [`decoration.glow`](https://wiki.hypr.land/0.56.0/Configuring/Basics/Variables/) supplies an active-window inner glow with configurable color, range, and falloff.
- [`borderangle` and `glowangle`](https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Animations/) animate gradient angles with a compositor-owned loop.
- [`hyprctl eval`](https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/) executes Lua against the running compositor. The current configuration reference documents `hyprctl eval 'hl.config(...)'` for runtime option changes.
- Quickshell 0.3.1 exposes Hyprland's raw IPC events, including `configreloaded`, so a service can reapply runtime values without polling.

Recent system reports in the official Omarchy repository identify the shipped stable combination as Omarchy 4.0.1, Hyprland 0.56.2, and Quickshell 0.3.1. This repository still treats that as a target, not a completed compatibility test.

## Decision

Use Hyprland's native border and glow renderer. Package a small Omarchy Shell service that applies the settings once at load and after `configreloaded`.

The QML entry point does not draw anything. It invokes `scripts/omaglowctl`, which validates an optional user config and sends a single batch of Lua evaluations to Hyprland. Hyprland then decides which window is active and renders the border and glow as part of that window's decoration.

When Omaglow unloads, the service runs `hyprctl reload`. Reloading is intentional. It restores all affected values from the user's actual Lua modules instead of guessing what their border, glow, or animation settings were before Omaglow loaded.

## Why this option

Native decorations already have the correct window lifecycle. Focus transfer, moving, resizing, tiling, floating geometry, output transforms, and scale all stay inside the compositor. Omaglow adds no input surface and cannot steal mouse or keyboard focus.

This also avoids build coupling. Hyprland's C++ plugin guidance warns that plugins have deep compositor access and must match the running Hyprland version. A native configuration remains on documented options and runtime commands.

## Tradeoffs

The glow in Hyprland 0.56 is an inner glow. It can soften the active edge, but it is not the broad outer bloom described by the original concept. A true outer aura remains future work unless Hyprland exposes a native outer-glow decoration.

Looped angle animations force redraws at the monitor refresh rate. Hyprland's own animation documentation calls out the CPU, GPU, and battery cost. Omaglow removes shell polling and repeated commands, but it cannot make the animation free. The default 4.5 second cycle changes visual speed, not redraw frequency.

Runtime overrides do not survive a config reload by themselves. The service handles the documented `configreloaded` event and reapplies after 75 ms. If Omarchy Shell is not running, the service is not present and Omaglow is inactive.

Reset reloads the whole Hyprland configuration. Any unrelated runtime-only `hyprctl keyword` changes made after the last config load will also be lost. This is safer than leaving stale Omaglow values behind, but users relying on runtime-only overrides should persist them in Lua first.

Fullscreen decorations are controlled by Hyprland. Some fullscreen modes suppress borders and glow. Omaglow does not draw over those windows.

## Alternatives rejected

### Hyprland C++ plugin

A compositor plugin could add a real outer blur and exact rounded geometry. It would also depend on Hyprland internals, require compilation for the active Hyprland build, and increase crash risk inside the compositor. That cost is not justified while 0.56 already supplies the core animation and active decoration.

### Screen shader

Hyprland's documented screen shader runs at the final output stage. It does not receive a stable, documented active-window rectangle API, so it cannot reliably isolate one window across monitors and scaling without compositor internals.

### Quickshell or layer-shell overlay

An overlay would need focus and geometry tracking, per-output coordinate conversion, rounded clipping, input regions, and careful stacking around fullscreen surfaces. It duplicates state Hyprland already owns and introduces more failure modes.

## Revisit conditions

Reconsider a compositor plugin only if all of these are true:

- a real outer halo is required rather than optional;
- Hyprland still lacks a documented outer-glow decoration;
- the project can maintain exact Hyprland commit pins and build artifacts;
- real tests cover crashes, plugin unload, multiple outputs, mixed scale, and fullscreen behavior.
