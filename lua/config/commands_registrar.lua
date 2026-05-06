local M = {}

local function register(spec)
  local opts = { desc = spec.desc }
  if spec.nargs ~= nil then opts.nargs = spec.nargs end
  if spec.range ~= nil then opts.range = spec.range end
  vim.api.nvim_create_user_command(spec.name, function(cmd_opts)
    local ok, mod = pcall(require, spec.module)
    if not ok then
      vim.notify(
        spec.on_load_error or ("Failed to load " .. spec.module),
        vim.log.levels.ERROR
      )
      return
    end
    local args_table, abort_msg, abort_level
    if spec.args then
      args_table, abort_msg, abort_level = spec.args(cmd_opts)
    else
      args_table = {}
    end
    if args_table == nil and abort_msg ~= nil then
      vim.notify(abort_msg, abort_level or vim.log.levels.WARN)
      return
    end
    if spec.kind == "void" then
      mod[spec.fn](unpack(args_table))
      return
    end
    if spec.kind == "synthesized_notify" then
      local returns = { mod[spec.fn](unpack(args_table)) }
      local msg, level = spec.notify(returns, cmd_opts)
      if msg then
        vim.notify(msg, level or vim.log.levels.INFO)
      end
      return
    end
    local success, msg = mod[spec.fn](unpack(args_table))
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
