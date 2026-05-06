local M = {}

local default_runner = function(cmd)
  local handle = io.popen(cmd)
  if handle then handle:close() end
end

local runner = default_runner

function M.run(cmd)
  runner(cmd)
end

function M.set_runner(fn)
  runner = fn
end

function M.reset_runner()
  runner = default_runner
end

return M
