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

-- abort-from-args cases.

T["register: args returning (nil, msg, level) emits one notify and skips leaf"] = function()
  local stub_key = "stub.registrar.abort_with_level"
  local leaf_called = false
  package.loaded[stub_key] = {
    run = function() leaf_called = true; return true, "" end,
  }

  register({
    name = "AbortCmd",
    desc = "Abort",
    module = stub_key,
    fn = "run",
    args = function(_) return nil, "abort msg", vim.log.levels.WARN end,
  })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].msg, "abort msg")
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.WARN)
  MiniTest.expect.equality(leaf_called, false)

  package.loaded[stub_key] = nil
end

T["register: args returning (nil, msg) defaults level to WARN"] = function()
  local stub_key = "stub.registrar.abort_default_level"
  local leaf_called = false
  package.loaded[stub_key] = {
    run = function() leaf_called = true; return true, "" end,
  }

  register({
    name = "AbortDefaultCmd",
    desc = "Abort default level",
    module = stub_key,
    fn = "run",
    args = function(_) return nil, "abort msg" end,
  })
  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].msg, "abort msg")
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.WARN)
  MiniTest.expect.equality(leaf_called, false)

  package.loaded[stub_key] = nil
end

-- range forwarding cases.

T["register: forwards spec.range to opts.range"] = function()
  register({
    name = "RangeCmd",
    desc = "A range command",
    module = "utils.does_not_exist",
    fn = "noop",
    range = true,
  })

  MiniTest.expect.equality(#recorded_commands, 1)
  MiniTest.expect.equality(recorded_commands[1].opts.range, true)
end

T["register: omits opts.range when spec.range is nil"] = function()
  register({
    name = "NoRangeCmd",
    desc = "No range command",
    module = "utils.does_not_exist",
    fn = "noop",
  })

  MiniTest.expect.equality(#recorded_commands, 1)
  MiniTest.expect.equality(recorded_commands[1].opts.range, nil)
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

-- kind = "synthesized_notify" cases.

T["register: kind = \"synthesized_notify\" calls notify with leaf returns and emits one notify"] = function()
  local stub_key = "stub.registrar.synth_notify"
  package.loaded[stub_key] = {
    run = function() return 7 end,
  }

  register({
    name = "SynthCmd",
    desc = "Synthesized notify",
    module = stub_key,
    fn = "run",
    kind = "synthesized_notify",
    args = function(_) return { 42 } end,
    notify = function(returns, cmd_opts)
      return "got " .. returns[1] .. " at line " .. cmd_opts.line1, vim.log.levels.INFO
    end,
  })
  recorded_commands[1].callback({ line1 = 3 })

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].msg, "got 7 at line 3")
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.INFO)

  package.loaded[stub_key] = nil
end

T["register: kind = \"synthesized_notify\" still surfaces load failure as ERROR notify"] = function()
  register({
    name = "SynthLoadFailCmd",
    desc = "Synth load fail",
    module = "utils.does_not_exist",
    fn = "noop",
    kind = "synthesized_notify",
    notify = function() error("must not be called") end,
  })

  recorded_commands[1].callback({})

  MiniTest.expect.equality(#recorded_notifies, 1)
  MiniTest.expect.equality(recorded_notifies[1].level, vim.log.levels.ERROR)
  MiniTest.expect.equality(
    recorded_notifies[1].msg,
    "Failed to load utils.does_not_exist"
  )
end

return T
