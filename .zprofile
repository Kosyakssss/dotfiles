# Homebrew lives outside the default prefix on macOS and Linux.
if [[ -x /opt/homebrew/bin/brew ]]
then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]
then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

# Reuse the portable login environment after system package-manager paths.
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile"