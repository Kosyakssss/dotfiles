# Native Zsh completion, cached without creating files outside compinit itself.
autoload -Uz compinit
_compcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [[ -d "$_compcache" ]]; then
  _compdump="$_compcache/zcompdump-${HOST}-${ZSH_VERSION}"
else
  _compdump="$HOME/.zcompdump-${HOST}-${ZSH_VERSION}"
fi
compinit -d "$_compdump"
unset _compcache _compdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' special-dirs true
