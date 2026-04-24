



<p align="center">
  <img src="cres.png" alt="cres">
</p>

# cres - Global Claude Resume

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/shell-zsh%20%7C%20bash-green.svg" alt="Shell">
  <img src="https://img.shields.io/badge/requires-fzf%20%7C%20jq%20%7C%20claude-orange.svg" alt="Requires">
</p>

Fuzzy-search your [Claude Code](https://claude.ai/code) conversation history with fzf, then resume the session.

<video src="https://github.com/user-attachments/assets/0aac96d3-a76d-4b20-b3ca-43b74947615c" autoplay loop muted playsinline></video>

Selecting a message `cd`s to the folder where that conversation took place and runs `claude --resume <session>`.

## Requirements

- [`fzf`](https://github.com/junegunn/fzf)
- [`jq`](https://jqlang.org) ≥ 1.6
- [`claude`](https://claude.ai/code) CLI

## Install

**One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/nraw/cres/main/install.sh | bash
```

**Or with make:**
```bash
git clone https://github.com/nraw/cres ~/.cres
make -C ~/.cres install
```

**Or manually:**
```bash
git clone https://github.com/nraw/cres ~/.cres

# add to ~/.zshrc or ~/.bashrc
export CRES_DIR="$HOME/.cres/shell"
source "$CRES_DIR/cres.sh"
```

## Usage

```bash
cres              # open picker, newest conversations first
cres refactor     # open picker pre-filtered to "refactor"
cres --help       # show help
cres --version    # show version
```

### Key bindings inside fzf

| key | action |
|-----|--------|
| `↑` / `↓` | navigate |
| `enter` | cd to session directory and resume |
| `esc` | cancel |
| `?` / `ctrl-/` | toggle preview pane |

The right-hand preview pane shows the full text of the selected message.

## How it works

1. Scans `~/.claude/projects/**/*.jsonl` in parallel
2. Extracts user prompts with `jq`, skips tool-result entries and slash commands
3. Sorts newest-first, opens `fzf`
4. On selection: `cd <cwd> && claude --resume <sessionId>`

## Configuration

| variable | default | purpose |
|---|---|---|
| `CRES_DIR` | dir of `cres.sh` | where `extract.jq` lives |
| `CLAUDE_PROJECTS_DIR` | `~/.claude/projects` | override Claude's data directory |

## Development

```bash
# run tests
make test

# project layout
shell/
  cres.sh       # shell function, source this
  extract.jq    # jq filter: selects real user prompts, emits TSV
tests/
  test_extract.sh
  fixtures/
```

## License

[MIT](LICENSE)
