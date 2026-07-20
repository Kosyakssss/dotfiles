# General interactive-shell behaviour.
setopt interactive_comments
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt no_beep

export EDITOR=hx
export VISUAL=hx
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export RIPGREP_CONFIG_PATH="$HOME/.config/.ripgreprc"
export DPRINT_CONFIG_DIR="$HOME/.config/dprint"

# One owner for interactive PATH ordering. Remove duplicates and stale entries
# inherited from path_helper or old package managers before adding user tools.
typeset -U path PATH
typeset -a existing_path
for directory in $path
do
  [[ -d "$directory" ]] && existing_path+=("$directory")
done
path=($existing_path)
for directory in "$HOME/.cargo/bin" "$HOME/.bun/bin" "$HOME/.local/bin"
do
  [[ -d "$directory" ]] && path=("$directory" $path)
done
unset existing_path directory
export PATH
