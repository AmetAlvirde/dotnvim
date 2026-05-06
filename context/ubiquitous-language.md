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
| Obsidian CLI          | The external command-line tool (`obsidian` binary) that exposes Obsidian operations — tasks, backlinks, search, history, outline, bookmarks — as subcommands consumed by `lua/utils/obsidian_cli/`. | "obsidian-cli" (hyphenated form not used in this repo), "obscli" (internal variable name only) |

## Relationships

- A **vault** is anchored by a **vault root**.
- A **vault-relative path** identifies a note inside a vault, expressed
  relative to that vault's vault root.
- The **Obsidian CLI** operates on notes addressed by **vault-relative
  path**.

## Example dialogue

> **Dev:** "The bookmark parser is returning the absolute path instead of
> the vault-relative one." **Domain expert:** "The Obsidian CLI emits
> absolute paths for bookmarks; the parser has to subtract the vault root
> to recover the vault-relative path. That subtraction is the resolver
> seam introduced in #20."

> **Dev:** "Should `wordcount_current` accept an absolute path or a
> vault-relative one?" **Domain expert:** "Vault-relative. The Obsidian
> CLI takes `path=` arguments as vault-relative paths; if a caller has an
> absolute path, it converts against the vault root first."

> **Dev:** "What if the current buffer is outside any registered vault?"
> **Domain expert:** "There is no vault root that anchors it, so there is
> no vault-relative path to derive. The leaf function returns its
> not-in-a-vault error envelope and the user command notifies."

## Flagged ambiguities

-
