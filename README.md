# Dotfiles

Public, reviewable configuration for macOS.

Fish is the login and interactive shell. Its full tracked setup lives in `.config/fish/config.fish`; other Fish files are ignored. Standalone shell scripts use portable POSIX `sh` by default and Bash only when needed. Fish is not used for scripts.

Apply the configuration from the repository root with GNU Stow:

```sh
stow --target="$HOME" .
```

Portable Pi configuration is tracked under `.pi/agent/`. Credentials, memory, sessions, caches, generated dependencies, and other machine-local state remain outside this public repository.
