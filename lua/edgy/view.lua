local Window = require("edgy.window")
local Editor = require("edgy.editor")
local Util = require("edgy.util")

---@class Edgy.View.Opts
---@field ft string
---@field filter? fun(buf:buffer, win:window):boolean?
---@field title? string
---@field size? Edgy.Size
-- When a view is pinned, it will always be shown
-- in the edgebar, even if it has no windows.
---@field pinned? boolean
-- Open function or command to open a pinned view
---@field open? fun()|string
---@field wo? vim.wo View specific window options

---@class Edgy.View: Edgy.View.Opts
---@field title string
---@field wins Edgy.Window[]
---@field size Edgy.Size
---@field pinned_win? Edgy.Window
---@field edgebar Edgy.Edgebar
---@field opening boolean
local M = {}
M.__index = M

---@param opts Edgy.View.Opts
function M.new(opts, edgebar)
  local self = setmetatable(opts, M)
  self.edgebar = edgebar
  self.wins = {}
  self.title = self.title or self.ft:sub(1, 1):upper() .. self.ft:sub(2)
  self.size = self.size or {}
  self.opening = false
  return self
end

---@param wins window[]
---@return boolean updated Whether the view was updated
function M:update(wins)
  ---@type table<window, Edgy.Window>
  local index = {}
  for _, w in ipairs(self.wins) do
    index[w.win] = w
  end
  local old = self.wins
  self.wins = {}
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not self.filter or self.filter(buf, win) then
      self.wins[#self.wins + 1] = index[win] or Window.new(win, self)
    end
  end
  if #self.wins > 0 then
    self.opening = false
  end
  return not vim.deep_equal(old, self.wins)
end

---@param opts? {check: boolean}
function M:layout(opts)
  if #self.wins == 1 and self.wins[1] == self.pinned_win then
    self.wins = {}
  end
  if self.edgebar.visible > 0 and self.pinned and #self.wins == 0 then
    self:show_pinned(opts)
  else
    self:hide_pinned(opts)
  end
end

---@param opts? {check: boolean}
function M:show_pinned(opts)
  if not (self.pinned_win and vim.api.nvim_win_is_valid(self.pinned_win.win)) then
    if opts and opts.check then
      self.edgebar.dirty = true
      return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "edgy"
    vim.api.nvim_buf_set_name(buf, "edgy://" .. self.title)
    local win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = 1,
      height = 1,
      col = 0,
      row = 0,
      style = "minimal",
    })
    vim.api.nvim_create_autocmd("BufWinLeave", {
      buffer = buf,
      callback = function()
        self:hide_pinned()
      end,
    })
    self.pinned_win = Window.new(win, self)
  end
  self.wins[1] = self.pinned_win
  self.wins[1].visible = false
end

---@param opts? {check: boolean}
function M:hide_pinned(opts)
  if self.pinned_win and vim.api.nvim_win_is_valid(self.pinned_win.win) then
    if opts and opts.check then
      self.edgebar.dirty = true
      return
    end
    if self.pinned_win.win == vim.api.nvim_get_current_win() then
      Editor:goto_main()
    end
    vim.api.nvim_win_close(self.pinned_win.win, true)
    self.pinned_win = nil
  end
end

function M:open_pinned()
  self.opening = true
  vim.schedule(function()
    Editor:goto_main()
    if type(self.open) == "function" then
      Util.try(self.open)
    elseif type(self.open) == "string" then
      Util.try(function()
        vim.cmd(self.open)
      end)
    else
      Util.error("View is pinned and has no open function")
    end
  end)
end

return M
