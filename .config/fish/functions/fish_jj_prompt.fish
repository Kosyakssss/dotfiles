function fish_jj_prompt --description 'Write out the jj prompt'
    command -sq jj; or return 1
    set --local dir $PWD
    while not test -d "$dir/.jj"
        test "$dir" = /; and return 1
        set dir (path dirname $dir)
    end
    set --local info (jj log </dev/null 2>/dev/null --no-graph --ignore-working-copy -r '@ | heads(::@ & bookmarks())' -T 'if(current_working_copy, "wc:" ++ local_bookmarks.join(" ") ++ "\nid:" ++ change_id.shortest() ++ if(conflict, "\nconflict"), "base:" ++ local_bookmarks.join(" ")) ++ "\n"')
    or return 1
    set --local label (string match -rg '^wc:(.+)' -- $info)
    test -n "$label"; or set label (string match -rg '^base:(.+)' -- $info)
    test -n "$label"; or set label (string match -rg '^id:(.+)' -- $info)
    test -n "$label"; or return 1

    set --local muted (set_color $fish_color_jj_base)
    set --local color (set_color $fish_color_jj)
    contains -- conflict $info; and set color (set_color $fish_color_error)

    printf ' %s(%s%s%s)%s' "$muted" "$color" (string join ' ' -- $label) "$muted" "$(set_color --reset)"
end
