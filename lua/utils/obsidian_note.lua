local M = {}

function M.link_or_create()
  local ok, obsidian = pcall(require, "obsidian")
  if not ok then
    vim.notify("obsidian.nvim is not available", vim.log.levels.ERROR)
    return
  end

  local client = obsidian.get_client()
  if not client then
    vim.notify("No active Obsidian workspace", vim.log.levels.WARN)
    return
  end

  local util_ok, util = pcall(require, "obsidian.util")
  if not util_ok then
    vim.notify("Failed to load obsidian.util", vim.log.levels.ERROR)
    return
  end

  local viz = util.get_visual_selection()
  if not viz or #viz.lines ~= 1 then
    vim.notify("Select inline text before linking", vim.log.levels.ERROR)
    return
  end

  local selection = viz.selection
  local line = assert(viz.lines[1])

  local function insert_link(note)
    if not note then
      vim.notify("No note provided to link", vim.log.levels.ERROR)
      return
    end
    local new_line = string.sub(line, 1, viz.cscol - 1)
      .. client:format_link(note, { label = selection })
      .. string.sub(line, viz.cecol + 1)

    vim.api.nvim_buf_set_lines(0, viz.csrow - 1, viz.csrow, false, { new_line })
    client:update_ui()
  end

  local function create_and_link_note(input_title)
    local title
    if type(input_title) == "string" then
      title = vim.trim(input_title)
      if title == "" then
        title = nil
      end
    end
    if not title then
      title = selection
    end
    local ok_note, note = pcall(client.create_note, client, { title = title })
    if not ok_note then
      vim.notify(string.format("Failed to create note for “%s”: %s", title, note), vim.log.levels.ERROR)
      return
    end
    if not note or not note.path then
      vim.notify(string.format("Note creation returned invalid result for “%s”", title), vim.log.levels.ERROR)
      return
    end
    if not note.path:is_file() then
      local write_ok, write_err = pcall(function()
        note = client:write_note(note)
      end)
      if not write_ok then
        vim.notify(string.format("Failed to write note for “%s”: %s", title, write_err), vim.log.levels.ERROR)
        return
      end
    end
    vim.notify(string.format("Linked to new note: %s", tostring(note.path)), vim.log.levels.INFO)
    insert_link(note)
  end

  client:resolve_note_async(selection, function(...)
    local notes = { ... }
    vim.schedule(function()
      if #notes == 0 then
        local picker = client:picker()
        if picker then
          local query_mappings = picker:_note_query_mappings() or {}
          query_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(query)
              create_and_link_note(query)
            end,
          }

          local selection_mappings = picker:_note_selection_mappings() or {}
          selection_mappings["<C-y>"] = {
            desc = "new note",
            callback = function(...)
              create_and_link_note(...)
            end,
            fallback_to_query = true,
          }

          local query_mappings2 = picker._note_query_mappings and picker:_note_query_mappings() or {}
          query_mappings2["<C-y>"] = {
            desc = "new note",
            callback = function(query)
              create_and_link_note(query)
            end,
          }

          local selection_mappings2 = picker._note_selection_mappings and picker:_note_selection_mappings() or {}
          selection_mappings2["<C-y>"] = {
            desc = "new note",
            callback = function(...)
              create_and_link_note(...)
            end,
            fallback_to_query = true,
          }

          picker:find_notes({
            prompt_title = string.format("Link “%s” to…", selection),
            no_default_mappings = true,
            query_mappings = query_mappings2,
            selection_mappings = selection_mappings2,
            callback = function(path)
              if not path or path == "" then
                local choice = vim.fn.confirm(
                  string.format("Create new note for “%s”?", selection),
                  "&Create\n&Cancel",
                  1
                )
                if choice == 1 then
                  create_and_link_note(selection)
                end
                return
              end
              local ok_resolve, note2 = pcall(function()
                return client:resolve_note(path, {
                  notes = { max_lines = client.opts.search_max_lines },
                })
              end)
              if not ok_resolve then
                vim.notify(string.format("Failed to resolve note from %s: %s", path, note2), vim.log.levels.ERROR)
                return
              end
              if note2 then
                insert_link(note2)
              else
                vim.notify(string.format("Could not resolve note for path %s", path), vim.log.levels.WARN)
              end
            end,
          })
        else
          local choice = vim.fn.confirm(
            string.format("Create new note for “%s”?", selection),
            "&Yes\n&No",
            1
          )
          if choice == 1 then
            insert_link(client:create_note({ title = selection }))
          else
            vim.notify(string.format("Skipped creating note for “%s”", selection), vim.log.levels.INFO)
          end
        end
      elseif #notes == 1 then
        insert_link(notes[1])
      else
        local picker = client:picker()
        if picker then
          picker:pick_note(notes, {
            prompt_title = string.format("Pick note for “%s”", selection),
            callback = function(note)
              insert_link(note)
            end,
          })
        else
          insert_link(notes[1])
        end
      end
    end)
  end)
end

return M

