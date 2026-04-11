--- Multicolumn - Filter Module
--- @module multicolumn
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Span tables across columns in Typst output.
--- @description When a Table inside a `quarto-scaffold` Div has a
---   `.multicolumn` class variant, inject `scope: "parent"` and `placement`
---   into the generated Typst `#figure()` call so the figure spans all
---   columns. Supported classes:
---     .multicolumn        - placement: auto
---     .multicolumn-top    - placement: top
---     .multicolumn-bottom - placement: bottom

local M = {}

local FIGURE_OPEN = '#figure('

--- Mapping of multicolumn class names to Typst placement values.
M.MULTICOLUMN_CLASSES = {
  ['multicolumn'] = 'auto',
  ['multicolumn-top'] = 'top',
  ['multicolumn-bottom'] = 'bottom',
}

--- Rewrite the Typst `#figure(` opening with scope/placement hints.
--- @param div pandoc.Div
--- @return pandoc.Div|nil
function M.process_div(div)
  if not quarto.doc.is_format('typst') then
    return nil
  end

  if not div.classes:includes('quarto-scaffold') then
    return nil
  end

  local placement = nil
  for _, block in ipairs(div.content) do
    if block.t == 'Table' then
      for cls, val in pairs(M.MULTICOLUMN_CLASSES) do
        if block.classes:includes(cls) then
          placement = val
          block.classes = block.classes:filter(function(c)
            return c ~= cls
          end)
          break
        end
      end
      break
    end
  end

  if placement == nil then
    return nil
  end

  for _, block in ipairs(div.content) do
    if block.t == 'Plain' then
      for _, inline in ipairs(block.content) do
        if inline.t == 'RawInline'
          and inline.format == 'typst'
          and inline.text == FIGURE_OPEN .. '['
        then
          inline.text = FIGURE_OPEN
            .. 'scope: "parent", placement: '
            .. placement
            .. ', ['
          return div
        end
      end
    end
  end

  return nil
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Div = M.process_div,
}

return M
