--- Count Cite - Filter Module
--- @module "count-cite"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Count citation occurrences and log them.
--- @description Walk the document collecting citation identifiers and,
---   at end of processing, log the per-id counts through logging.lua.

local M = {}

local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))

local EXTENSION_NAME = 'gallimaufry'

local citation_count = {}

--- Increment the counter for each citation id in a Cite element.
--- @param cite pandoc.Cite
function M.count_cite(cite)
  for _, citation in ipairs(cite.citations) do
    local id = citation.id
    citation_count[id] = (citation_count[id] or 0) + 1
  end
end

--- Report collected citation counts.
--- @param _ pandoc.Pandoc
function M.report(_)
  local parts = {}
  for id, count in pairs(citation_count) do
    table.insert(parts, id .. '=' .. tostring(count))
  end
  table.sort(parts)
  log.log_output(EXTENSION_NAME, 'count-cite: ' .. table.concat(parts, ', '))
end

--- Filter tables for the gallimaufry orchestrator.
M.filters = {
  Cite = M.count_cite,
  Pandoc = M.report,
}

return M
