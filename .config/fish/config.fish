eval (/opt/homebrew/bin/brew shellenv fish)

fish_add_path --global --move \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.optmem"

set -g fish_transient_prompt 1
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
    abbr --add --command git lg 'log --oneline --graph'
    abbr --add --command git st 'status -sb'

    # Keep the complete Git segment on the right side of the prompt.
    set -g __fish_git_prompt_showdirtystate yes
    set -g __fish_git_prompt_showuntrackedfiles yes
    set -g __fish_git_prompt_showstashstate yes
    set -g __fish_git_prompt_showupstream informative
    set -g __fish_git_prompt_show_informative_status yes
    set -g __fish_git_prompt_status_order stagedstate invalidstate dirtystate untrackedfiles stashstate
    set -g __fish_git_prompt_char_stagedstate ' +'
    set -g __fish_git_prompt_char_invalidstate ' !'
    set -g __fish_git_prompt_char_dirtystate ' *'
    set -g __fish_git_prompt_char_untrackedfiles ' ?'
    set -g __fish_git_prompt_char_stashstate ' $'
    set -g __fish_git_prompt_char_stateseparator ''
    set -g __fish_git_prompt_char_upstream_ahead '↑'
    set -g __fish_git_prompt_char_upstream_behind '↓'
    set -g __fish_git_prompt_char_upstream_diverged '↕'
    set -g __fish_git_prompt_char_upstream_equal '='
    set -g __fish_git_prompt_char_upstream_prefix ' '

    function fish_prompt
        set -l last_pipestatus $pipestatus
        set -lx __fish_last_status $status
        set -l normal (set_color --reset)
        set -l color_cwd $fish_color_cwd
        set -l suffix '>'

        if functions -q fish_is_root_user; and fish_is_root_user
            if set -q fish_color_cwd_root
                set color_cwd $fish_color_cwd_root
            end
            set suffix '#'
        end

        set -l bold_flag --bold
        set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
        if test $__fish_prompt_status_generation = $status_generation
            set bold_flag
        end
        set __fish_prompt_status_generation $status_generation
        set -l status_color (set_color $fish_color_status)
        set -l statusb_color (set_color $bold_flag $fish_color_status)
        set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

        echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal " "$prompt_status $suffix " "
    end

    function fish_right_prompt
        set -l saved_upstream $__fish_git_prompt_showupstream
        set -g __fish_git_prompt_showupstream none
        set -l git_info (fish_git_prompt '(%s)')
        set -g __fish_git_prompt_showupstream $saved_upstream
        set -l git_parts (string match -r -g '^\(([^ ]+)( .*)\)$' -- "$git_info")
        if test (count $git_parts) -eq 2
            set git_info "($git_parts[1])$git_parts[2]"
        end
        set -l upstream_info (__fish_git_prompt_show_upstream)
        if test -n "$git_info"
            printf '<%s%s' $git_info $upstream_info
        end
    end

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
end

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"
