# Source from any shell to put the local toolchain on PATH.
#   source tools/env.sh
#
# Idempotent: re-sourcing won't duplicate entries.

_orchard_tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

case ":$PATH:" in
    *":${_orchard_tools_dir}/cc65/bin:"*) ;;
    *) PATH="${_orchard_tools_dir}/cc65/bin:$PATH" ;;
esac

case ":$PATH:" in
    *":${_orchard_tools_dir}/sjasmplus/sjasmplus-1.23.0.win:"*) ;;
    *) PATH="${_orchard_tools_dir}/sjasmplus/sjasmplus-1.23.0.win:$PATH" ;;
esac

export PATH
unset _orchard_tools_dir
