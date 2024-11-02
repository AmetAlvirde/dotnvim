local status, _ = pcall(vim.cmd, "colorscheme vim")

if not status then
  print("Colorscheme not found")
  return
end


