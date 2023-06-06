---@class Edgy: Edgy.Commands
local M = {}

---@param opts? Edgy.Config
function M.setup(opts)
  require("edgy.config").setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("edgy.commands")[k]
  end,
})
