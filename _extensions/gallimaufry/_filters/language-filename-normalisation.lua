--- Language Filename Normalisation - Filter Module
--- @module "language-filename-normalisation"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Normalise unknown code block languages to "default" while
---   preserving the original language as a filename attribute.
--- @description A code block whose first class is not a known Pandoc
---   language is retagged as `default` and, if no `filename` attribute is
---   set, the original class value is promoted to `filename`.

local M = {}

local known_language_cache = {}

--- Probe Pandoc's highlighter by rendering a test block to HTML.
--- @param lang string
--- @return boolean
function M.is_known_language(lang)
  if not lang or lang == '' then
    return false
  end

  if known_language_cache[lang] ~= nil then
    return known_language_cache[lang]
  end

  local test_block = pandoc.CodeBlock('x', pandoc.Attr('', { lang }))
  local html = pandoc.write(pandoc.Pandoc({ test_block }), 'html')
  local is_known = html:find('sourceCode') ~= nil
  known_language_cache[lang] = is_known
  return is_known
end

--- Retag unknown languages to `default` and preserve the original name
--- as a filename when one is not already set.
--- @param block pandoc.CodeBlock
--- @return pandoc.CodeBlock
function M.process_code_block(block)
  if not block.classes or #block.classes == 0 then
    block.classes:insert('default')
    block.attributes['code-window-no-auto-filename'] = 'true'
    return block
  end

  local lang = block.classes[1]
  if not M.is_known_language(lang) then
    block.classes[1] = 'default'
    if not block.attributes['filename'] or block.attributes['filename'] == '' then
      block.attributes['filename'] = lang
    end
  end

  return block
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  CodeBlock = M.process_code_block,
}

return M
