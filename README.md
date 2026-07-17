# Dotfiles

Public, reviewable configuration for macOS and Linux.

This repository is descriptive rather than self-bootstrapping:

- `manifests/` records intended software and installation ownership;
- `.config/zsh/` contains modular, side-effect-light Zsh configuration;
- `docs/security.md` defines public, private, secret, and local state;
- `docs/application-portability.md` maps current macOS applications to Linux equivalents or evaluation plans;
- an agent reconciles these files with each real machine.

Zsh is the active login shell. Standalone shell scripts should prefer portable POSIX shell.

Apply the public configuration from the repository root with `stow --target="$HOME" .`. Private portable application settings live separately in `~/PrivateConf`; see `docs/security.md`.
