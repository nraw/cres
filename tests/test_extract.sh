#!/usr/bin/env bash
# Tests for the jq extraction pipeline used by cres.
# Run: bash tests/test_extract.sh
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$ROOT/tests/fixtures"
JQ_FILTER="$ROOT/shell/extract.jq"

fail=0
pass=0

say_fail() { printf 'FAIL: %s\n' "$1" >&2; fail=$((fail + 1)); }
say_pass() { printf 'ok:   %s\n' "$1"; pass=$((pass + 1)); }

assert_eq() {
  local expected="$1" actual="$2" name="$3"
  if [[ "$expected" == "$actual" ]]; then
    say_pass "$name"
  else
    say_fail "$name"
    printf '  expected: %q\n  actual:   %q\n' "$expected" "$actual" >&2
  fi
}

# Run the extractor pipeline against both fixtures.
extract() {
  cat "$FIXTURES"/session-a.jsonl "$FIXTURES"/session-b.jsonl \
    | jq -rc -f "$JQ_FILTER"
}

out="$(extract)"

# 1) Exactly 3 user prompts should survive the filter:
#    session-a: "first real prompt..." and the multiline one
#    session-b: "what does this repo do?"  (the /init slash-command entry is filtered)
line_count=$(printf '%s\n' "$out" | grep -c .)
assert_eq 3 "$line_count" "keeps only real user text prompts"

# 2) Each line must have 5 tab-separated fields.
while IFS= read -r line; do
  nf=$(awk -F'\t' '{print NF}' <<<"$line")
  assert_eq 5 "$nf" "line has 5 TSV fields: ${line:0:60}"
done <<<"$out"

# 3) Base64 field (col 5) round-trips to the original content.
#    The multiline message from session-a should decode back with newlines + tab intact.
multiline_b64=$(awk -F'\t' '/second prompt/ {print $5}' <<<"$out")
decoded=$(printf '%s' "$multiline_b64" | base64 -d)
expected=$'second prompt with\nmultiple lines\nand tabs\there'
assert_eq "$expected" "$decoded" "base64 round-trip preserves newlines and tabs"

# 4) Display field (col 4) strips newlines/tabs for fzf single-line display.
display=$(awk -F'\t' '/second prompt/ {print $4}' <<<"$out")
case "$display" in
  *$'\n'*|*$'\t'*) say_fail "display field is single-line" ;;
  *) say_pass "display field is single-line" ;;
esac

# 5) Slash-command entry is filtered out.
if grep -q '<command-name>' <<<"$out"; then
  say_fail "slash-command entries are filtered"
else
  say_pass "slash-command entries are filtered"
fi

# 6) Tool-result user messages (content is an array) are filtered out.
if grep -q 'tool output here' <<<"$out"; then
  say_fail "tool_result user messages are filtered"
else
  say_pass "tool_result user messages are filtered"
fi

# 7) sessionId and cwd are populated per line.
while IFS=$'\t' read -r ts sid cwd disp b64; do
  [[ -n "$sid" && "$sid" == *-*-*-*-* ]] || say_fail "sessionId looks like a UUID: $sid"
  [[ "$cwd" == /* ]] || say_fail "cwd is absolute: $cwd"
done <<<"$out"
say_pass "sessionId / cwd fields populated"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
