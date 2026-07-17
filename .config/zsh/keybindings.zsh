# Emacs-style editing with predictable word navigation.
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
