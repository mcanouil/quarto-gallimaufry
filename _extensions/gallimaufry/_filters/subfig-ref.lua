--- Subfig Ref - Filter Module
--- @module subfig-ref
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Strip parent prefix from subfigure cross-references.
--- @description At post-quarto, Quarto replaces Div IDs/classes with
---   `__quarto_custom_*` attributes, so the Div handler is not called for
---   custom elements. This filter walks the AST manually via Pandoc and
---   rewrites the in-parent cross-reference forms for HTML and Typst.

local M = {}

--- Check whether a Div is a Quarto FloatRefTarget.
--- @param el pandoc.Div
--- @return boolean
function M.is_float_ref_target(el)
  return el.t == 'Div' and el.attributes['__quarto_custom_type'] == 'FloatRefTarget'
end

--- Check whether a Div contains a nested FloatRefTarget.
--- @param div pandoc.Div
--- @return boolean
function M.has_nested_float_ref(div)
  local found = false
  div:walk({
    Div = function(inner)
      if M.is_float_ref_target(inner) then
        found = true
      end
    end,
  })
  return found
end

--- HTML: strip everything before the opening "(" Str in a quarto-xref Link.
--- @param link pandoc.Link
--- @return pandoc.Link|nil
function M.strip_html_link_prefix(link)
  if not link.classes:includes('quarto-xref') then
    return nil
  end

  local paren_idx = nil
  for i, inline in ipairs(link.content) do
    if inline.t == 'Str' and inline.text:match('^%(') then
      paren_idx = i
      break
    end
  end
  if paren_idx == nil then
    return nil
  end

  local new_content = pandoc.Inlines({})
  for i = paren_idx, #link.content do
    new_content:insert(link.content[i])
  end
  link.content = new_content
  return link
end

--- Typst: replace `#ref(<id>, supplement: [ ... ])` with `#subref(<id>)`.
--- @param inlines pandoc.Inlines
--- @return pandoc.Inlines|nil
function M.strip_typst_prefix(inlines)
  local new = pandoc.Inlines({})
  local i = 1
  local changed = false
  while i <= #inlines do
    local el = inlines[i]
    if el.t == 'RawInline' and el.format == 'typst' then
      local ref_id = el.text:match('^#ref%((<fig%-.->), supplement: %[$')
      if ref_id then
        local j = i + 1
        while j <= #inlines do
          if inlines[j].t == 'RawInline' and inlines[j].format == 'typst' and inlines[j].text:match('^%]%)$') then
            break
          end
          j = j + 1
        end
        if j <= #inlines then
          new:insert(pandoc.RawInline('typst', '#subref(' .. ref_id .. ')'))
          i = j + 1
          changed = true
        else
          new:insert(el)
          i = i + 1
        end
      else
        new:insert(el)
        i = i + 1
      end
    else
      new:insert(el)
      i = i + 1
    end
  end
  if changed then
    return new
  end
  return nil
end

--- Rewrite cross-references inside a parent figure Div.
--- @param div pandoc.Div
--- @return pandoc.Div
function M.process_parent_figure(div)
  if quarto.doc.is_format('html') then
    return div:walk({
      Link = M.strip_html_link_prefix,
    })
  end

  local strip_prefix
  if quarto.doc.is_format('typst') then
    strip_prefix = M.strip_typst_prefix
  else
    return div
  end

  return div:walk({
    Plain = function(plain)
      local result = strip_prefix(plain.content)
      if result then
        plain.content = result
        return plain
      end
      return nil
    end,
    Para = function(para)
      local result = strip_prefix(para.content)
      if result then
        para.content = result
        return para
      end
      return nil
    end,
  })
end

--- Recursively walk blocks rewriting parent-figure cross-references.
--- @param blocks pandoc.Blocks
--- @return boolean
function M.process_blocks(blocks)
  local changed = false
  for i, block in ipairs(blocks) do
    if M.is_float_ref_target(block) and M.has_nested_float_ref(block) then
      blocks[i] = M.process_parent_figure(block)
      changed = true
    elseif block.t == 'Div' then
      if M.process_blocks(block.content) then
        changed = true
      end
    end
  end
  return changed
end

--- Inject format-specific header content for `\subref` / `#subref` support.
--- @param meta pandoc.Meta
--- @return pandoc.Meta|nil
function M.add_header_includes(meta)
  local raw_block = nil

  if quarto.doc.is_format('typst') then
    raw_block = pandoc.RawBlock('typst', [[#let subref(target) = {
  link(target, context {
    let idx = quartosubfloatcounter.at(query(target).first().location()).first() + 1
    [(#numbering("a", idx))]
  })
}]])
  end

  if raw_block == nil then
    return nil
  end

  local includes = meta['header-includes']
  if includes == nil then
    includes = pandoc.MetaList({})
  end
  includes:insert(pandoc.MetaBlocks({ raw_block }))
  meta['header-includes'] = includes
  return meta
end

--- Walk the document, rewriting in-parent subfigure cross-references and
--- injecting format-specific helper definitions.
--- @param doc pandoc.Pandoc
--- @return pandoc.Pandoc|nil
function M.process_pandoc(doc)
  local meta_changed = M.add_header_includes(doc.meta)
  local blocks_changed = M.process_blocks(doc.blocks)
  if meta_changed or blocks_changed then
    return doc
  end
  return nil
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Pandoc = M.process_pandoc,
}

return M
