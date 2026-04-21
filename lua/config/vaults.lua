local M = {}

-- Single source of truth for Obsidian vault/workspace definitions.
-- Consumers:
-- - lua/plugins/obsidian.lua (obsidian.nvim workspaces)
-- - lua/utils/obsidian_cli.lua (vault root resolution)
-- - lua/config/keymaps.lua (workspace switching)

M.vaults = {
  conscium = {
    name = "conscium",
    path = "/Users/amet/Writing/conscium",
  },
  cronicasDeUnCorredorComoTu = {
    name = "cronicasDeUnCorredorComoTu",
    path = "/Users/amet/2025/work/mycelium/cronicas-de-un-corredor-como-tu",
  },
}

-- obsidian.nvim expects an array of { name, path }.
M.workspaces = {
  { name = M.vaults.conscium.name, path = M.vaults.conscium.path },
  { name = M.vaults.cronicasDeUnCorredorComoTu.name, path = M.vaults.cronicasDeUnCorredorComoTu.path },
}

function M.get(name)
  return name and M.vaults[name] or nil
end

function M.paths()
  local out = {}
  for _, ws in ipairs(M.workspaces) do
    table.insert(out, ws.path)
  end
  return out
end

return M

