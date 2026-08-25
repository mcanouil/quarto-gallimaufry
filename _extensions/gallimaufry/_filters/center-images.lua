--- Centre Images - Filter Module
--- @module "center-images"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Align standalone images in Typst output.
--- @description Use the `img-align` image attribute or document-level metadata
---   field to wrap standalone images in `#align(...)[...]`. Must run at
---   post-quarto.

local M = {}

local doc_meta = {}

--- Resolve alignment from image attribute or document metadata.
--- @param img pandoc.Image
--- @return string
function M.get_align(img)
  local align = img.attributes['img-align']
  if align ~= nil then
    return align
  end
  local meta_align = doc_meta['img-align']
  if meta_align ~= nil then
    return pandoc.utils.stringify(meta_align)
  end
  return 'center'
end

--- Return the sole image in a Para, ignoring soft breaks and spaces.
--- @param para pandoc.Para
--- @return pandoc.Image|nil
function M.get_sole_image(para)
  local img = nil
  for _, inline in ipairs(para.content) do
    if inline.t == 'Image' then
      if img ~= nil then
        return nil
      end
      img = inline
    elseif inline.t ~= 'SoftBreak' and inline.t ~= 'Space' then
      return nil
    end
  end
  return img
end

--- Capture document metadata for later alignment resolution.
--- @param m pandoc.Meta
function M.capture_meta(m)
  doc_meta = m
end

--- Wrap a standalone image in a Typst alignment block.
--- @param para pandoc.Para
--- @return pandoc.Para|nil
function M.process_para(para)
  if not quarto.doc.is_format('typst') then
    return nil
  end
  local img = M.get_sole_image(para)
  if img == nil then
    return nil
  end
  local align = M.get_align(img)
  local raw_open = pandoc.RawInline('typst', '#align(' .. align .. ')[')
  local raw_close = pandoc.RawInline('typst', ']')
  return pandoc.Para({ raw_open, img, raw_close })
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  { Meta = M.capture_meta },
  { Para = M.process_para },
}

return M
