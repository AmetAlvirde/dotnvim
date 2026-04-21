# Keymaps

## Strategy

Every `<leader>` sequence starts with a **namespace prefix** that names its domain, so the mapping reads like a sentence: `<leader>gc` = "git commit", `<leader>cf` = "code format", `<leader>dd` = "diagnostic display".

Rules:
- One prefix, one purpose — no prefix does double duty.
- LSP go-to keys (`gd`, `gr`, `gi`, etc.) follow Neovim convention and live outside `<leader>`.
- Plugin-internal keymaps (e.g. diffview buffer navigation) keep their defaults since they are context-local and don't pollute the global namespace.
- Insert-mode and operator keys (`<C-s>`, `<C-y>*`, `[`/`]`) are unchanged.

---

## Namespace reference

### `<leader>b` — Buffer

| Key | Action |
|-----|--------|
| `<leader>br` | Reload file from disk (`:e!`) |
| `<leader>bc` | Check if file changed externally (`:checktime`) |

---

### `<leader>c` — Code (LSP)

| Key | Action |
|-----|--------|
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | Format (conform / LSP fallback) |
| `<leader>cm` | Format markdown with hard line breaks (Prettier) |

LSP navigation lives on standard `g*` keys, not under `<leader>c`:

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Hover documentation |
| `<C-k>` (insert) | Signature help |

---

### `<leader>d` — Diagnostics

| Key | Action |
|-----|--------|
| `<leader>dd` | Show diagnostic float |
| `<leader>dl` | Open diagnostics loclist |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

---

### `<leader>e` — Explorer

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle Neo-tree (right side) |

---

### `<leader>f` — Find (Telescope)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files in current directory |
| `<leader>fg` | Find files in git project root |
| `<leader>fb` | Find open buffers (MRU) |
| `<leader>fl` | Switch to last buffer immediately |

---

### `<leader>g` — Git

All git tooling lives under `<leader>g`, grouped by sub-namespace.

#### Fugitive (file-level operations)

| Key | Action |
|-----|--------|
| `<leader>gs` | Git status |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gl` | Git pull |
| `<leader>gb` | Git blame |
| `<leader>gd` | Git diff split |
| `<leader>gw` | Git write — stage current file |
| `<leader>gr` | Git read — checkout current file |

#### LazyGit (TUI)

| Key | Action |
|-----|--------|
| `<leader>gg` | Open LazyGit |
| `<leader>gf` | Open LazyGit filtered |
| `<leader>gF` | Open LazyGit filtered to current file |

#### `<leader>gh` — Hunks (gitsigns)

| Key | Action |
|-----|--------|
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghS` | Stage entire buffer |
| `<leader>ghu` | Undo last stage |
| `<leader>ghR` | Reset entire buffer |
| `<leader>ghp` | Preview hunk |
| `<leader>ghb` | Blame line (full) |
| `<leader>ghd` | Diff this |
| `<leader>ghD` | Diff this ~ |
| `[c` | Previous hunk |
| `]c` | Next hunk |
| `ih` (o/x) | Select hunk (text object) |

#### `<leader>gv` — View (diffview)

| Key | Action |
|-----|--------|
| `<leader>gvo` | Open diffview |
| `<leader>gvc` | Close diffview |
| `<leader>gvh` | File history (all files) |
| `<leader>gvf` | File history (current file) |
| `<leader>gvr` | Refresh diffview |

---

### `<leader>o` — Obsidian

#### Workspaces

| Key | Action |
|-----|--------|
| `<leader>oc` | Enter conscium workspace |
| `<leader>or` | Enter cronicasDeUnCorredorComoTu workspace |

#### Notes

| Key | Action |
|-----|--------|
| `<leader>on` | New note |
| `<leader>oo` | Open note |
| `<leader>os` | Search notes |
| `<leader>oq` | Quick switch |
| `<leader>of` | Follow link |
| `<leader>ob` | Show backlinks |
| `<leader>ot` | View tags |
| `<leader>op` | Paste image |
| `<leader>om` | Rename note |
| `<leader>od` | Delete note |
| `<leader>ol` (visual) | Link or create note from selection |
| `<leader>ch` | Toggle checkbox |
| `gf` | Follow markdown/wiki link |

---

### `<leader>t` — Theme & Toggles

| Key | Action |
|-----|--------|
| `<leader>tt` | Toggle Solarized light/dark |
| `<leader>td` | Set Solarized dark |
| `<leader>tl` | Set Solarized light |
| `<leader>tr` | Refresh lualine theme |
| `<leader>tb` | Toggle inline git blame |
| `<leader>tx` | Toggle showing deleted lines (gitsigns) |

---

### `<leader>w` — Windows

| Key | Action |
|-----|--------|
| `<leader>ww` | Focus other window |
| `<leader>wd` | Close window |
| `<leader>w-` | Split below |
| `<leader>w\|` | Split right |
| `<leader>-` | Split below (shorthand) |
| `<leader>\|` | Split right (shorthand) |

---

### `<leader><tab>` — Tabs

| Key | Action |
|-----|--------|
| `<leader><tab><tab>` | New tab |
| `<leader><tab>]` | Next tab |
| `<leader><tab>[` | Previous tab |
| `<leader><tab>f` | First tab |
| `<leader><tab>l` | Last tab |
| `<leader><tab>d` | Close tab |

---

### `<leader>q` — Quit

| Key | Action |
|-----|--------|
| `<leader>qq` | Quit all |

---

## Global / always-on keys

| Key | Mode | Action |
|-----|------|--------|
| `<C-s>` | n/i/v/s | Save |
| `<C-S>` | n/i/v/s | Force save |
| `<Esc>` | n/i | Clear search highlight |
| `<leader>ur` | n | Redraw / clear highlight / diff update |
| `]q` / `[q` | n | Next / previous quickfix |
| `<C-h/j/k/l>` | n | Navigate windows / tmux panes |
| `<C-↑/↓/←/→>` | n | Resize window |
| `<` / `>` | v | Indent (keep selection) |
| `,` `.` `;` | i | Undo break-points |

---

## Emmet (insert mode, `<C-y>` prefix)

| Key | Action |
|-----|--------|
| `<C-y>,` | Expand abbreviation |
| `<C-y>;` | Expand word |
| `<C-y>d` / `D` | Balance tag inward / outward |
| `<C-y>n` / `N` | Move to next / previous edit point |
| `<C-y>j` | Split/join tag |
| `<C-y>k` | Remove tag |
| `<C-y>/` | Toggle comment |
| `<C-y>a` / `A` | Anchorize URL / summary |
| `<C-y>m` | Merge lines |
| `<C-y>c` | Pretty code |
| `<C-y>i` / `I` | Update / encode image |
