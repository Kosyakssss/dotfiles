# Interactive Zsh entry point. Keep startup declarative and side-effect free.
[[ -o interactive ]] || return

for module in   options history completion keybindings aliases functions integrations
do
  source "$HOME/.config/zsh/${module}.zsh"
done

[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
