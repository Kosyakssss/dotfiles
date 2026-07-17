# System model

This repository records intended configuration and software ownership. It does not bootstrap machines.

On a new machine, install Pi, clone this repository, inspect the actual operating system, and reconcile the manifests manually with an agent. Manifests describe intent; package managers remain authoritative for installation state.

## Boundaries

- `~/Code`: Git repositories and generated dependencies; outside Syncthing.
- `~/Projects`: synchronized non-repository project and venture material.
- `~/Notes`: the synchronized Obsidian vault, including its configuration.
- `~/Documents`: synchronized personal documents.
- `~/Lib-rary`: synchronized books, media, and reference material; this is unrelated to macOS `~/Library`.
- `~/Dotfiles`: public, reviewable configuration applied with Stow and distributed through Git, never Syncthing.
- `~/PrivateConf`: private, credential-free portable configuration synchronized by Syncthing.
- `~/.hermes` and `~/.pi`: mixed state; only deliberate links into `~/PrivateConf` are synchronized.
- macOS `~/Library`, credentials, sessions, databases, logs, caches, and editor state remain machine-local.

The phone is a relay between macOS and Linux. Before switching operating systems, wait for the current computer and phone to become fully synchronized; after switching, wait for the new system to become fully synchronized before editing. The last device to edit after a completed synchronization is authoritative. The systems must not write the same synchronized files concurrently.

Use `$HOME`, `~`, XDG paths, or standard platform prefixes instead of user-specific absolute paths. Keep unavoidable host differences in ignored local overrides rather than forking common configuration.
