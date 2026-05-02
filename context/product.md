> Describes what the product does for users. Domain terms and naming live in
> `ubiquitous-language.md`. This file does not define domain terms.

## Elevator pitch

Problem: nvim config distributions are a one-size-fits-all solution that result
in lack of knowledge on how nvim works, and how to interact with all the
features they ship with. Also prevents a developer to embark in their own
journey of customizing nvim to the deepest level.

Who: Software developer working primarily on web development (React, Lit, web
components, TypeScript) and note-taking via Obsidian.

Gap: The need to create a hyper-custom nvim configuration that I build and know
like the palm of my hand.

Distinction: This is a software excellence practice. To build to the best of my
abilities, the configuration for the piece of software that I interact the most
with: My code/prose editor.

Form / access surface: Neovim configuration loaded as `~/.config/nvim`,
encountered through the `nvim` command and its keymaps, statusline, and theme.

## Intentions

1. Every plugin earns its place; nothing is loaded by default just because a
   distribution included it.
2. Keymaps remain mnemonic and discoverable through their `<leader>` namespace.
3. The configuration stays legible to its author six months from now without a
   re-read of every plugin spec.

## Goals

A configuration that the author can maintain alone, that survives Neovim version
bumps without forensic debugging, and that can be reasoned about in pieces
rather than as a monolith.

## Access surface

The Neovim editor itself. The "logic engine" framing in the process spec maps
imperfectly here — Neovim is the engine, this configuration is a layer of
adapters and customizations on top of it. The access surface is keymaps,
commands, autocmds, and visual surfaces (statusline, theme, neo-tree).

There is no CLI-vs-API choice to make: the surface is fixed by Neovim. What we
control is whether configuration logic is decoupled from the surface in a way
that makes it testable and rearrangeable.

## Work boundaries

- In: editor configuration, plugin selection and tuning, keymaps, theme,
  language tooling for the languages the author writes (TS/JS, Lua, web).
- Out: building plugins from scratch when a maintained one exists; supporting
  languages or workflows the author does not use.

## Generative core

TBD. The durable product-making principle that this configuration must keep
expressing. Grilling prompts to find it:

- Why is this not a fork of a distribution?
- What would feel wrong if violated, even when it would save time?
- What is the configuration optimizing for that distributions cannot?

## Coherence signals

TBD. Qualitative signs that future work still fits. Candidates:

- New keymaps fit the existing `<leader>` mnemonic namespace without inventing a
  new prefix.
- New plugins justify their inclusion against the deletion test: would removing
  this plugin make the config noticeably worse for the author's actual workflow?
- The config remains scannable — `lua/plugins/` is a flat list of single-purpose
  files, not a maze of cross-referencing modules.

## Constraints

- Neovim 0.11.0+ as the runtime.
- Lazy.nvim as the package manager.
- macOS as the primary platform; Linux secondary; Windows unsupported.
- Single-author maintenance — no contributor onboarding burden to design for.
