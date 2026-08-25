--- Suppress Bibliography - Filter Module
--- @module "suppress-bibliography"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Hide the bibliography block in Typst output.
--- @description When `suppress-bibliography: true` is set in the document
---   metadata and `citeproc` is not enabled, inject a Typst show rule
---   before the body to hide the bibliography block while keeping
---   citation references functional.

local M = {}

--- Inject the Typst show rule when the document opts in.
--- @param meta pandoc.Meta
--- @return pandoc.Meta|nil
function M.process_meta(meta)
  if not quarto.doc.is_format('typst') then
    return nil
  end
  if meta['suppress-bibliography'] ~= true then
    return nil
  end
  if meta['citeproc'] == true then
    return nil
  end
  quarto.doc.include_text('before-body', '#show bibliography: none')
  return nil
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Meta = M.process_meta,
}

return M
