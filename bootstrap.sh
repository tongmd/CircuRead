#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: ./bootstrap.sh <github-user> [idea-repo] [exchange-org]" >&2
}

[[ $# -ge 1 && $# -le 3 ]] || { usage; exit 2; }

ME="$1"
IDEA_REPO="${2:-ideas}"
EXCHANGE_ORG="${3:-circuread-xrepos}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

[[ "$ME" =~ ^[A-Za-z0-9-]+$ ]] || { echo "Invalid GitHub user: $ME" >&2; exit 2; }
[[ "$IDEA_REPO" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Invalid repository name: $IDEA_REPO" >&2; exit 2; }
[[ "$EXCHANGE_ORG" =~ ^[A-Za-z0-9-]+$ ]] || { echo "Invalid exchange organization: $EXCHANGE_ORG" >&2; exit 2; }

for command_name in git gh yq install; do
  command -v "$command_name" >/dev/null 2>&1 ||
    { echo "Missing dependency: $command_name" >&2; exit 1; }
done

gh auth status >/dev/null 2>&1 ||
  { echo "GitHub CLI is not authenticated. Run: gh auth login" >&2; exit 1; }

git config --get user.signingkey >/dev/null 2>&1 ||
  { echo "Configure git user.signingkey before bootstrapping CircuRead." >&2; exit 1; }

[[ ! -e "$IDEA_REPO" ]] ||
  { echo "Local path already exists: $IDEA_REPO" >&2; exit 1; }

if gh repo view "$ME/$IDEA_REPO" >/dev/null 2>&1; then
  echo "GitHub repository already exists: $ME/$IDEA_REPO" >&2
  exit 1
fi

gh repo create "$ME/$IDEA_REPO" --private --clone
cd "$IDEA_REPO"

cat > .circuread.yml <<EOF
me: $ME
exchange_org: $EXCHANGE_ORG
upstreams: []
EOF

mkdir -p notes/demo
cat > notes/demo/note.tex <<'EOF'
\documentclass[11pt]{article}
\usepackage[margin=1in]{geometry}
\title{Demo Note}
\author{}
\date{}

\begin{document}
\maketitle

State the question, evidence, and next experiment here.

\end{document}
EOF

cat > notes/demo/note.meta.yml <<EOF
title: Demo Note
writer: $ME
readers: []
push_to: []
EOF

git add .circuread.yml notes/demo
git commit -S -m "Initialize CircuRead idea repository"
git branch -M main
git push -u origin main

mkdir -p "$HOME/.local/bin"
install -m 0755 "$SCRIPT_DIR/circuread" "$HOME/.local/bin/circuread"

echo "Created private repository $ME/$IDEA_REPO."
echo "Installed circuread at $HOME/.local/bin/circuread."
echo "Add a reviewer to notes/demo/note.meta.yml before delivering."
