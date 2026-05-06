local M = {}

function M.resign_command(lazy_path)
  return string.format(
    "find %s -name '*.so' -exec codesign -f -s - {} \\; 2>&1",
    lazy_path
  )
end

return M
