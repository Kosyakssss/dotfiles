## Writing

- Use the shortest complete answer.
- Base response length on what the task requires, not on the length of the user's message.
- Treat background, thinking aloud, and transcripts as context. Do not repeat, summarize, or answer each part unless asked.
- Address the request and key decisions only. Do not turn a narrow question into a report.
- Cut introductions, recaps, repetition, stock phrases, and needless examples.
- Prefer short, plain, direct English and active voice.
- Avoid figures of speech.
- Use technical terms when they improve accuracy. Explain uncommon terms briefly.
- For reports, lean toward ASD-STE100, but don't overdo it.
- When a long answer is necessary, keep it structured and stop once the task is complete.

## User environment

- Interactive and login shell: Fish
- Version control: JJ (jujutsu). When working in a repo where jj is already initialized or creating a new one, always use jj for everything, including commits and pushes
- Notes: `~/Notes`
- Everything related to code: `~/Code/`
- Everything related to non-code projects: `~/Projects/` (if a project needs some code, make a matching folder in ~/Code/)

## Conventions

- Keep all tracked Fish setup in `.config/fish/config.fish`; do not create tracked Fish functions, snippets, or generated state.
- Use Fish only for interactive shell configuration. Never write standalone scripts in Fish.
- Configs in `~/Dotfiles` are symlinked via Stow. Respect the directory structure. If we ever want to track some kind of a global config and it can be done using this, use it, don't just make one-off symlinks
- Use `$HOME`, `~`, XDG paths, or paths derived at runtime. Never commit a user-specific home path such as `/Users/name` or `/home/name`.
- Do not leave comments in any code, for any reason.
- New test files are opt-in. Do not create unit, integration, end-to-end, or spec files, or new test-only helpers/fixtures, unless the user explicitly requests their creation or approves it first. A request to implement, fix, test, or verify something does not by itself authorize new test files. Assume no by default; ask only when creating them has a concrete benefit, not as a routine step.
- Prefer running existing tests and direct browser/runtime checks without adding test files. Where test changes are in scope, exercise observable behavior rather than asserting source-code strings, implementation shapes, or that tests exist.

## Public repositories

Treat committed data as public.

- Never commit secrets, credentials, private keys, session data, personal data, or machine-local state.
- Before committing, review the staged diff and new files. Preserve unrelated changes.
- Run a wider secret and history check only when changes involve auth, private URLs, generated files, large data, Git history, or other sensitive content.
- Never push, create a public remote, rewrite shared history, or change repository visibility without explicit approval.
- If you cannot tell whether data is safe to publish, stop and ask.

# When using Bend:
- run `bend guide` to learn it
- use `LAWS.bend` to keep important rules
- run `bend PROOF.bend` before committing
- parallelize the code whenever possible
