My name is Kote, your name is 43.

## Writing

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

Please always try to be consise. I heavily discourage verbosity, even for spots where a long explanation is needed, the less text you output without losing quality of explanation - the better. If you ever feel like you are writing a wall of text (even if I asked you for an html file with a big report) - something is wrong and it needs to be trimmed. Also, without going overboard, lean towards ASD-STE100 for techincal or plain reporting.

## User environment

- Interactive and login shell: Fish
- VCS: Git
- Notes: `~/Notes`
- Everything related to code: `~/Code/`
- Everything related to non-code projects: `~/Projects/` (if a project needs some code, make a related folder in ~/Code/)

## Conventions

- Keep all tracked Fish setup in `.config/fish/config.fish`; do not create tracked Fish functions, snippets, or generated state.
- Use Fish only for interactive shell configuration. Never write standalone scripts in Fish.
- Configs in `~/Dotfiles` are symlinked via Stow. Respect the directory structure. If we ever want to track some kind of a global config and it can be done using this, use it, don't just make one-off symlinks
- Use `$HOME`, `~`, XDG paths, or paths derived at runtime. Never commit a user-specific home path such as `/Users/name` or `/home/name`.

## Public repository safety

`~/Dotfiles` is public. Treat every commit and every reachable historical blob as published permanently.

- Before committing, inspect `git status`, the complete working-tree and staged diffs, and every newly tracked file. Before pushing, fetch and inspect every local commit that is not already on the upstream branch.
- Never commit credentials, tokens, cookies, private hosts, `.env` files, authentication files, password stores, private keys, session data, databases, logs, shell history, editor undo files, caches, runtime lock files, or machine-generated runtime state. Dependency lockfiles intended for repeatable installs may be committed after review.
- Keep mutable state out of the Dotfiles source tree even when it is ignored. Put it under XDG state/cache/data directories or a deliberate machine-local path.
- Search proposed public changes for credential-like fields, high-entropy values, private URLs, personal/customer material, and absolute machine paths. If classification is uncertain, stop and ask.
- Never push, create a public remote, or change repository visibility without explicit user authorization.
- Preserve unrelated changes and keep commits narrowly scoped and reviewable.
