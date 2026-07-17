# Interactive integrations require a live ZLE (terminal) session.
if [[ -o zle && -t 0 && -t 1 ]]; then
  command -v starship >/dev/null && eval "$(starship init zsh)"
  command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
  command -v fzf >/dev/null && source <(fzf --zsh)
fi
