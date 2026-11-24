function fish_prompt --description 'Write out the prompt'
    set --local last_pipestatus $pipestatus
    set --local --export __fish_last_status $status
    set --local normal (set_color --reset)
    set --local muted (set_color $fish_color_operator)

    set --local color_cwd $fish_color_cwd
    set --local suffix '>'
    if fish_is_root_user
        set color_cwd $fish_color_cwd_root
        set suffix '#'
    end
    set --local cwd (string join '' -- (set_color $color_cwd) (prompt_pwd) $normal)

    if contains -- --final-rendering $argv
        printf '%s %s%s%s ' "$cwd" "$muted" $suffix "$normal"
        return
    end

    set --local status_color (set_color $fish_color_status)
    set --local prompt_status (__fish_print_pipestatus '[' ']' '|' $status_color $status_color $last_pipestatus)

    echo -s (prompt_login) ' ' $cwd (fish_vcs_prompt) $normal ' '$prompt_status
    printf '%s%s%s ' "$muted" $suffix "$normal"
end
