# Agent Instructions

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

## User environment

- Interactive and login shell: Fish
- VCS: jj (Jujutsu) colocated with Git — use `jj` commands, not `git`
- Notes: `~/Notes`

## Conventions

- Keep all tracked Fish setup in `.config/fish/config.fish`; do not create tracked Fish functions, snippets, or generated state.
- Use Fish only for interactive shell configuration. Never write standalone scripts in Fish.
- Use portable POSIX shell for standalone scripts by default. Use Bash only when a script needs Bash features.
- Configs in `~/Dotfiles` are symlinked via Stow. Respect the directory structure.
- Code repositories live under `~/Code`. Synced non-repository project material lives under `~/Projects`.
- Use `$HOME`, `~`, XDG paths, or paths derived at runtime. Never commit a user-specific home path such as `/Users/name` or `/home/name`.

## Public repository safety

`~/Dotfiles` is public. Treat every commit and every reachable historical blob as published permanently.

- Before committing, inspect `jj status`, the complete diff, and every newly tracked file. Before pushing, inspect every commit that is not already on the remote.
- Never commit credentials, tokens, cookies, private hosts, `.env` files, authentication files, password stores, private keys, session data, databases, logs, shell history, editor undo files, caches, runtime lock files, or machine-generated runtime state. Dependency lockfiles intended for repeatable installs may be committed after review.
- Keep mutable state out of the Dotfiles source tree even when it is ignored. Put it under XDG state/cache/data directories or a deliberate machine-local path.
- Do not rely on `.gitignore` as a security boundary, and never use `git add -f` to bypass a safety ignore without explicit user review.
- Search proposed public changes for credential-like fields, high-entropy values, private URLs, personal/customer material, and absolute machine paths. If classification is uncertain, stop and ask.
- Deleting a sensitive file in a later commit does not remove it from Git history. If sensitive material is ever committed, stop the push, report it, rotate affected credentials, and clean the complete history.
- Never push, create a public remote, or change repository visibility without explicit user authorization.
- Preserve unrelated changes and keep commits narrowly scoped and reviewable.
