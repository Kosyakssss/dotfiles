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

set --global --export EDITOR hx
set --global --export VISUAL hx
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"

if status is-interactive
    function fish_greeting
        echo ☁️
    end

    function fish_jj_prompt --description 'Write out the jj prompt'
        command -sq jj; or return 1
        set --local dir $PWD
        while not test -d "$dir/.jj"
            test "$dir" = /; and return 1
            set dir (path dirname $dir)
        end
        set --local info (jj log </dev/null 2>/dev/null --no-graph --ignore-working-copy -r '@ | heads(::@ & bookmarks())' -T 'if(current_working_copy, "wc:" ++ if(local_bookmarks, local_bookmarks.join(","), change_id.shortest()) ++ if(conflict, " ×"), "base:" ++ local_bookmarks.join(",")) ++ "\n"')
        or return 1
        set --local wc (string match -rg '^wc:(.*)' -- $info)
        set --local base (string match -rg '^base:(.*)' -- $info)
        test -n "$wc"; or return 1
        set --local parts $wc
        test -n "$base"; and set --append parts → $base
        printf ' (%s)' (string join ' ' $parts)
    end

    function notes
        cd "$HOME/Notes"; and hx
    end
    function code
        cd "$HOME/Code"
    end
    function dot
        cd "$HOME/Dotfiles"
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

    type --query fzf; and fzf --fish | source
end
