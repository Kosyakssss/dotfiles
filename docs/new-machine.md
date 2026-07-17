# New machine

1. Install Pi using the appropriate mechanism for the actual OS.
2. Clone `~/Dotfiles`.
3. Ask Pi to inspect the host and read `README.md`, `docs/`, and `manifests/`.
4. Reconcile applications and packages manually; do not execute manifests blindly.
5. Apply the common and platform-appropriate Stow configuration.
6. Enroll `~/Lib-rary`, `~/Documents`, `~/Notes`, `~/Projects`, and `~/PrivateConf` as separate Syncthing folders and wait for them to finish syncing. Install the local `.stignore` rules on every device because Syncthing does not synchronize that file.
7. Link portable private configuration:
   - `~/.hermes/config.yaml`, `SOUL.md`, and `memories/` to `~/PrivateConf/hermes/`;
   - `~/.pi/agent/settings.json` to `~/PrivateConf/pi/settings.json`.
8. Configure Hermes/Pi credentials locally; never copy auth files with the portable configuration.
9. Verify shell PATH, editor, Git/JJ, agents, and application availability.

The Fedora manifest intentionally remains incomplete until inspected on the real system.
