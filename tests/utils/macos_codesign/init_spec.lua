local T = MiniTest.new_set()

local shell = require("utils.macos_codesign.shell")
local macos_codesign = require("utils.macos_codesign")

local _orig_has     = vim.fn.has
local _orig_stdpath = vim.fn.stdpath
local _orig_notify  = vim.notify

local recorded_cmd
local recorded_notifies

T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      recorded_cmd = nil
      recorded_notifies = {}

      vim.fn.has = function(feature)
        if feature == "mac" then return 1 end
        return _orig_has(feature)
      end

      vim.fn.stdpath = function(what)
        if what == "data" then return "/fake/data" end
        return _orig_stdpath(what)
      end

      vim.notify = function(msg, level)
        table.insert(recorded_notifies, { msg = msg, level = level })
      end

      shell.set_runner(function(cmd)
        recorded_cmd = cmd
      end)
    end,
    post_case = function()
      shell.reset_runner()
      vim.fn.has     = _orig_has
      vim.fn.stdpath = _orig_stdpath
      vim.notify     = _orig_notify
    end,
  },
})

T["tracer: module loads through the directory init.lua"] = function()
  local ok, mod = pcall(require, "utils.macos_codesign")
  MiniTest.expect.equality(ok, true)
  MiniTest.expect.equality(type(mod), "table")
end

T["resign_lazy_plugins: runner receives a command containing find, *.so, and codesign"] = function()
  macos_codesign.resign_lazy_plugins()

  MiniTest.expect.equality(type(recorded_cmd), "string")
  MiniTest.expect.equality(recorded_cmd:find("find") ~= nil, true)
  MiniTest.expect.equality(recorded_cmd:find("%*%.so") ~= nil, true)
  MiniTest.expect.equality(recorded_cmd:find("codesign") ~= nil, true)
end

T["resign_lazy_plugins: command contains the derived lazy_path"] = function()
  macos_codesign.resign_lazy_plugins()

  MiniTest.expect.equality(recorded_cmd:find("/fake/data/lazy", 1, true) ~= nil, true)
end

T["resign_lazy_plugins: emits two INFO notifications"] = function()
  macos_codesign.resign_lazy_plugins()

  MiniTest.expect.equality(#recorded_notifies, 2)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.INFO)
  MiniTest.expect.equality(recorded_notifies[2].level, vim.log.levels.INFO)
end

T["resign_lazy_plugins: returns early without calling runner on non-macOS"] = function()
  vim.fn.has = function(feature)
    if feature == "mac" then return 0 end
    return _orig_has(feature)
  end

  macos_codesign.resign_lazy_plugins()

  MiniTest.expect.equality(recorded_cmd, nil)
  MiniTest.expect.equality(#recorded_notifies, 0)
end

return T
