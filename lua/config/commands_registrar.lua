local M = {}

local function register(spec)
  local opts = { desc = spec.desc }
  if spec.nargs ~= nil then opts.nargs = spec.nargs end
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    local ok, mod = pcall(require, spec.module)
    if not ok then
      vim.notify(
        spec.on_load_error or ("Failed to load " .. spec.module),
        vim.log.levels.ERROR
      )
      return
    end
    local args = spec.args and spec.args(cmd_opts) or {}
    local success, msg = mod[spec.fn](unpack(args))
    if not success then
      vim.notify(msg, vim.log.levels.ERROR)
      return
    end
    if msg and msg ~= "" then
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, opts)
end

M.register = register

return M
