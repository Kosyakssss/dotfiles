# Application portability

This records the function that must survive an operating-system change. The macOS application name is not automatically the Linux requirement: prefer the same application when it is well supported, otherwise select and test a functional replacement on the real Fedora system.

## Directly portable

| Function | macOS | Linux plan |
| --- | --- | --- |
| Terminal | Ghostty | Ghostty |
| Primary browser | Helium | Helium upstream build |
| Agent | Hermes Agent | Hermes official installer |
| Coding agent | Pi | Pi through Bun |
| Dictation | Handy | Handy upstream Linux package |
| Password manager | KeePassXC | KeePassXC; open the synchronized encrypted KDBX database |
| Local file transfer | LocalSend | LocalSend |
| Notes and project vaults | Obsidian | Obsidian |
| BitTorrent | qBittorrent | qBittorrent |
| Media center | Stremio | Stremio |
| File synchronization | Syncthing macOS wrapper | Syncthing daemon and user service |
| Private networking | Tailscale app | Tailscale daemon and CLI |
| RSS/Atom | Feedreader LaunchAgent | Feedreader with a systemd user service, to be implemented on Fedora |

## Replacement required or likely

| Function | Current macOS application | Linux direction |
| --- | --- | --- |
| Video playback | IINA | Start with Celluloid for an IINA-like mpv GUI; use mpv directly if the GUI adds no value |
| Mouse and scroll tuning | LinearMouse | Test desktop/libinput settings first, then input-remapper; use Piper/libratbag for supported configurable mice |
| PDF compression | PDF Squeezer | Test Ghostscript presets for ordinary PDFs and OCRmyPDF optimization for scanned documents |
| Screenshot annotation | Shottr | Test Flameshot and Ksnip under the actual Wayland session; add a separate OCR tool only if their OCR support is insufficient |
| Soulseek | SoulseekQt | Nicotine+ |
| Application cleanup | AppCleaner | No direct replacement expected: DNF and Flatpak own installed files; use their uninstall and cleanup facilities |

## Selection rules

- Do not populate the Fedora package manifest by guessing package names. Verify availability, Wayland behavior, ARM64 support, and required repositories on the running Fedora Asahi system.
- Preserve the required function, not macOS-specific implementation details.
- Prefer maintained native packages, then trusted upstream packages or Flatpak. Avoid opaque install scripts when a reviewable package exists.
- Keep credentials and machine-generated state local. Only the five documented Syncthing roots are synchronized.
- Update this document and `manifests/apps.txt` whenever an application is adopted, replaced, or retired.
