local M = {}

local default_runner = function(cmd)
  local handle = io.popen(cmd)
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end

local runner = default_runner
local cached

function M.set_runner(fn) runner = fn end
function M.reset_runner() runner = default_runner end
function M.refresh() cached = nil end

function M.detect()
  if cached ~= nil then return cached end
  if vim.fn.has("mac") == 1 then
    local out = runner("defaults read -g AppleInterfaceStyle 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  elseif vim.fn.has("unix") == 1 then
    local out = runner("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null")
    cached = (out and out:match("Dark")) and "dark" or "light"
  else
    cached = vim.o.background == "dark" and "dark" or "light"
  end
  return cached
end

return M
