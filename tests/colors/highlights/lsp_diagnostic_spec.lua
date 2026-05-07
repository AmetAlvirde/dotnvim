-- Stage-2 tracer: lsp_diagnostic.highlights(c) is a pure function.
-- No pre_case / post_case swaps: the module touches no global state.

local T = MiniTest.new_set()

local function make_palette()
  return { bg2 = "#aaa", red = "#f00", yellow = "#ff0", blue = "#00f", cyan = "#0ff" }
end

-- Tracer: proves the section-module shape exists and returns all seven groups.
T["lsp_diagnostic.highlights returns the seven expected groups"] = function()
  package.loaded["colors.highlights.lsp_diagnostic"] = nil
  local lsp_diag = require("colors.highlights.lsp_diagnostic")
  local c = make_palette()

  local result = lsp_diag.highlights(c)

  local expected_keys = {
    "LspReferenceText", "LspReferenceRead", "LspReferenceWrite",
    "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
  }
  for _, key in ipairs(expected_keys) do
    MiniTest.expect.no_equality(result[key], nil)
  end
  -- Exactly seven keys — no bonus groups.
  local count = 0
  for _ in pairs(result) do count = count + 1 end
  MiniTest.expect.equality(count, 7)
end

T["lsp_diagnostic.highlights propagates palette colors into Diagnostic groups"] = function()
  package.loaded["colors.highlights.lsp_diagnostic"] = nil
  local lsp_diag = require("colors.highlights.lsp_diagnostic")
  local c = make_palette()

  local result = lsp_diag.highlights(c)

  MiniTest.expect.equality(result.DiagnosticError.fg, c.red)
  MiniTest.expect.equality(result.DiagnosticWarn.fg,  c.yellow)
  MiniTest.expect.equality(result.DiagnosticInfo.fg,  c.blue)
  MiniTest.expect.equality(result.DiagnosticHint.fg,  c.cyan)
end

T["lsp_diagnostic.highlights propagates bg2 into LspReference groups"] = function()
  package.loaded["colors.highlights.lsp_diagnostic"] = nil
  local lsp_diag = require("colors.highlights.lsp_diagnostic")
  local c = make_palette()

  local result = lsp_diag.highlights(c)

  MiniTest.expect.equality(result.LspReferenceText.bg,  c.bg2)
  MiniTest.expect.equality(result.LspReferenceRead.bg,  c.bg2)
  MiniTest.expect.equality(result.LspReferenceWrite.bg, c.bg2)
end

T["lsp_diagnostic.highlights is pure: two calls return equal but distinct tables"] = function()
  package.loaded["colors.highlights.lsp_diagnostic"] = nil
  local lsp_diag = require("colors.highlights.lsp_diagnostic")
  local c = make_palette()

  local r1 = lsp_diag.highlights(c)
  local r2 = lsp_diag.highlights(c)

  -- Structurally equal.
  MiniTest.expect.equality(r1.DiagnosticError.fg, r2.DiagnosticError.fg)
  MiniTest.expect.equality(r1.LspReferenceText.bg, r2.LspReferenceText.bg)
  -- But distinct table references — each call constructs a fresh table.
  MiniTest.expect.equality(rawequal(r1, r2), false)
end

return T
