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

    set --local muted (set_color $fish_color_jj_base)
    set --local color (set_color $fish_color_jj)
    string match -q '* ×' -- $wc; and set color (set_color $fish_color_error)

    printf ' %s(%s%s' "$muted" "$color" "$wc"
    test -n "$base"; and printf '%s → %s' "$muted" (string join ' ' -- $base)
    printf '%s)%s' "$muted" "$(set_color --reset)"
end
