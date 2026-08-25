--- MiTeX - Filter Module
--- @module "mitex"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Convert LaTeX maths to Typst via the MiTeX package.
--- @description DisplayMath blocks become `#mimath(...)` and InlineMath
---   becomes `#mi(...)`. The `#import "@preview/mitex:0.2.6": *` statement
---   is injected once in the header when any maths element has been seen.

local M = {}

--- Tracks whether any maths element has been processed.
local has_math = false

--- Check whether a Para contains a single DisplayMath element.
--- @param el pandoc.Para
--- @return boolean
function M.is_display_math(el)
  return #el.content == 1
    and el.content[1].t == 'Math'
    and el.content[1].mathtype == 'DisplayMath'
end

--- Replace a Para containing a single DisplayMath with raw Typst MiTeX.
--- @param el pandoc.Para
--- @return pandoc.RawBlock|nil
function M.process_para(el)
  if not quarto.doc.is_format('typst') then
    return nil
  end
  if M.is_display_math(el) then
    has_math = true
    return pandoc.RawBlock('typst', '#mimath(`\n' .. el.content[1].text .. '\n`)')
  end
end

--- Replace inline maths with raw Typst MiTeX calls.
--- @param el pandoc.Math
--- @return pandoc.RawInline|nil
function M.process_math(el)
  if not quarto.doc.is_format('typst') then
    return nil
  end
  if el.mathtype == 'InlineMath' then
    has_math = true
    return pandoc.RawInline('typst', '#mi(`' .. el.text .. '`)')
  end
end

--- Emit the MiTeX import once in the document header.
--- @param _ pandoc.Pandoc
function M.finalise(_)
  if has_math then
    quarto.doc.include_text('in-header', '#import "@preview/mitex:0.2.6": *')
  end
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Para = M.process_para,
  Math = M.process_math,
  Pandoc = M.finalise,
}

return M
