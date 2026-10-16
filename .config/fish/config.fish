set --global --export HOMEBREW_PREFIX /opt/homebrew
set --global --export HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
set --global --export HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX"

set --global --export BUN_INSTALL "$HOME/.bun"
set --global --export JAVA_HOME "$HOMEBREW_PREFIX/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
set --global --export ANDROID_HOME "$HOME/Library/Android/sdk"

fish_add_path --global --move --path \
    "$HOME/.cargo/bin" \
    "$HOMEBREW_PREFIX/bin" \
    "$HOMEBREW_PREFIX/sbin" \
    "$HOME/.local/bin" \
    "$HOME/.optmem" \
    "$BUN_INSTALL/bin" \
    "$JAVA_HOME/bin" \
    "$ANDROID_HOME/platform-tools" \
    "$ANDROID_HOME/emulator" \
    "$ANDROID_HOME/cmdline-tools/latest/bin"

set --global --export EDITOR hx
set --global --export VISUAL hx
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/.ripgreprc"

if status is-interactive
    function fish_greeting
        echo ☁️
    end

    abbr --add ls eza
    abbr --add cc 'claude --dangerously-skip-permissions'
    abbr --add --command git lg 'log --oneline --graph'
    abbr --add --command git st 'status -sb'

    function n
        cd "$HOME/Notes"; and hx
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
end
