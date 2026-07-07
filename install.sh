#!/usr/bin/env bash
#
# EMO-Claude installer
# Adds the emo spinner verbs to your Claude Code settings via the supported
# "spinnerVerbs" key. Non-destructive: backs up settings.json and merges.
#
# Usage:
#   ./install.sh            # append emo verbs to the built-in defaults
#   ./install.sh --replace  # use ONLY emo verbs (drop the defaults)
#   ./install.sh --uninstall# remove the spinnerVerbs block entirely
#
set -euo pipefail

MODE="append"
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --replace)   MODE="replace" ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBS_FILE="$SCRIPT_DIR/verbs.json"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)" >&2; exit 1; }
[ -f "$VERBS_FILE" ] || { echo "error: verbs.json not found next to install.sh" >&2; exit 1; }

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Validate existing settings is real JSON before touching it.
jq empty "$SETTINGS" 2>/dev/null || { echo "error: $SETTINGS is not valid JSON; aborting." >&2; exit 1; }

BACKUP="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$BACKUP"
echo "Backed up settings -> $BACKUP"

TMP="$(mktemp)"
if [ "$UNINSTALL" -eq 1 ]; then
  jq 'del(.spinnerVerbs)' "$SETTINGS" > "$TMP"
  echo "Removed spinnerVerbs."
else
  jq --slurpfile verbs "$VERBS_FILE" --arg mode "$MODE" \
     '.spinnerVerbs = {mode: $mode, verbs: $verbs[0]}' \
     "$SETTINGS" > "$TMP"
  COUNT="$(jq length "$VERBS_FILE")"
  echo "Installed $COUNT emo verbs (mode: $MODE)."
fi

mv "$TMP" "$SETTINGS"
echo "Done. Restart Claude Code to see the new spinner."
