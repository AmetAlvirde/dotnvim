local M = {}

local function default_runner(cmdline)
  local out = vim.fn.systemlist(cmdline)
  local code = vim.v.shell_error
  if code ~= 0 then
    local msg = table.concat(out or {}, "\n")
    if msg == "" then
      msg = string.format("obsidian-cli failed (exit %d). Is Obsidian running and CLI enabled?", code)
    end
    return nil, msg
  end
  return out, nil
end

local runner = default_runner

function M.run(cmdline)
  return runner(cmdline)
end

function M.set_runner(fn)
  runner = fn
end

function M.reset_runner()
  runner = default_runner
end

return M
