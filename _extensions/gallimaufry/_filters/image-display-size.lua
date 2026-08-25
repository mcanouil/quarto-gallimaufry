--- Image Display Size - Filter Module
--- @module "image-display-size"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Move width/height from a cell div onto the nested image.
--- @description When a `.cell` div carries `width`/`height` attributes,
---   push them down to the `<img>` inside the nested `.cell-output-display`
---   div and clear them from the parent.

local M = {}

--- Relocate width/height attributes from cell div onto the nested image.
--- @param div pandoc.Div
--- @return pandoc.Div|nil
function M.process_div(div)
  if not div.classes:includes('cell') then
    return nil
  end

  local width = div.attributes['width']
  local height = div.attributes['height']

  if not (width or height) then
    return nil
  end

  local modified = false

  for i, el in ipairs(div.content) do
    if el.t == 'Div' and el.classes:includes('cell-output-display') then
      div.content[i] = pandoc.walk_block(el, {
        Image = function(img)
          img.attributes['width'] = width
          img.attributes['height'] = height
          modified = true
          return img
        end,
      })
    end
  end

  if modified then
    div.attributes['width'] = nil
    div.attributes['height'] = nil
  end

  return div
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Div = M.process_div,
}

return M
