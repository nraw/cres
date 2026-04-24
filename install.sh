#!/usr/bin/env bash
# One-shot installer for cres.
# Usage: curl -fsSL https://raw.githubusercontent.com/nraw/cres/main/install.sh | bash
set -euo pipefail

REPO="${CRES_REPO:-https://github.com/nraw/cres}"
INSTALL_DIR="${CRES_INSTALL_DIR:-$HOME/.cres}"
BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)

step() { printf '%s==>%s %s\n' "$BOLD$GREEN" "$RESET" "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

for dep in fzf jq claude git; do
  command -v "$dep" >/dev/null 2>&1 || die "missing dependency: $dep"
done

step "Installing cres to $INSTALL_DIR"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" pull --ff-only --quiet
  step "Updated existing install"
else
  git clone --depth 1 --quiet "$REPO" "$INSTALL_DIR"
fi

VERSION=$(cat "$INSTALL_DIR/VERSION")

detect_rc() {
  if [[ "${SHELL##*/}" == "zsh" ]]; then
    echo "${ZDOTDIR:-$HOME}/.zshrc"
  elif [[ "${SHELL##*/}" == "bash" ]]; then
    echo "$HOME/.bashrc"
  else
    echo "$HOME/.profile"
  fi
}

RC=$(detect_rc)
SOURCE_LINE="source \"$INSTALL_DIR/shell/cres.sh\""
EXPORT_LINE="export CRES_DIR=\"$INSTALL_DIR/shell\""

if grep -qF 'cres.sh' "$RC" 2>/dev/null; then
  step "Shell rc already configured ($RC)"
else
  {
    printf '\n# cres %s\n' "$VERSION"
    printf '%s\n' "$EXPORT_LINE"
    printf '%s\n' "$SOURCE_LINE"
  } >> "$RC"
  step "Added cres to $RC"
fi

step "cres $VERSION ready — restart your shell or run: source $RC"
