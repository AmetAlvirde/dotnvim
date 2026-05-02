local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local mini_path = vim.fn.stdpath("data") .. "/lazy/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
  io.stderr:write("mini.nvim not installed; run nvim once to let lazy.nvim install plugins\n")
  os.exit(2)
end
vim.opt.rtp:prepend(mini_path)

local spec_files = vim.fn.globpath(root .. "/tests", "**/*_spec.lua", false, true)
if #spec_files == 0 then
  os.exit(0)
end

require("mini.test").setup()
MiniTest.run({
  collect = {
    find_files = function()
      return spec_files
    end,
  },
})
