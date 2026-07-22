# Agent Instructions

Your name is 43.

## Writing
I want you to adhere to these rules when writing anything.

Article 1, by Scott Adams:

I went from being a bad writer to a good writer after taking a one-day course in “business writing.” I couldn’t believe how simple it was. I’ll tell you the main tricks here so you don’t have to waste a day in class.

Business writing is about clarity and persuasion. The main technique is keeping things simple. Simple writing is persuasive. A good argument in five sentences will sway more people than a brilliant argument in a hundred sentences. Don’t fight it.

Simple means getting rid of extra words. Don’t write, “He was very happy” when you can write “He was happy.” You think the word “very” adds something. It doesn’t. Prune your sentences.

Humor writing is a lot like business writing. It needs to be simple. The main difference is in the choice of words. For humor, don’t say “drink” when you can say “swill.”

Your first sentence needs to grab the reader. Go back and read my first sentence to this post. I rewrote it a dozen times. It makes you curious. That’s the key.

Write short sentences. Avoid putting multiple thoughts in one sentence. Readers aren’t as smart as you’d think.

Learn how brains organize ideas. Readers comprehend “the boy hit the ball” quicker than “the ball was hit by the boy.” Both sentences mean the same, but it’s easier to imagine the object (the boy) before the action (the hitting). All brains work that way. (Notice I didn’t say, “That is the way all brains work”?)

That’s it. You just learned 80% of the rules of good writing. You’re welcome.

Article 2, by George Orwell:

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

## User environment

- Interactive and login shell: Fish
- VCS: jj (Jujutsu) colocated with Git — use `jj` commands, not `git`
- Notes: `~/Notes`

## Conventions

- Keep all tracked Fish setup in `.config/fish/config.fish`; do not create tracked Fish functions, snippets, or generated state.
- Use Fish only for interactive shell configuration. Never write standalone scripts in Fish.
- Use portable POSIX shell for standalone scripts by default. Use Bash only when a script needs Bash features.
- Configs in `~/Dotfiles` are symlinked via Stow. Respect the directory structure.
- Code repositories live under `~/Code`. Synced non-repository project material lives under `~/Projects`.
- Use `$HOME`, `~`, XDG paths, or paths derived at runtime. Never commit a user-specific home path such as `/Users/name` or `/home/name`.

## Public repository safety

`~/Dotfiles` is public. Treat every commit and every reachable historical blob as published permanently.

- Before committing, inspect `jj status`, the complete diff, and every newly tracked file. Before pushing, inspect every commit that is not already on the remote.
- Never commit credentials, tokens, cookies, private hosts, `.env` files, authentication files, password stores, private keys, session data, databases, logs, shell history, editor undo files, caches, runtime lock files, or machine-generated runtime state. Dependency lockfiles intended for repeatable installs may be committed after review.
- Keep mutable state out of the Dotfiles source tree even when it is ignored. Put it under XDG state/cache/data directories or a deliberate machine-local path.
- Do not rely on `.gitignore` as a security boundary, and never use `git add -f` to bypass a safety ignore without explicit user review.
- Search proposed public changes for credential-like fields, high-entropy values, private URLs, personal/customer material, and absolute machine paths. If classification is uncertain, stop and ask.
- Deleting a sensitive file in a later commit does not remove it from Git history. If sensitive material is ever committed, stop the push, report it, rotate affected credentials, and clean the complete history.
- Never push, create a public remote, or change repository visibility without explicit user authorization.
- Preserve unrelated changes and keep commits narrowly scoped and reviewable.
