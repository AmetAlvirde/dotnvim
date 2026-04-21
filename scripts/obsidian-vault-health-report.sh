#!/usr/bin/env bash
# Obsidian vault health report (read-only CLI stats → markdown report).
#
# Vault selection uses the same paths as lua/plugins/obsidian.lua. Commands run
# with that directory as cwd so the CLI targets that folder (not a stale vault
# name in the Obsidian app).
#
# Requires: Obsidian running with the CLI enabled; `obsidian` on PATH.
#
# Usage:
#   ./scripts/obsidian-vault-health-report.sh [--stdout | --write[=PATH]] [--vault=NAME]
#   OBSIDIAN_VAULT=cronicasDeUnCorredorComoTu ./scripts/obsidian-vault-health-report.sh --stdout
#
# Output modes:
#   --stdout             Print report to stdout (default).
#   --write[=PATH]       Write report to a file. If PATH is omitted, writes
#                        `./vault-health-YYYY-MM-DD.md` in the current directory.
#
# Vault targeting:
#   --vault=NAME or OBSIDIAN_VAULT=NAME (default: conscium)
#   OBSIDIAN_VAULT_ROOT=/path         Override path (skips name lookup)

set -euo pipefail

VAULT_NAME="${OBSIDIAN_VAULT:-conscium}"
OUTPUT_MODE="stdout" # stdout|write
OUTPUT_PATH=""

usage() {
  cat <<'EOF'
Usage:
  obsidian-vault-health-report.sh [--stdout | --write[=PATH]] [--vault=NAME]

Options:
  --stdout             Print report to stdout (default)
  --write[=PATH]       Write report to PATH. If PATH is omitted, write to:
                       ./vault-health-YYYY-MM-DD.md
  --vault=NAME         Vault key: conscium | cronicasDeUnCorredorComoTu (see lua/config/vaults.lua)
  -h, --help           Show help

  OBSIDIAN_VAULT_ROOT=/abs/path      Use this vault directory (overrides --vault path lookup)
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --stdout)
      OUTPUT_MODE="stdout"
      ;;
    --write)
      OUTPUT_MODE="write"
      OUTPUT_PATH=""
      ;;
    --write=*)
      OUTPUT_MODE="write"
      OUTPUT_PATH="${arg#--write=}"
      ;;
    --vault=*)
      VAULT_NAME="${arg#--vault=}"
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Paths must match lua/config/vaults.lua
resolve_vault_root() {
  case "$VAULT_NAME" in
    conscium) echo "/Users/amet/Writing/conscium" ;;
    cronicasDeUnCorredorComoTu) echo "/Users/amet/2025/work/mycelium/cronicas-de-un-corredor-como-tu" ;;
    *) echo "" ;;
  esac
}

VAULT_ROOT="${OBSIDIAN_VAULT_ROOT:-$(resolve_vault_root)}"
if [[ -z "$VAULT_ROOT" || ! -d "$VAULT_ROOT" ]]; then
  echo "obsidian-vault-health-report: unknown vault name '${VAULT_NAME}' or missing directory." >&2
  echo "Use conscium or cronicasDeUnCorredorComoTu, or set OBSIDIAN_VAULT_ROOT to the vault folder." >&2
  exit 1
fi

# Run CLI from inside the vault so Obsidian resolves this vault by path (matches nvim config).
ocli() {
  (cd "$VAULT_ROOT" && obsidian "$@")
}

REPORT_DATE="$(date +%Y-%m-%d)"
GENERATED_AT="$(date '+%Y-%m-%d %H:%M:%S %z')"
DEFAULT_FILENAME="vault-health-${REPORT_DATE}.md"
if [[ "$OUTPUT_MODE" == "write" && -z "$OUTPUT_PATH" ]]; then
  OUTPUT_PATH="./${DEFAULT_FILENAME}"
fi

run_stat() {
  local out
  if ! out="$(ocli "$@" 2>/dev/null)"; then
    printf '%s' "error"
    return
  fi
  printf '%s' "$(echo "${out}" | tr -d '\r' | sed '/^[[:space:]]*$/d' | tail -n 1)"
}

# Order matters with some CLI builds: use "files total ext=md", not "files ext=md total".
FILES_MD="$(run_stat files total ext=md)"
FOLDERS_TOTAL="$(run_stat folders total)"
ORPHANS_TOTAL="$(run_stat orphans total)"
DEADENDS_TOTAL="$(run_stat deadends total)"
UNRESOLVED_TOTAL="$(run_stat unresolved total)"

TAGS_TOP=""
if TAGS_TOP="$(ocli tags sort=count counts format=tsv 2>/dev/null)"; then
  :
else
  TAGS_TOP="(could not fetch tags — is Obsidian running?)"
fi

render_report() {
  # Use printf '%s\n' '...' when the text starts with '-' (BSD/macOS printf otherwise treats it as an option).
  printf '%s\n' '---'
  printf 'title: "Vault health report"\n'
  printf 'date: "%s"\n' "${REPORT_DATE}"
  printf 'tags: [stats, automated]\n'
  printf '%s\n' '---'
  printf '\n'
  printf '# Vault health (%s)\n' "${VAULT_NAME}"
  printf '\n'
  printf '_Vault path: `%s` — stats via Obsidian CLI (cwd); read-only queries._\n' "${VAULT_ROOT}"
  printf '\n'
  printf '_Generated: %s_\n' "${GENERATED_AT}"
  printf '\n'
  printf '## Summary\n'
  printf '\n'
  printf '| Metric | Value |\n'
  printf '|--------|-------|\n'
  printf '| Markdown files (`files total ext=md`) | %s |\n' "${FILES_MD}"
  printf '| Folders (`folders total`) | %s |\n' "${FOLDERS_TOTAL}"
  printf '| Orphans (`orphans total`) | %s |\n' "${ORPHANS_TOTAL}"
  printf '| Dead ends (`deadends total`) | %s |\n' "${DEADENDS_TOTAL}"
  printf '| Unresolved links (`unresolved total`) | %s |\n' "${UNRESOLVED_TOTAL}"
  printf '\n'
  printf '## Tags (sort=count, counts)\n'
  printf '\n'
  printf '%s\n' '```text'
  printf '%s\n' "${TAGS_TOP}"
  printf '%s\n' '```'
  printf '\n'
  printf '## Next steps\n'
  printf '\n'
  printf '%s\n' '- Orphans / dead ends: link or archive notes as needed.'
  printf '%s\n' '- Unresolved links: fix or remove broken wikilinks.'
  printf '%s\n' "- Re-run this script weekly; same-day \`--write\` overwrites \`vault-health-${REPORT_DATE}.md\` in the output directory."
}

if [[ "$OUTPUT_MODE" == "write" ]]; then
  render_report > "${OUTPUT_PATH}"
  echo "Wrote ${OUTPUT_PATH}"
else
  render_report
fi
