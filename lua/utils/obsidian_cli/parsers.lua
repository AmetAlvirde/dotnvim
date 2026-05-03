local M = {}

local VAULT_ROOTS = require("config.vaults").paths()

--- Resolve a vault-relative path (as returned by the CLI) to an absolute file path.
--- @return string|nil
local function vault_relpath_to_abs(rel)
  if not rel or rel == "" then
    return nil
  end
  rel = vim.trim(rel):gsub("^[\"'](.*)[\"']$", "%1")
  if rel:sub(1, 1) == "/" then
    local stat = vim.loop.fs_stat(rel)
    if stat and stat.type == "file" then
      return vim.loop.fs_realpath(rel) or rel
    end
    return nil
  end
  rel = rel:gsub("^/", ""):gsub("\\", "/")
  for _, root in ipairs(VAULT_ROOTS) do
    local real_root = vim.loop.fs_realpath(root) or root
    local candidate = real_root .. "/" .. rel
    local stat = vim.loop.fs_stat(candidate)
    if stat and stat.type == "file" then
      return vim.loop.fs_realpath(candidate) or candidate
    end
  end
  return nil
end

local function parse_path_line_text(line)
  -- Supports:
  -- 1) `path/to/file.md:123: - [ ] ...`
  -- 2) `path/to/file.md:123 - [ ] ...`
  -- 3) `path/to/file.md\t123\t...` (tsv-ish)
  if not line or line == "" then
    return nil
  end

  local path, lnum, text = line:match("^(.-):(%d+):%s*(.*)$")
  if path and lnum then
    return { path = path, lnum = tonumber(lnum, 10) or 1, text = text }
  end

  path, lnum, text = line:match("^(.-):(%d+)%s+(.*)$")
  if path and lnum then
    return { path = path, lnum = tonumber(lnum, 10) or 1, text = text }
  end

  local parts = vim.split(line, "\t", { plain = true })
  if #parts >= 2 then
    local p = vim.trim(parts[1] or "")
    local n = tonumber(vim.trim(parts[2] or ""), 10)
    if p ~= "" and n then
      local rest = table.concat(vim.list_slice(parts, 3), "\t")
      return { path = p, lnum = n, text = vim.trim(rest) }
    end
  end

  return nil
end

--- Parse `obsidian tasks [todo] verbose` output into quickfix items.
--- @param lines string[]
--- @return table[]
function M.tasks_verbose(lines)
  local items = {}
  local current_file = nil

  for _, line in ipairs(lines or {}) do
    if line and line ~= "" then
      local file_header = vim.trim(line)
      if file_header:match("%.md$") and not file_header:match(":%d+") and not file_header:match("%[%s*[xX %-%?]%s*%]") then
        current_file = file_header
      else
        local parsed = parse_path_line_text(line)
        if not parsed and current_file then
          local lnum, txt = line:match("^%s*(%d+):%s*(.*)$")
          if not lnum then
            lnum, txt = line:match("^%s*(%d+)%s+(.*)$")
          end
          if lnum and txt then
            parsed = { path = current_file, lnum = tonumber(lnum, 10) or 1, text = vim.trim(txt) }
          end
        end

        if parsed then
          local ref = string.format("%s:%d", parsed.path, parsed.lnum)
          table.insert(items, {
            filename = parsed.path,
            lnum = parsed.lnum,
            col = 1,
            text = (parsed.text and parsed.text ~= "") and parsed.text or line,
            user_data = { obsidian_task_ref = ref },
          })
        end
      end
    end
  end

  return items
end

--- Parse `obsidian unresolved verbose` output into quickfix items.
--- @param lines string[]
--- @return table[]
function M.unresolved_verbose(lines)
  local items = {}
  for _, line in ipairs(lines or {}) do
    if line and line ~= "" then
      local parts = vim.split(line, "\t", { plain = true })
      if #parts >= 3 then
        local link = vim.trim(parts[1] or "")
        local count = tonumber(vim.trim(parts[2] or ""), 10)
        local sources = vim.trim(parts[3] or "")

        local first_source = sources:match("^%s*([^,%s]+%.md)%s*[, ]") or sources:match("^%s*([^,%s]+%.md)%s*$")

        if first_source and first_source ~= "" then
          table.insert(items, {
            filename = first_source,
            lnum = 1,
            col = 1,
            text = string.format("%s (count=%s) sources: %s", link, tostring(count or ""), sources),
          })
        else
          table.insert(items, {
            filename = "",
            lnum = 1,
            col = 1,
            text = string.format("%s (count=%s) sources: %s", link, tostring(count or ""), sources),
          })
        end
      end
    end
  end
  return items
