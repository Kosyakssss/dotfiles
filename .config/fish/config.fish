# Fish is the interactive and login shell. Keep all tracked Fish setup here.

# Homebrew provides system-wide command-line tools on this Mac.
eval (/opt/homebrew/bin/brew shellenv fish)

# User-managed tools override Homebrew tools with the same name.
fish_add_path --global --move \
    "$HOME/.local/bin" \
    "$HOME/.bun/bin" \
    "$HOME/.cargo/bin"

set --global --export EDITOR hx
set --global --export VISUAL hx
set --global --export STARSHIP_CONFIG "$HOME/.config/starship.toml"
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"
set --global --export DPRINT_CONFIG_DIR "$HOME/.config/dprint"

if status is-interactive
    function fish_greeting
        echo ☁️
    end

    abbr --add v nvim
    abbr --add ls eza

    function t
        cd "$HOME/Notes"; and hx todo.md
    end

    function n
        cd "$HOME/Notes"; and hx
    end

    function dot
        cd "$HOME/Dotfiles"; and hx
    end

    # Open Yazi and adopt its final working directory.
    function y
        set --local tmp (mktemp -t yazi-cwd.XXXXXX); or return
        command yazi $argv --cwd-file="$tmp"
        set --local cwd (command cat -- "$tmp")
        command rm -f -- "$tmp"
        if test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
    end

    type --query starship; and starship init fish | source
    type --query zoxide; and zoxide init fish | source
    type --query fzf; and fzf --fish | source
end
