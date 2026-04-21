local M = {}

--- Whitespace-separated words: each token is a maximal run of non-whitespace (`%S+`).
--- @param text string
--- @return integer
function M.count_words_whitespace(text)
  local n = 0
  for _ in text:gmatch("%S+") do
    n = n + 1
  end
  return n
end

--- @param bufnr integer
--- @param line1 integer 1-based, inclusive
--- @param line2 integer 1-based, inclusive
--- @return integer
function M.buf_line_range_wordcount(bufnr, line1, line2)
  if line1 < 1 then
    line1 = 1
  end
  local last = vim.api.nvim_buf_line_count(bufnr)
  if line2 > last then
    line2 = last
  end
  if line1 > line2 then
    return 0
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, true)
  return M.count_words_whitespace(table.concat(lines, "\n"))
end

return M
