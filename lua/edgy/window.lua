local Config = require("edgy.config")

---@class Edgy.Window
---@field visible boolean
---@field view Edgy.View
---@field win window
---@field width number
---@field height number
---@field next? Edgy.Window
---@field prev? Edgy.Window
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
  }, M)
  M.cache[win] = self
  if self.view.winbar ~= false then
    vim.wo[self.win].winbar = "%!v:lua.edgy_winbar(" .. win .. ")"
  end
  vim.wo[self.win].winfixwidth = true
  return self
end

function M:is_valid()
  return vim.api.nvim_win_is_valid(self.win)
end

---@param visibility? boolean
function M:show(visibility)
  self.visible = visibility == nil and true or visibility or false
  if not self.visible and not self.prev and not self.next then
    self.visible = true
    return
  end
  if not self.visible and vim.api.nvim_get_current_win() == self.win then
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if not M.cache[w] then
        vim.api.nvim_set_current_win(w)
        break
      end
    end
  end
  if not self.visible then
    self:ensure_one_visible()
  end
  vim.cmd([[redrawstatus!]])
  require("edgy.layout").update()
end

function M:ensure_one_visible()
  if self:sibling(function(w)
    return w.visible
  end) then
    return
  end
  if self.prev then
    self.prev:show()
  elseif self.next then
    self.next:show()
  end
end

---@param filter fun(win:Edgy.Window):boolean?
---@param dir? "next" | "prev"
function M:sibling(filter, dir)
  if not dir then
    return self:sibling(filter, "next") or self:sibling(filter, "prev")
  end
  local sibling = self[dir]
  while sibling do
    if filter(sibling) then
      return sibling
    end
    sibling = sibling[dir]
  end
end

function M:toggle()
  self:show(not self.visible)
end

function M:winbar()
  ---@type string[]
  local parts = {}
  parts[#parts + 1] = "%" .. self.win .. "@v:lua.edgy_click@"
  parts[#parts + 1] = "%#SignColumn#" .. (self.visible and Config.icons.open or Config.icons.closed) .. "%*"
  parts[#parts + 1] = "%#Title# " .. self.view.title .. "%*"
  parts[#parts + 1] = "%T"
  return table.concat(parts)
end

function M:resize()
  vim.api.nvim_win_set_height(self.win, self.height)
  vim.api.nvim_win_set_width(self.win, self.width)
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
