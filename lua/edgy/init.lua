local M = {}

---@param opts? Edgy.Config
function M.setup(opts)
  require("edgy.config").setup(opts)
end

---@param pos? Edgy.Pos
function M.close(pos)
  local Config = require("edgy.config")
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      edgebar:close()
    end
  end
end

return M
