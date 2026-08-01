---
name: update-all
description: Update Kote's global machine-managed tools. Use only when explicitly invoked with /skill:update-all; never invoke automatically.
disable-model-invocation: true
---

Run these global updates, continuing after failures:

```sh
brew update && brew upgrade
npm outdated -g
npm update -g
rustup update
pi update --all
curl -fsSL https://raw.githubusercontent.com/VictorTaelin/OptMem/main/install.sh | sh
```

Do not update apps or project dependencies. Report results and failures.
