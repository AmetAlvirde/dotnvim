# Issue folder numbers track GitHub issue numbers

_Made during: post 01-test-harness, prior to the next parent issue_
_Scope: product_
_Status: accepted_

Parent-issue and sub-issue folder numbers under `context/cycles/<cycle>/issues/`
take the GitHub issue number assigned to the unit at creation time. They are
not a local sequential counter scoped to the cycle.

`01-harness-foundation` was issue #1 on GitHub, so the first parent issue's
folder happened to look like an ordinary `01-` prefix. The next parent issue
is `13-...` because GitHub has assigned #2 through #12 to other units
(sub-issues, PR-tracking issues, stray work) in the meantime. Sub-issue
folders follow the same rule — `14-...` is the first sub-issue under `13-...`
because GitHub assigned #14 to it.

Folder numbers are therefore **incremental across the whole project but rarely
sequential within a single cycle**. A scan of `issues/` in any non-trivial
cycle will show gaps. The gaps are by design.

## Considered Options

- **Local sequential numbering scoped to the cycle** (rejected). The folder
  name would be a per-cycle index — `01-`, `02-`, `03-` within each cycle,
  restarting from `01-` in the next cycle — with the GitHub issue number
  recorded in a sidecar field inside `issue.md`. Pro: clean, contiguous folder
  listing; cycle structure self-evident from `ls`. Con: every cross-reference
  between the repo and GitHub requires a lookup; the sidecar is a second source
  of truth that drifts as renames happen; pasting a folder path into a PR
  description does not directly identify the issue it implements.
- **GitHub-synced numbering** (accepted). The folder name *is* the GitHub
  reference. No mapping table, no translation step, no drift. A folder path
  pasted into a PR description identifies the issue unambiguously. Cost: gaps
  in the numeric sequence visible to anyone scanning `issues/`.

## Consequence

A future reader looking at `context/cycles/01-test-harness/issues/` will see
`01-harness-foundation/` directly followed by `13-<name>/`. That is not
missing work and not a renumbering bug — it is the GitHub issue number for the
second parent issue of that cycle. Each issue folder still carries its own
`issue.md` and (on closure) `aar.md`, so scope is fully recoverable from the
folder contents without relying on numeric continuity.
