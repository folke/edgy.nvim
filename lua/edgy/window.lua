local Config = require("edgy.config")

---@class Edgy.Window
---@field visible boolean
---@field view Edgy.View
---@field win window
---@field changed number
local M = {}
M.__index = M

---@type table<window, Edgy.Window>
M.cache = setmetatable({}, { __mode = "v" })

---@param win window
---@param view Edgy.View
function M.new(win, view)
  local self = setmetatable({
    visible = true,
    view = view,
    win = win,
    changed = 0,
  }, M)
  M.cache[win] = self
  if self.view.winbar ~= false then
    vim.wo[self.win].winbar = "%!v:lua.edgy_winbar(" .. win .. ")"
  end
  vim.api.nvim_win_call(self.win, function()
    vim.cmd([[setlocal winminwidth=0]])
    vim.cmd([[setlocal winminheight=0]])
  end)
  return self
end

function M:is_valid()
  return vim.api.nvim_win_is_valid(self.win)
end

---@param visibility? boolean
function M:show(visibility)
  self.visible = visibility == nil and true or visibility or false
  if not self.visible and vim.api.nvim_get_current_win() == self.win then
    vim.cmd([[wincmd p]])
  end
  self.changed = vim.loop.hrtime()
  vim.cmd([[redrawstatus!]])
  require("edgy.layout").update()
end
--
function M:toggle()
  self:show(not self.visible)
end

function M:winbar()
  local parts = {}
  parts[#parts + 1] = "%" .. self.win .. "@v:lua.edgy_click@"
  parts[#parts + 1] = "%#SignColumn#" .. (self.visible and Config.icons.open or Config.icons.closed) .. "%*"
  parts[#parts + 1] = "%#Title# " .. self.view.title .. "%*"
  parts[#parts + 1] = "%T"
  return table.concat(parts)
end

function M:resize(width, height)
  if height then
    vim.api.nvim_win_set_height(self.win, height)
    if height == 0 then
      vim.fn.win_move_statusline(self.win, -1)
    end
  end
  if width then
    vim.api.nvim_win_set_width(self.win, width)
  end
end

---@diagnostic disable-next-line: global_usage
function _G.edgy_winbar(win)
  local window = M.cache[win]
  return window and window:winbar() or ""
end

---@diagnostic disable-next-line: global_usage
function _G.edgy_click(win)
  local window = M.cache[win]
  if window then
    window:toggle()
  end
end

return M
