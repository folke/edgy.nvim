local M = {}

---@param opts? Edgy.Config
function M.setup(opts)
  require("edgy.config").setup(opts)
end

---@param pos? Edgy.Pos
function M.close(pos)
  local Config = require("edgy.config")
  for p, sidebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      sidebar:close()
    end
  end
end

return M
