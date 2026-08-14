#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$ROOT_DIR/circuread"

for script in \
  "$ROOT_DIR/circuread" \
  "$ROOT_DIR/bootstrap.sh" \
  "$ROOT_DIR/fetch_edges.sh" \
  "$ROOT_DIR/manage_edges.sh"; do
  bash -n "$script"
done

HELP_OUTPUT=$(bash "$CLI" --help)
grep -q "circuread deliver" <<<"$HELP_OUTPUT"
[[ "$(bash "$CLI" --version)" == "circuread 0.2.0" ]]

if bash "$CLI" definitely-not-a-command >/dev/null 2>&1; then
  echo "unknown commands must fail" >&2
  exit 1
fi

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin"

cat > "$TEST_DIR/bin/yq" <<'EOF'
#!/usr/bin/env bash
case "${2:-}" in
  '.me // ""') echo alice ;;
  '.exchange_org // ""') echo research-exchange ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/bin/yq"

(
  cd "$TEST_DIR"
  git init -q
  cat > .circuread.yml <<'EOF'
me: alice
exchange_org: research-exchange
upstreams: []
EOF

  PATH="$TEST_DIR/bin:$PATH" bash "$CLI" new notes/test
  [[ -f notes/test/note.tex ]]
  [[ -f notes/test/note.meta.yml ]]
  grep -q '^writer: alice$' notes/test/note.meta.yml

  if PATH="$TEST_DIR/bin:$PATH" bash "$CLI" new ../escape >/dev/null 2>&1; then
    echo "new must reject parent-directory traversal" >&2
    exit 1
  fi
)

echo "CircuRead CLI tests passed."
