---
name: update-all
description: Update Kote's global machine-managed tools. Use only when explicitly invoked with /skill:update-all; never invoke automatically.
disable-model-invocation: true
---

Run these global updates, continuing after failures:

```sh
brew update && brew upgrade
bun update -g
bun pm untrusted -g
rustup update
uv python upgrade
curl -fsSL https://raw.githubusercontent.com/VictorTaelin/OptMem/main/install.sh | sh
curl -fsSL https://cua.ai/driver/install.sh | bash
```

Do not update apps or project dependencies. Report results and failures.