end

--- Parse plain path lines (orphans, deadends) into quickfix items.
--- @param lines string[]
--- @return table[]
function M.paths(lines)
  local items = {}
  for _, line in ipairs(lines or {}) do
    local p = vim.trim(line or "")
    if p ~= "" and not p:match("^%s*total%s*$") then
      table.insert(items, {
        filename = p,
        lnum = 1,
        col = 1,
        text = p,
      })
    end
  end
  return items
end

--- Parse `obsidian search:context` output into quickfix items.
--- @param lines string[]
--- @return table[]
function M.search_context(lines)
  local items = {}
  for _, line in ipairs(lines or {}) do
    local parsed = parse_path_line_text(line)
    if parsed and parsed.path and parsed.lnum then
      table.insert(items, {
        filename = parsed.path,
        lnum = parsed.lnum,
        col = 1,
        text = parsed.text ~= "" and parsed.text or line,
      })
    end
  end
  return items
end

--- Decode JSON text and extract backlink rows from it.
--- Returns nil when the text cannot be parsed as JSON.
--- Returns an empty table when parsing succeeds but yields no rows.
--- @param text string raw CLI output joined with newlines
--- @return { path: string, count: integer }[]|nil rows, or nil on parse failure
function M.backlinks_json(text)
  text = vim.trim(text or "")
  if text == "" then
    return nil
  end

  local ok, data = pcall(vim.json.decode, text)
  if not ok or data == nil then
    local start = text:find("[%[%{]")
    if start then
      ok, data = pcall(vim.json.decode, text:sub(start))
    end
    if not ok or data == nil then
      return nil
    end
  end

  local rows = {}

  local function add(path, count)
    path = vim.trim(tostring(path or ""))
    if path == "" then
      return
    end
    count = tonumber(count)
    if not count or count < 1 then
      count = 1
    end
    table.insert(rows, { path = path, count = count })
  end

  local function from_item(item)
    if type(item) == "string" then
      if vim.trim(item) ~= "" then
        add(item, 1)
      end
      return
    end
    if type(item) ~= "table" then
      return
    end
    local p = item.path or item.file or item.filePath or item.filepath or item.source or item.from or item.name
    if type(p) ~= "string" then
      return
    end
    local c = item.count or item.linkCount or item.links or item.total or item.n
    add(p, c)
  end

  if type(data) ~= "table" then
    return rows
  end

  if vim.tbl_islist(data) then
    for _, item in ipairs(data) do
      from_item(item)
    end
    return rows
  end

  local nested = data.backlinks or data.links or data.items or data.results or data.files
  if type(nested) == "table" and vim.tbl_islist(nested) then
    for _, item in ipairs(nested) do
      from_item(item)
    end
    if #rows > 0 then
      return rows
    end
  end

  for k, v in pairs(data) do
    if type(k) == "string" and k:match("%.md") and type(v) == "number" then
      add(k, v)
    elseif type(v) == "table" then
      from_item(v)
    elseif type(v) == "string" and v:match("%.md") then
      add(v, 1)
    end
  end

  return rows
end

--- Pick a note path from a `obsidian bookmarks verbose` line (TSV-ish; paths may be quoted).
--- @return string|nil vault-relative or absolute path to a .md file
function M.extract_bookmark_note_path(line)
  line = line or ""
  local cells = vim.split(line, "\t", { plain = true })
  for _, cell in ipairs(cells) do
    cell = vim.trim(cell):gsub("^[\"'](.*)[\"']$", "%1")
    if cell ~= "" and not cell:match("^https?:") then
      if vault_relpath_to_abs(cell) then
        return cell
      end
      if cell:match("%.md$") then
        return cell
      end
    end
  end
  local md = line:match("([%w%-%._/]+)%.md")
  if md then
    return md .. ".md"
  end
  return nil
end

return M
