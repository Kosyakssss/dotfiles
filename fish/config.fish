if status is-interactive

    function fish_greeting
        echo "🐟"
    end

    alias vim="nvim"
    alias n="cd ~/Documents/Notes; vim"

    function fish_prompt
        echo
        set_color $fish_color_cwd
        echo -n (prompt_pwd)
        set_color normal
        echo -n "> "
    end

    set -gx PATH $PATH /Users/kote/Library/pnpm
    set -gx PATH $PATH ~/.local/share/bob/nvim-bin

end
