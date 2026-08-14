# CircuRead protocol

CircuRead separates a researcher's working note from the copy sent for review.

## Identities and repositories

- The author keeps the source note in a private idea repository.
- Each author and reviewer pair uses one private exchange repository named `<author>__to__<reviewer>`.
- The author creates the exchange repository and grants the reviewer push access.
- A delivery UUID is shared across all reviewer copies of the same submission.

## Delivery record

Each `deliveries/<uuid>/` directory contains:

- `note.tex`: the submitted snapshot;
- `note.meta.yml`: routing metadata at submission time;
- `delivery.yml`: UUID, author, reviewer, and UTC creation time;
- `review.tex`: a separate review document.

The author signs the delivery commit. The reviewer signs the review commit. A signature proves that a particular Git identity signed particular bytes; trust in that identity still depends on verifying its public key.

## Import rule

`circuread fetch` copies exchange snapshots into:

```text
.circuread/reviews/<uuid>/<reviewer>/
```

It never copies a review over the source `note.tex`. The author can compare, quote, or merge the feedback explicitly.

## Failure and trust boundaries

- A repository administrator can force-push or delete an exchange repository.
- A collaborator can edit more than `review.tex` unless branch rules limit paths.
- GitHub availability and organization policy remain external dependencies.
- Private repositories protect access only as far as GitHub credentials and collaborator permissions do.
- Signed commits make unauthorized edits detectable when the expected keys and earlier commits are available.

For stronger audit requirements, protect `main`, require signed commits, retain independent clones, and verify fingerprints outside GitHub.

