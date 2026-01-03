if status is-interactive

    function fish_greeting
        echo fih
    end

    alias a="tmux a"
    alias g="lazygit"
    alias n="cd ~/Documents/Notes; hx ."
    alias p="cd ~/projects; ls"
    alias dot="cd ~/dotfiles"
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

    # zoxide init fish | source

end
