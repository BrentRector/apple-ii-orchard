# Source from any shell to put the local toolchain on PATH and the project's
# Python packages on PYTHONPATH.
#   source shared/toolchain/env.sh
#
# Idempotent: re-sourcing won't duplicate entries.

_orchard_tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# repo root is two levels up: <root>/shared/toolchain
_orchard_root="$(cd "${_orchard_tools_dir}/../.." && pwd)"

case ":$PATH:" in
    *":${_orchard_tools_dir}/cc65/bin:"*) ;;
    *) PATH="${_orchard_tools_dir}/cc65/bin:$PATH" ;;
esac

case ":$PATH:" in
    *":${_orchard_tools_dir}/sjasmplus/sjasmplus-1.23.0.win:"*) ;;
    *) PATH="${_orchard_tools_dir}/sjasmplus/sjasmplus-1.23.0.win:$PATH" ;;
esac

export PATH

# Make the importable packages resolvable by bare name (import nibbler, etc.)
# without a pip install, mirroring conftest.py for the test runner.
for _orchard_tree in "${_orchard_root}/shared" "${_orchard_root}/cpm-80" "${_orchard_root}/apple-ii"; do
    case ":${PYTHONPATH:-}:" in
        *":${_orchard_tree}:"*) ;;
        *) PYTHONPATH="${_orchard_tree}${PYTHONPATH:+:${PYTHONPATH}}" ;;
    esac
done
export PYTHONPATH

unset _orchard_tools_dir _orchard_root _orchard_tree
