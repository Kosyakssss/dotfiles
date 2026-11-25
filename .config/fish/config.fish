set --global --export HOMEBREW_PREFIX /opt/homebrew
set --global --export HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
set --global --export HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX"
set --global --export BUN_INSTALL "$HOME/.bun"

fish_add_path --global --move --path \
    "$HOMEBREW_PREFIX/opt/rustup/bin" \
    "$HOMEBREW_PREFIX/bin" \
    "$HOMEBREW_PREFIX/sbin" \
    "$HOME/.cargo/bin" \
    "$HOME/.local/bin" \
    "$HOME/.optmem" \
    "$BUN_INSTALL/bin"

set --global --export EDITOR nvim
set --global --export VISUAL nvim
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"

if status is-interactive
    function fish_greeting
        echo ☁️
    end

    function n
        cd "$HOME/Notes"
    end
    function code
        cd "$HOME/Code"
    end
    function dot
        cd "$HOME/Dotfiles"
    end

    abbr --add --command git lg 'log --oneline --graph'
    abbr --add --command git st 'status -sb'
    abbr --add vim nvim
    abbr --add v nvim

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
    end

    function __reset_background --on-event fish_postexec
        printf '\e]111\e\\'
    end

    fzf --fish | source
end
