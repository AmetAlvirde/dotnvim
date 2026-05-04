local register = require("config.commands_registrar").register

local _orig_create_user_command = vim.api.nvim_create_user_command
local _orig_notify = vim.notify

local recorded_commands
local recorded_notifies

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      recorded_commands = {}
      recorded_notifies = {}
      vim.api.nvim_create_user_command = function(name, cb, opts)
        table.insert(recorded_commands, { name = name, callback = cb, opts = opts })
      end
      vim.notify = function(msg, level)
        table.insert(recorded_notifies, { msg = msg, level = level })
      end
    end,
    post_case = function()
      vim.api.nvim_create_user_command = _orig_create_user_command
      vim.notify = _orig_notify
    end,
  },
})

-- Stage-2 First Contact pair: the seam exists and is wired.

T["register: calls nvim_create_user_command with the spec name and opts.desc"] = function()
  register({
    name = "TestCmd",
    desc = "A test command",
    module = "utils.does_not_exist",
    fn = "noop",
  })

  MiniTest.expect.equality(#recorded_commands, 1)
  MiniTest.expect.equality(recorded_commands[1].name, "TestCmd")
  MiniTest.expect.equality(recorded_commands[1].opts.desc, "A test command")
  MiniTest.expect.equality(type(recorded_commands[1].callback), "function")
end

T["register: registered callback is invocable and runs the pipeline"] = function()
  local stub_key = "stub.registrar.invoke"
  package.loaded[stub_key] = { run = function() return true, "" end }

  register({ name = "InvokeCmd", desc = "Invoke", module = stub_key, fn = "run" })
  MiniTest.expect.equality(#recorded_commands, 1)

  recorded_commands[1].callback({})
  MiniTest.expect.equality(#recorded_notifies, 0)

  package.loaded[stub_key] = nil
end

-- Four callback-branch cases.

T["register: load failure emits one ERROR notify with the default message"] = function()
  register({
    name = "FailCmd",
    desc = "Fail",
    module = "utils.does_not_exist",
    fn = "noop",
  })

  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.ERROR)
  MiniTest.expect.equality(
    recorded_notifies[1].msg,
    "Failed to load utils.does_not_exist"
  )
end

T["register: leaf returns (true, empty string): no notify"] = function()
  local stub_key = "stub.registrar.silent_empty"
  package.loaded[stub_key] = { run = function() return true, "" end }

  register({ name = "SilentCmd", desc = "Silent", module = stub_key, fn = "run" })
  recorded_commands[1].callback({})
  MiniTest.expect.equality(#recorded_notifies, 0)

  package.loaded[stub_key] = nil
end

T["register: leaf returns (true, nil): no notify"] = function()
  local stub_key = "stub.registrar.silent_nil"
  package.loaded[stub_key] = { run = function() return true, nil end }

  register({ name = "NilMsgCmd", desc = "Nil msg", module = stub_key, fn = "run" })
  recorded_commands[1].callback({})
  MiniTest.expect.equality(#recorded_notifies, 0)

  package.loaded[stub_key] = nil
end

T["register: leaf returns (false, msg): one ERROR notify with msg"] = function()
  local stub_key = "stub.registrar.leaf_error"
  package.loaded[stub_key] = { run = function() return false, "boom" end }

  register({ name = "ErrCmd", desc = "Error", module = stub_key, fn = "run" })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.ERROR)
  MiniTest.expect.equality(recorded_notifies[1].msg, "boom")

  package.loaded[stub_key] = nil
end

T["register: leaf returns (true, non-empty msg): one INFO notify with msg"] = function()
  local stub_key = "stub.registrar.leaf_info"
  package.loaded[stub_key] = {
    run = function() return true, "loaded 4 items" end,
  }

  register({ name = "InfoCmd", desc = "Info", module = stub_key, fn = "run" })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.INFO)
  MiniTest.expect.equality(recorded_notifies[1].msg, "loaded 4 items")

  package.loaded[stub_key] = nil
end

-- kind = "void" cases.

T["register: kind = \"void\" calls leaf with unpacked args and emits no notify"] = function()
  local stub_key = "stub.registrar.void_leaf"
  local call_args = nil
  package.loaded[stub_key] = {
    run = function(...)
      call_args = { ... }
    end,
  }

  register({
    name = "VoidCmd",
    desc = "Void",
    module = stub_key,
    fn = "run",
    kind = "void",
    args = function(_) return { "dark" } end,
  })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 0)
  MiniTest.expect.equality(call_args, { "dark" })

  package.loaded[stub_key] = nil
end

T["register: kind = \"void\" discards leaf return value"] = function()
  local stub_key = "stub.registrar.void_discard"
  package.loaded[stub_key] = {
    run = function() return true, "msg that must not fire" end,
  }

  register({
    name = "VoidDiscardCmd",
    desc = "Void discard",
    module = stub_key,
    fn = "run",
    kind = "void",
  })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 0)

  package.loaded[stub_key] = nil
end

T["register: kind = \"void\" still surfaces load failure as ERROR notify"] = function()
  register({
    name = "VoidLoadFailCmd",
    desc = "Void load fail",
    module = "utils.does_not_exist",
    fn = "noop",
    kind = "void",
  })

  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.ERROR)
  MiniTest.expect.equality(
    recorded_notifies[1].msg,
    "Failed to load utils.does_not_exist"
  )
end

-- nargs forwarding cases.

T["register: forwards spec.nargs to opts.nargs"] = function()
  register({
    name = "NargsCmd",
    desc = "A nargs command",
    module = "utils.does_not_exist",
    fn = "noop",
    nargs = "?",
  })

  MiniTest.expect.equality(#recorded_commands, 1)
  MiniTest.expect.equality(recorded_commands[1].opts.nargs, "?")
  MiniTest.expect.equality(recorded_commands[1].opts.desc, "A nargs command")
end

T["register: omits opts.nargs when spec.nargs is nil"] = function()
  register({
    name = "NoNargsCmd",
    desc = "No nargs command",
    module = "utils.does_not_exist",
    fn = "noop",
  })

  MiniTest.expect.equality(#recorded_commands, 1)
  MiniTest.expect.equality(recorded_commands[1].opts.nargs, nil)
end

return T
