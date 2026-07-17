# Agent Instructions

## User environment

- Shell: Zsh
- VCS: jj (Jujutsu) colocated with Git — use `jj` commands, not `git`
- Notes: `~/Notes`

## Conventions

- Write interactive shell configuration in Zsh; use portable POSIX shell for standalone scripts unless Zsh-specific features are required.
- Configs in `~/Dotfiles` are symlinked via Stow. Respect the directory structure.
- Code repositories live under `~/Code`. Synced non-repository project material lives under `~/Projects`.
- Use `$HOME`, `~`, XDG paths, or paths derived at runtime. Never commit a user-specific home path such as `/Users/name` or `/home/name`.

## Public repository safety

`~/Dotfiles` is public. Treat every commit and every reachable historical blob as published permanently.

- Before committing, inspect `jj status`, the complete diff, and every newly tracked file. Before pushing, inspect every commit that is not already on the remote.
- Never commit credentials, tokens, cookies, private hosts, `.env` files, authentication files, password stores, private keys, session data, databases, logs, shell history, editor undo files, caches, lock files, or machine-generated runtime state.
- Keep mutable state out of the Dotfiles source tree even when it is ignored. Put it under XDG state/cache/data directories or a deliberate machine-local path.
- Do not rely on `.gitignore` as a security boundary, and never use `git add -f` to bypass a safety ignore without explicit user review.
- Search proposed public changes for credential-like fields, high-entropy values, private URLs, personal/customer material, and absolute machine paths. If classification is uncertain, stop and ask.
- Deleting a sensitive file in a later commit does not remove it from Git history. If sensitive material is ever committed, stop the push, report it, rotate affected credentials, and clean the complete history.
- Never push, create a public remote, or change repository visibility without explicit user authorization.
- Preserve unrelated changes and keep commits narrowly scoped and reviewable.

## Browser / Chromium

- Helium is the primary Chromium browser for this machine.
- For browser work, first try the Chrome/extension bridge and enumerate live tabs before assuming the browser is unavailable or that only the Codex in-app browser exists.
- If the Chrome bridge is unavailable, use Computer Use against Helium for visual inspection and UI actions.
