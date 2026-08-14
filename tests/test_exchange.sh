#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$ROOT_DIR/circuread"
TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/bin" "$TEST_DIR/remotes"

ssh-keygen -q -t ed25519 -N '' -f "$TEST_DIR/signing_key"
PUBLIC_KEY=$(cat "$TEST_DIR/signing_key.pub")
printf 'tester@example.com %s\n' "$PUBLIC_KEY" > "$TEST_DIR/allowed_signers"

cat > "$TEST_DIR/gitconfig" <<EOF
[user]
    name = CircuRead Test
    email = tester@example.com
    signingkey = $TEST_DIR/signing_key
[commit]
    gpgsign = true
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = $TEST_DIR/allowed_signers
[init]
    defaultBranch = main
EOF

cat > "$TEST_DIR/bin/yq" <<'EOF'
#!/usr/bin/env bash
case "${2:-}" in
  '.me // ""') echo alice ;;
  '.exchange_org // ""') echo exchange ;;
  '.push_to[]? // empty') echo bob ;;
  '.upstreams[]? // empty') echo bob ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/bin/yq"

cat > "$TEST_DIR/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

remote_path() {
  local full="$1"
  printf '%s/%s.git\n' "$GH_REMOTE_ROOT" "${full//\//--}"
}

case "${1:-} ${2:-}" in
  "auth status")
    exit 0
    ;;
  "repo view")
    [[ -d "$(remote_path "$3")" ]]
    ;;
  "repo create")
    remote=$(remote_path "$3")
    mkdir -p "$(dirname "$remote")"
    git init -q --bare --initial-branch=main "$remote"
    ;;
  "repo clone")
    remote=$(remote_path "$3")
    git clone -q "$remote" "$4"
    ;;
  "repo list")
    org="$3"
    prefix="${org}--"
    for remote in "$GH_REMOTE_ROOT"/"$org"--*.git; do
      [[ -d "$remote" ]] || continue
      name=$(basename "$remote" .git)
      printf '%s\n' "${name#"$prefix"}"
    done
    ;;
  "api -X")
    exit 0
    ;;
  *)
    echo "unexpected gh call: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$TEST_DIR/bin/gh"

cat > "$TEST_DIR/bin/review-editor" <<'EOF'
#!/usr/bin/env bash
printf '\nReviewed in the integration test.\n' >> "$1"
EOF
chmod +x "$TEST_DIR/bin/review-editor"

export PATH="$TEST_DIR/bin:$PATH"
export GH_REMOTE_ROOT="$TEST_DIR/remotes"
export GIT_CONFIG_GLOBAL="$TEST_DIR/gitconfig"

gh auth status

mkdir -p "$TEST_DIR/ideas/notes/test"
cd "$TEST_DIR/ideas"
git init -q

cat > .circuread.yml <<'EOF'
me: alice
exchange_org: exchange
upstreams:
  - bob
EOF

cat > notes/test/note.tex <<'EOF'
\documentclass{article}
\begin{document}
A testable idea.
\end{document}
EOF

cat > notes/test/note.meta.yml <<'EOF'
title: Testable Idea
writer: alice
readers: []
push_to:
  - bob
EOF

git add .
git commit -q -S -m "Create test note"

FIRST_OUTPUT=$(bash "$CLI" deliver notes/test/note.tex)
FIRST_ID=$(sed -n 's/^delivery_id=//p' <<<"$FIRST_OUTPUT")
[[ "$FIRST_ID" =~ ^[0-9a-f-]{36}$ ]]

SECOND_OUTPUT=$(bash "$CLI" deliver notes/test/note.tex)
SECOND_ID=$(sed -n 's/^delivery_id=//p' <<<"$SECOND_OUTPUT")
[[ "$SECOND_ID" =~ ^[0-9a-f-]{36}$ ]]
[[ "$FIRST_ID" != "$SECOND_ID" ]]

EDGE_REMOTE="$TEST_DIR/remotes/exchange--alice__to__bob.git"
[[ "$(git --git-dir="$EDGE_REMOTE" rev-list --count main)" -eq 2 ]]

git clone -q "$EDGE_REMOTE" "$TEST_DIR/reviewer"
EDITOR="$TEST_DIR/bin/review-editor" \
  bash "$CLI" review "$TEST_DIR/reviewer/deliveries/$FIRST_ID"

BEFORE_NOTE=$(sha256sum notes/test/note.tex | awk '{print $1}')
bash "$CLI" fetch "$FIRST_ID"
AFTER_NOTE=$(sha256sum notes/test/note.tex | awk '{print $1}')

[[ "$BEFORE_NOTE" == "$AFTER_NOTE" ]]
grep -q 'Reviewed in the integration test' \
  ".circuread/reviews/$FIRST_ID/bob/review.tex"

echo "CircuRead exchange integration test passed."
