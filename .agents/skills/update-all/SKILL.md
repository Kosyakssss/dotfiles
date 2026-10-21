---
name: update-all
description: Update global machine-managed tools.
disable-model-invocation: true
---

Run these global updates, continuing after failures:

```sh
brew update && brew upgrade
bun update -g
bun pm untrusted -g
rustup update
uv python upgrade
curl -fsSL https://cua.ai/driver/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/VictorTaelin/OptMem/main/install.sh | sh
```

Do not update apps or project dependencies. Report results and failures.
