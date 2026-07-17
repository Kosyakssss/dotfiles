# Open Yazi and adopt its final working directory.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  rm -f -- "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
}
