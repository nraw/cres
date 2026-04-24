# cres - fzf through Claude Code conversations, cd to the session's cwd, resume it.
# Usage:
#   source /path/to/cres/shell/cres.sh
#   cres [--help | --version | query]
#
# Requires: fzf, jq, and the `claude` CLI on PATH.

cres() {
  local script_dir filter projects
  script_dir="${CRES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)}"
  filter="$script_dir/extract.jq"
  projects="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

  case "${1:-}" in
    -h|--help)
      cat <<'EOF'
cres — fuzzy-search Claude Code conversation history and resume a session

USAGE
  cres [query]

ARGUMENTS
  query    optional initial search string passed to fzf

OPTIONS
  -h, --help     show this help
  --version      show version

KEY BINDINGS
  enter    cd to the session directory and resume with claude --resume
  esc      cancel
  ?        toggle preview pane

ENVIRONMENT
  CRES_DIR              directory containing cres.sh and extract.jq
  CLAUDE_PROJECTS_DIR   override Claude's data dir (default: ~/.claude/projects)
EOF
      return 0
      ;;
    --version)
      local ver_file="$script_dir/../VERSION"
      if [[ -f "$ver_file" ]]; then
        printf 'cres %s\n' "$(cat "$ver_file")"
      else
        printf 'cres (unknown version)\n'
      fi
      return 0
      ;;
  esac

  for bin in fzf jq claude; do
    command -v "$bin" >/dev/null 2>&1 || { printf 'cres: missing dependency: %s\n' "$bin" >&2; return 127; }
  done
  [[ -f "$filter" ]]   || { printf 'cres: extractor not found: %s\n' "$filter" >&2; return 1; }
  [[ -d "$projects" ]] || { printf 'cres: no Claude projects dir: %s\n' "$projects" >&2; return 1; }

  local selection sid cwd
  selection=$(
    find "$projects" -type f -name '*.jsonl' -print0 \
      | xargs -0 -n 20 -P 8 jq -rc -f "$filter" 2>/dev/null \
      | grep -E $'^[0-9]{4}-[0-9]{2}-[0-9]{2}T' \
      | sort -t$'\t' -k1,1 -r \
      | fzf \
          --delimiter=$'\t' \
          --with-nth=1,3,4 \
          --preview='printf %s {5} | base64 -d' \
          --preview-window='right,60%,wrap,border-left' \
          --bind='?:toggle-preview' \
          --bind='ctrl-/:toggle-preview' \
          --header='  enter resume · esc cancel · ? preview' \
          --header-first \
          --color='header:italic:dim,prompt:cyan,pointer:cyan,hl:yellow,hl+:yellow' \
          --prompt='  ' \
          --pointer='▶' \
          --height=90% \
          --reverse \
          --query="${1:-}"
  ) || return 130

  [[ -z "$selection" ]] && return 0

  sid=$(printf '%s' "$selection" | awk -F'\t' '{print $2}')
  cwd=$(printf '%s' "$selection" | awk -F'\t' '{print $3}')

  if [[ ! -d "$cwd" ]]; then
    printf 'cres: original cwd no longer exists: %s\n' "$cwd" >&2
    return 1
  fi

  cd "$cwd" && claude --resume "$sid"
}
