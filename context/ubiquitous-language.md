# DotNVim

> Canonical glossary for this configuration — terms, relationships, example
> dialogue. The product pitch, goals, and constraints live in `product.md`. This
> file does not pitch the product.

<!--
  Terms are added during the Domain Validation Procedure as artifacts are
  written or grilled. Do not pre-populate this file with speculative terms.
  The first cycle's PRD and exploration will surface the real vocabulary.

  Rules for every entry:
  - Be opinionated: when multiple words exist for the same concept, pick one
    and list the rest under "Aliases to avoid".
  - Only include terms a domain expert would use. Skip module names, class
    names, and general programming concepts unless they carry domain-specific
    meaning. The failure mode is a glossary that documents the code rather than
    the domain. Test: would the author use this term when describing the
    configuration's behavior to another developer, or only when reading the
    code?
  - Definitions are one sentence max. Define what the term IS, not what it does.
  - Group terms by natural cluster (lifecycle, actor, concept). One table per
    cluster.
  - Flag conflicts in "Flagged ambiguities" with a clear resolution.
-->

## Terms

### Obsidian-domain (sourced: cycle `02-obsidian-cli` PRD)

| Term                  | Definition                                                                                                                                                                       | Aliases to avoid                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| vault                 | An Obsidian-managed directory tree of Markdown notes; the unit of data this configuration's Obsidian-aware utilities operate over.                                               | "Obsidian directory", "notes folder"                                              |
| vault root            | An absolute filesystem path registered in `lua/config/vaults.lua` that anchors a vault. Used to convert absolute file paths to vault-relative paths.                             | "vault path" (ambiguous with vault-relative path), "vault directory"              |
| vault-relative path   | A note path expressed relative to a vault root, e.g. `inbox/note.md`. The form the Obsidian CLI accepts for `path=` arguments.                                                   | "relative path" (too generic), "rel path", "vault path"                           |
| Obsidian CLI          | The external command-line tool (`obsidian` binary) that exposes Obsidian operations — tasks, backlinks, search, history, outline, bookmarks — as subcommands consumed by `lua/utils/obsidian_cli.lua`. | "obsidian-cli" (hyphenated form not used in this repo), "obscli" (internal variable name only) |

## Relationships

- A **vault** is anchored by a **vault root**.
- A **vault-relative path** identifies a note inside a vault, expressed
  relative to that vault's vault root.
- The **Obsidian CLI** operates on notes addressed by **vault-relative
  path**.

## Example dialogue

<!-- Add 3–5 exchanges once enough terms exist to surface a non-obvious
     boundary. Skip until the glossary has real entries. -->

## Flagged ambiguities

-
