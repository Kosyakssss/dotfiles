# Configuration security

## Public

Safe after review: shell/editor/terminal configuration, package manifests, Pi settings without credentials, and generic agent instructions. Before publishing, scan for tokens, private hosts, personal identifiers, customer names, and sensitive paths.

## Private synchronized

`~/PrivateConf` is the dedicated private Syncthing root. The live portable files are linked from their normal application paths:

- Hermes `config.yaml`, `SOUL.md`, and `memories/`;
- Pi `settings.json`;
- encrypted KeePass `*.kdbx` databases;
- a future encrypted `pass/` store when first needed.

Portable configuration must not contain credentials. Do not synchronize live databases.

## Secrets

Use `pass` for future API keys and other non-password secrets, but do not install or initialize it until the first such secret appears. Never commit or ordinarily synchronize `~/.hermes/.env`, `~/.hermes/auth.json`, `~/.pi/agent/auth.json`, SSH private keys, or GPG private keys.

Load secrets per command or application. Do not export every credential from `.zshrc`.

## Local/private state

Keep these local unless a deliberate export process is designed:

- shell history and editor undo, spell, cache, and state files;
- `~/.hermes/state.db`, sessions, logs, caches, snapshots and `*.db-wal`/`*.db-shm`;
- `~/.pi/agent/sessions`;
- Hermes/Pi installed runtimes and extension caches;
- SSH `known_hosts`;
- macOS `~/Library` and generated LaunchAgents.

The five deliberate Syncthing roots are `~/Lib-rary`, `~/Documents`, `~/Notes`, `~/Projects`, and `~/PrivateConf`. Each device needs local `.stignore` rules; Syncthing does not synchronize `.stignore`. Do not place `~/PrivateConf` inside a broader public or casually shared root.
