local T = MiniTest.new_set()
local command = require("utils.macos_codesign.command")

T["resign_command: returns a string for a known path"] = function()
  local result = command.resign_command("/some/path/lazy")
  MiniTest.expect.equality(type(result), "string")
end

T["resign_command: contains find, *.so, and codesign"] = function()
  local result = command.resign_command("/some/path/lazy")
  MiniTest.expect.equality(result:find("find") ~= nil, true)
  MiniTest.expect.equality(result:find("%*%.so") ~= nil, true)
  MiniTest.expect.equality(result:find("codesign") ~= nil, true)
end

T["resign_command: embeds the given lazy_path in the returned string"] = function()
  local path = "/Users/test/.local/share/nvim/lazy"
  local result = command.resign_command(path)
  MiniTest.expect.equality(result:find(path, 1, true) ~= nil, true)
end

return T
