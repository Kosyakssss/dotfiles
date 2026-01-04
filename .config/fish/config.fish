if status is-interactive

    function fish_greeting
        echo fih
    end

    alias a="tmux a"
    alias g="lazygit"
    alias n="cd ~/Documents/Notes; hx ."
    alias p="cd ~/projects; ls"
    alias dot="cd ~/dotfiles/.config"
    alias ll="ls -lah"

    function fish_prompt
        echo
        echo -n (prompt_pwd)
        set_color normal
        echo -n " > "
    end

    set -gx EDITOR hx
    set -gx PATH $PATH ~/.bun/bin
    set -gx PATH $PATH ~/.cargo/bin
    set -gx PATH $PATH /home/kote/.amp/bin
    set -gx PATH $PATH /home/kote/.local/bin
    set -gx PNPM_HOME "/home/kote/.local/share/pnpm"
    set -gx PATH $PATH "$PNPM_HOME"
    set -gx RIPGREP_CONFIG_PATH "$HOME/dotfiles/.ripgreprc"

    # Yazi

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # Helix automatic theme sync script

    function sync_helix_theme
        set current_theme (defaults read -g AppleInterfaceStyle 2>/dev/null)
        set config_path "$HOME/.config/helix/config.toml"

        if test -f $config_path
            if test "$current_theme" = Dark
                set new_theme flexoki_dark
            else
                set new_theme flexoki_light
            end

            set current_helix_theme (grep "^theme = " $config_path | sed 's/theme = "\(.*\)"/\1/')

            if test "$current_helix_theme" != "$new_theme"
                sed -i '' "s/^theme = .*/theme = \"$new_theme\"/" $config_path
            end
        end
    end

    # Run on shell startup
    sync_helix_theme

    # Auto-check on command execution
    function __helix_theme_check --on-event fish_preexec
        sync_helix_theme
    end

    # zoxide init fish | source

end
