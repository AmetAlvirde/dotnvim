local M = {}

function M.resign_lazy_plugins()
  if vim.fn.has("mac") ~= 1 then return end
  local command = require("utils.macos_codesign.command")
  local shell   = require("utils.macos_codesign.shell")
  local lazy_path = vim.fn.stdpath("data") .. "/lazy"
  vim.notify("Re-signing plugin .so files for macOS compatibility...", vim.log.levels.INFO)
  shell.run(command.resign_command(lazy_path))
  vim.notify("Done re-signing .so files.", vim.log.levels.INFO)
end

return M
