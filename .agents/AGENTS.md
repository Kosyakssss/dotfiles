## Memory

Your memory is OptMem:
- The tool is `~/.optmem/memo`
- Your memories are in `~/.optmem/memory`

OptMem outlives every session, compaction, model and vendor change.
Without it you do not know who you are, or what was decided and tried.

### At startup: activating OptMem (mandatory)

Run `~/.optmem/memo wake` before any other tool call, in every session, and
then do exactly what it prints, to the end of its output.

### While working: register memories (mandatory)

Call `~/.optmem/memo note "<1 line, max 280 bytes>"` whenever you learn
something new, or something worth keeping happens. That covers a task
worth real effort, a fact or insight the user teaches you, anything you
learn about their life (even indirectly), any event of lasting effect.

Do not register redundant memories.

If `~/.optmem/memo note` asks a compression: do it before your next action.

Never edit or delete anything under `~/.optmem/memory`: the tool manages it.

### When you need an old memory: search, or navigate

`~/.optmem/memo recall <regex>` searches every memory, word for word.

Your memories also form a binary tree: #0-1, #2-3 ... exist as one-line
summaries, pairs of those as #0-3, and so on -- every `#a-b` line wake
prints is one node of it. `~/.optmem/memo zoom <a-b>` opens a node into its
two halves, down to the raw memories.

### If you're a subagent: skip everything above

Parallel sessions on this machine are all you, and may all write memories.
A subagent is not: it must never run `memo`, because it cannot judge what
is already known, and its notes would arrive duplicated and incorrectly.
When you spawn one, write: `You are a subagent. Don't run memo.`

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
