local M = {}

function M.highlights(c)
  return {
    LspReferenceText  = { bg = c.bg2 },
    LspReferenceRead  = { bg = c.bg2 },
    LspReferenceWrite = { bg = c.bg2 },
    DiagnosticError   = { fg = c.red },
    DiagnosticWarn    = { fg = c.yellow },
    DiagnosticInfo    = { fg = c.blue },
    DiagnosticHint    = { fg = c.cyan },
  }
end

return M
