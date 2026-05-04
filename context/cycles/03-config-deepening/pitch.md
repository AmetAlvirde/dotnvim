# Pitch — Cycle 03, Configuration Deepening

Problem: with `utils.obsidian_cli` deepened (cycle 02), the next-largest
sources of friction in this configuration are no longer in `utils/` — they
live in the wiring layer. `lua/config/commands.lua` (366 lines) repeats the
same 14-line `pcall(require, ...)` → call → notify shape across 14 Obsidian
CLI commands. `lua/colors/solarized.lua` (547 lines) is a single highlight
wall plus an unsealed `defaults read AppleInterfaceStyle` shell-out that
fires on every `FocusGained`. `lua/plugins/lualine.lua` reacts to theme
changes through five parallel mechanisms — two autocmds, a 1-second polling
timer, an explicit `:LualineRefresh` user command, and a re-run of
`solarized.setup()` on focus — with stray `print()` debug statements left
in the production path. `lua/config/autocmds.lua` carries 19 lines of macOS
`codesign` shell-out buried among unrelated event handlers.

Who: the maintainer (author), on the next change to any of these files —
adding a new user command, changing how the statusline reacts to a theme
flip, adjusting a highlight group, or fixing a regression in the macOS
re-signing workaround. Cycle 02's harness is now proven across seven
sub-issues; the next module-shape changes in this configuration would be
expected to ship with tests, and the current shapes of these four files
forbid that.

Gap: each of these surfaces has the same underlying defect — the unit of
behavior is not nameable, so it is not testable. A new ObsCLI command means
copying 14 lines of boilerplate, not registering one row. A theme flip
means hoping at least one of five mechanisms catches it, not emitting one
event. A markdown highlight tweak means searching ~430 entries in one table,
not editing one section. The codesign workaround cannot be disabled, tested,
or documented in one place because it has no place. The harness exists from
cycle 01; ADR-0003's four-layer pattern exists from cycle 02; what is missing
is the willingness to apply the same shape-deepening discipline to the
configuration's wiring layer.

Distinction: this cycle treats the four friction surfaces as one cycle of
**general configuration deepening** rather than four unrelated cleanups.
They share a common shape — wiring code that has accreted application logic
in-place — and they share a common deepening move: extract the application
logic behind a public, testable seam, leave the wiring file declarative.
The cycle's coherence comes from that shared move, not from the surfaces
sitting next to each other in the directory tree. Each surface becomes its
own parent issue so the seams can be designed and tested independently;
the cycle's value is that they are designed against the same standard set
by cycles 01 and 02.

Form / access surface: the user-facing access surface — `:ObsCLI*` and
`:Solarized*` commands, the `<leader>` keymaps that invoke them, the
statusline that reflects the active theme, the macOS workflow of opening
Neovim after a system update — must not change. Command names, command
arguments, theme-flip behavior, statusline appearance, and the
re-signing-on-update behavior all stay observably identical across the
cycle. The new surface introduced by the deepening — a command registrar,
a theme-change event with a subscribe seam, named highlight section
modules, an `os_theme.lua` runner seam, a `macos_codesign.lua` utility —
is the access surface for *tests*. Success means each of the four wiring
files shrinks to a declarative spine, and the application logic each one
carried can be exercised by `./tests/run` without a live editing session.
