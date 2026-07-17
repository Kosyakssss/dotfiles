# General interactive-shell behaviour.
setopt interactive_comments
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt no_beep

export EDITOR=nvim
export VISUAL=nvim
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export RIPGREP_CONFIG_PATH="$HOME/.config/.ripgreprc"
export DPRINT_CONFIG_DIR="$HOME/.config/dprint"

# One owner for interactive PATH ordering; Zsh removes duplicates automatically.
typeset -U path PATH
for directory in   "$HOME/.cargo/bin"   "$HOME/.bun/bin"   "$HOME/.local/bin"
do
  [[ -d "$directory" ]] && path=("$directory" $path)
done
export PATH
