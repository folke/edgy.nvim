local M = {}

---@param opts? Edgy.Config
function M.setup(opts)
  require("edgy.config").setup(opts)
end

return M
