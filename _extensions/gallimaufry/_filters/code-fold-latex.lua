--- Code Fold LaTeX - Filter Module
--- @module code-fold-latex
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Drop code-fold blocks when rendering to LaTeX.
--- @description LaTeX does not support the `code-fold` UI, so code blocks
---   carrying the `code-fold` attribute are removed entirely.

local M = {}

--- Remove code blocks tagged with `code-fold`.
--- Returns an empty table to remove the element, or nil to leave it unchanged.
--- No-op when the output format is not LaTeX.
--- @param el pandoc.CodeBlock
--- @return table|nil
function M.process_code_block(el)
  if not quarto.doc.is_format('latex') then
    return nil
  end
  if el.attributes['code-fold'] then
    return {}
  end
  return nil
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  { CodeBlock = M.process_code_block },
}

return M
