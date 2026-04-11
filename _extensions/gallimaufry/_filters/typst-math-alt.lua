--- Typst Math Alt - Filter Module
--- @module typst-math-alt
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Emit `#math.equation(alt: ...)` for Math wrapped in an element
---   carrying an `alt` attribute.
--- @description Quarto already generates `math.equation(alt: ...)` for
---   display equations with a cross-reference label, but equations that
---   only have `{alt="..."}` (no label) lose their alt text in Typst
---   output. This filter intercepts Span and Div elements with an `alt`
---   attribute that contain a Math element and emits explicit Typst raw
---   content.

local M = {}

--- Escape a Lua string so it can be embedded in a Typst string literal.
--- @param s string
--- @return string
function M.escape_typst_string(s)
  return s:gsub('\\', '\\\\'):gsub('"', '\\"')
end

--- Serialise a Pandoc Math element to its Typst representation.
--- @param math_el pandoc.Math
--- @return string
function M.math_to_typst(math_el)
  local doc = pandoc.Pandoc({ pandoc.Para({ math_el }) })
  local raw = pandoc.write(doc, 'typst')
  return raw:match('^%s*(.-)%s*$')
end

--- Locate the (single) Math child inside an element.
--- @param el pandoc.Span|pandoc.Div
--- @return pandoc.Math|nil
function M.find_math(el)
  local math_el = nil
  el:walk({
    Math = function(m)
      math_el = m
    end,
  })
  return math_el
end

--- Build the Typst raw content for an element whose Math child carries alt.
--- @param math_el pandoc.Math
--- @param alt string
--- @return pandoc.RawBlock|pandoc.RawInline
function M.build_raw(math_el, alt)
  local typst_math = M.math_to_typst(math_el)
  local escaped_alt = M.escape_typst_string(alt)

  if math_el.mathtype == 'DisplayMath' then
    return pandoc.RawBlock(
      'typst',
      '#math.equation(block: true, alt: "' .. escaped_alt .. '", [ ' .. typst_math .. ' ])'
    )
  end
  return pandoc.RawInline(
    'typst',
    '#math.equation(alt: "' .. escaped_alt .. '", ' .. typst_math .. ')'
  )
end

--- Handle Span/Div wrappers; returns nil if nothing to rewrite.
--- @param el pandoc.Span|pandoc.Div
--- @return pandoc.RawBlock|pandoc.RawInline|nil
function M.process_wrapper(el)
  if not quarto.doc.is_format('typst') then
    return nil
  end
  local alt = el.attributes['alt']
  if alt == nil then
    return nil
  end
  local math_el = M.find_math(el)
  if math_el == nil then
    return nil
  end
  return M.build_raw(math_el, alt)
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Span = M.process_wrapper,
  Div = M.process_wrapper,
}

return M
