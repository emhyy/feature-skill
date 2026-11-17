#!/usr/bin/env bash
# Install, update or remove the "feature" skill for Claude Code, Codex and Antigravity.
#
#   ./install.sh                    install for every supported tool found on this machine
#   ./install.sh claude codex       install only for the tools you name
#   ./install.sh --uninstall        remove it from every tool
#   ./install.sh --uninstall codex  remove it only from the tools you name
#
# Tools: claude, codex, antigravity

set -euo pipefail

SKILL_NAME="feature"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SKILL_NAME"
ALL_TOOLS="claude codex antigravity"

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# The directory that holds a tool's configuration.
tool_home() {
  case "$1" in
    claude) echo "$HOME/.claude" ;;
    codex) echo "$HOME/.codex" ;;
    antigravity) echo "$HOME/.gemini" ;;
    *) return 1 ;;
  esac
}

uninstall=false
tools=""
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --uninstall) uninstall=true ;;
    claude | codex | antigravity) tools="$tools $arg" ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Tools named on the command line are installed even if the tool's directory
# does not exist yet. With no names, only tools already present are touched.
explicit=true
if [ -z "$tools" ]; then
  explicit=false
  tools="$ALL_TOOLS"
fi

if [ "$uninstall" = false ] && [ ! -f "$SRC_DIR/SKILL.md" ]; then
  echo "Cannot find $SRC_DIR/SKILL.md. Run this script from a full copy of the repository." >&2
  exit 1
fi

changed=0
for tool in $tools; do
  home="$(tool_home "$tool")"
  target="$home/skills/$SKILL_NAME"

  if [ "$uninstall" = true ]; then
    if [ -e "$target" ] || [ -L "$target" ]; then
      rm -rf "$target"
      echo "Removed    $tool: $target"
      changed=$((changed + 1))
    else
      echo "Not found  $tool: $target"
    fi
    continue
  fi

  if [ "$explicit" = false ] && [ ! -d "$home" ]; then
    echo "Skipped    $tool: $home does not exist (run './install.sh $tool' to install anyway)"
    continue
  fi

  mkdir -p "$home/skills"
  # Replace any earlier copy so files removed from the skill do not linger.
  rm -rf "$target"
  cp -R "$SRC_DIR" "$target"
  echo "Installed  $tool: $target"
  changed=$((changed + 1))
done

if [ "$uninstall" = false ]; then
  if [ "$changed" -eq 0 ]; then
    echo "Nothing installed: no supported tool was found. Name one explicitly, for example './install.sh claude'." >&2
    exit 1
  fi
  echo "Done. Start a new session in each tool so it picks up the skill."
fi
