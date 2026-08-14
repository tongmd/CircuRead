# CircuRead

CircuRead is a small command-line protocol for exchanging early research notes through private GitHub repositories. A delivery contains the note, its routing metadata, a review template, and signed Git history.

[English](README.md) | [中文](README_CN.md)

> Status: experimental. Use it for trusted research groups, inspect every imported review, and keep the idea repository private.

## What works

- `circuread new` scaffolds a LaTeX note and metadata.
- `circuread deliver` creates or reuses one private exchange repository per author and reviewer.
- Every delivery receives a stable UUID and lives under `deliveries/<uuid>/`.
- `circuread review` edits a separate `review.tex` and requires a signed commit.
- `circuread fetch` imports reviews under `.circuread/reviews/` without overwriting the source note.
- `circuread route` updates reviewer metadata without interpolating user input into a `yq` expression.
- `circuread doctor` checks dependencies, GitHub authentication, signing, and configuration.

Git signatures make later changes detectable; they do not make a GitHub repository literally immutable.

## Requirements

- Bash 4 or newer
- Git
- [GitHub CLI](https://cli.github.com/) authenticated with `gh auth login`
- [mikefarah/yq](https://github.com/mikefarah/yq) version 4
- A configured Git signing key. GPG and SSH signing are both supported by Git.

Check the environment:

```bash
circuread doctor
```

## Install

```bash
git clone https://github.com/tongmd/CircuRead.git
cd CircuRead
install -m 0755 circuread "$HOME/.local/bin/circuread"
```

Make sure `$HOME/.local/bin` is on `PATH`. To create a new private idea repository and install the CLI in one step:

```bash
./bootstrap.sh YOUR_GITHUB_USER ideas YOUR_EXCHANGE_ORG
```

The exchange organization must allow you to create private repositories and invite collaborators.

## Configure an existing idea repository

Create `.circuread.yml` at the repository root:

```yaml
me: alice
exchange_org: research-exchange
upstreams:
  - bob
```

Create a note:

```bash
circuread new notes/topological-qubits
```

Edit `notes/topological-qubits/note.tex` and its metadata:

```yaml
title: Topological Qubits
writer: alice
readers: []
push_to:
  - bob
  - clara
```

Commit the note in the private idea repository, then deliver it:

```bash
git add notes/topological-qubits
git commit -S -m "Draft topological-qubits"
circuread deliver notes/topological-qubits/note.tex
```

The command prints a value such as:

```text
delivery_id=7da3b87d-5e14-4be0-b882-04bc92f26ad7
```

Each exchange repository is named `<author>__to__<reviewer>`. CircuRead reuses its `main` branch, so repeated deliveries preserve history instead of creating unrelated repositories.

## Review

The reviewer accepts the GitHub invitation, clones the exchange repository, and runs:

```bash
circuread review deliveries/7da3b87d-5e14-4be0-b882-04bc92f26ad7
```

CircuRead opens `review.tex` in `EDITOR`, creates a signed commit, and pushes it.

## Fetch

From the author's private idea repository:

```bash
circuread fetch 7da3b87d-5e14-4be0-b882-04bc92f26ad7
# or import every accessible delivery
circuread fetch --all
```

Imported snapshots are stored at:

```text
.circuread/reviews/<delivery-uuid>/<reviewer>/
```

CircuRead creates a signed local commit but does not push it automatically. Inspect the diff and run `git push` yourself.

## Commands

| Command | Effect |
| --- | --- |
| `doctor` | Validate the local environment and repository |
| `new <dir>` | Scaffold a note without committing it |
| `deliver <note.tex>` | Create a UUID and send signed copies to reviewers |
| `review <delivery-dir>` | Edit, sign, and push `review.tex` |
| `fetch <uuid\|--all>` | Import review snapshots without replacing the note |
| `route <meta> add\|remove <user>` | Safely edit `push_to` |
| `sync` | Prepare exchange repositories listed in `upstreams` |

The legacy `fetch_edges.sh` and `manage_edges.sh` files are compatibility wrappers around `fetch --all` and `sync`.

## Delivery layout

```text
author__to__reviewer/
└── deliveries/
    └── <uuid>/
        ├── delivery.yml
        ├── note.meta.yml
        ├── note.tex
        └── review.tex
```

## Verify signatures

```bash
git log --show-signature --decorate --oneline
```

Reviewers should verify the author fingerprint out of band before trusting a signature. Repository administrators can rewrite Git history, so keep independent clones or protected branches when auditability matters.

## Development

```bash
bash tests/test_cli.sh
bash tests/test_exchange.sh
shellcheck circuread bootstrap.sh fetch_edges.sh manage_edges.sh tests/*.sh
```

Continuous integration runs the same syntax, behavior, and ShellCheck checks.

## License

MIT © 2025–2026 CircuRead contributors
