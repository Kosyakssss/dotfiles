# Portable user executables for POSIX login shells.
for directory in "$HOME/.cargo/bin" "$HOME/.bun/bin" "$HOME/.local/bin"
do
  case ":$PATH:" in
    *":$directory:"*) ;;
    *) PATH="$directory:$PATH" ;;
  esac
done
unset directory
export PATH