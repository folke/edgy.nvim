local Window = require("edgy.window")

---@class Edgy.View.Opts
---@field ft string
---@field title? string
---@field size? Edgy.Size
---@field winbar? boolean
---@field pinned? boolean
---@field open? fun()
---@field close? fun()

---@class Edgy.View: Edgy.View.Opts
---@field title string
---@field wins Edgy.Window[]
---@field size Edgy.Size
local M = {}
M.__index = M

---@param opts Edgy.View.Opts
function M.new(opts)
  local self = setmetatable(opts, M)
  self.wins = {}
  self.title = self.title or self.ft:sub(1, 1):upper() .. self.ft:sub(2)
  self.size = self.size or {}
  return self
end

---@param wins window[]
function M:update(wins)
  ---@type table<window, Edgy.Window>
  local index = {}
  for _, w in ipairs(self.wins) do
    index[w.win] = w
  end
  self.wins = {}
  for _, win in ipairs(wins) do
    self.wins[#self.wins + 1] = index[win] or Window.new(win, self)
  end
end

return M
