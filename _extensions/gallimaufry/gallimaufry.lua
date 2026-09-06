--- Gallimaufry - Filter
--- @module "gallimaufry"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Toggleable bundle of Pandoc AST filters.
--- @description Loads a per-document subset of filter modules based on
---   `extensions.gallimaufry.*` flags in the document metadata. All
---   modules are opt-in; an empty or missing `extensions.gallimaufry`
---   block leaves the document untouched.

--- Extension name constant
local EXTENSION_NAME = 'gallimaufry'

local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/metadata.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once and reused by the whole render. It reads
--- `_schema.yml` on the way in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcode, so the check runs from
--- the `Meta` handler. There is nowhere else it could run.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Ordered list of bundled module names.
local MODULES = {
  'center-images',
  'code-fold-latex',
  'count-cite',
  'image-display-size',
  'language-filename-normalisation',
  'mitex',
  'multicolumn',
  'repeat-heading',
  'subfig-ref',
  'suppress-bibliography',
  'typst-math-alt',
}

--- Lookup set for module name validation.
local MODULE_SET = {}
for _, name in ipairs(MODULES) do
  MODULE_SET[name] = true
end

--- Activation flags populated from the document metadata in the first pass.
local enabled = {}

--- Convert a MetaValue (or plain Lua value) to a boolean.
--- @param value any
--- @return boolean
local function to_bool(value)
  if value == nil then
    return false
  end
  if type(value) == 'boolean' then
    return value
  end
  return pandoc.utils.stringify(value) == 'true'
end

--- Normalise a module return value into a list of filter passes.
--- @param mod any
--- @return table
local function as_passes(mod)
  if type(mod) ~= 'table' or next(mod) == nil then
    return {}
  end
  if type(next(mod)) == 'number' then
    return mod
  end
  return { mod }
end

--- Resolve the require path for a filter module file.
--- @param name string
--- @return string
local function filter_path(name)
  return quarto.utils.resolve_path('_filters/' .. name .. '.lua'):gsub('%.lua$', '')
end

--- Wrap each handler in a pass with an activation guard.
--- @param name string
--- @param pass table
--- @return table
local function gate_pass(name, pass)
  local gated = {}
  for elem, fn in pairs(pass) do
    gated[elem] = function(...)
      if not enabled[name] then
        return nil
      end
      return fn(...)
    end
  end
  return gated
end

--- Capture the activation flags from the document metadata.
--- @param meta pandoc.Meta
--- @return nil
local function capture_config(meta)
  checker:options(meta)
  local cfg = meta_mod.get_extension_config(meta, EXTENSION_NAME) or {}
  for key, _ in pairs(cfg) do
    if not MODULE_SET[key] then
      log.log_warning(EXTENSION_NAME, "Unknown module '" .. key .. "'.")
    end
  end
  for _, name in ipairs(MODULES) do
    enabled[name] = to_bool(cfg[name])
  end
  return nil
end

local filters = { { Meta = capture_config } }
for _, name in ipairs(MODULES) do
  local mod = require(filter_path(name))
  for _, pass in ipairs(as_passes(mod.filters)) do
    table.insert(filters, gate_pass(name, pass))
  end
end

return filters
