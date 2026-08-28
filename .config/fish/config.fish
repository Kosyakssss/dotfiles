eval (/opt/homebrew/bin/brew shellenv fish)

set --global --export BUN_INSTALL "$HOME/.bun"

fish_add_path --global --move \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$BUN_INSTALL/bin"

set --global --export EDITOR hx
set --global --export VISUAL hx
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"
set --global --export DPRINT_CONFIG_DIR "$HOME/.config/dprint"

if status is-interactive
    function fish_greeting
        echo ☁️
    end

    abbr --add v nvim
    abbr --add ls eza

    function n
        cd "$HOME/Notes"; and hx
    end

    function dot
        cd "$HOME/Dotfiles"; and hx
    end

    function y
        set --local tmp (mktemp -t yazi-cwd.XXXXXX); or return
        command yazi $argv --cwd-file="$tmp"
        set --local cwd (command cat -- "$tmp")
        command rm -f -- "$tmp"
        if test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
    end

    type --query zoxide; and zoxide init fish | source
    type --query fzf; and fzf --fish | source
    oh-my-posh init fish --strict --config "$HOME/.config/oh-my-posh/config.toml" | source
end
