local Window = require("edgy.window")
local Editor = require("edgy.editor")

---@class Edgy.View.Opts
---@field ft string
---@field filter? fun(win:window):boolean?
---@field title? string
---@field size? Edgy.Size
---@field pinned? boolean
---@field sidebar Edgy.Sidebar
---@field open? fun()|string
---@field close? fun()
---@field wo? vim.wo

---@class Edgy.View: Edgy.View.Opts
---@field title string
---@field wins Edgy.Window[]
---@field size Edgy.Size
---@field pinned_win? Edgy.Window
local M = {}
M.__index = M

---@param opts Edgy.View.Opts
function M.new(opts, sidebar)
  local self = setmetatable(opts, M)
  self.sidebar = sidebar
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
    if not self.filter or self.filter(win) then
      self.wins[#self.wins + 1] = index[win] or Window.new(win, self)
    end
  end
  return #self.wins
end

---@param opts? {check: boolean}
function M:layout(opts)
  if #self.wins == 1 and self.wins[1] == self.pinned_win then
    self.wins = {}
  end
  if self.sidebar.visible > 0 and self.pinned and #self.wins == 0 then
    self:show_pinned(opts)
  else
    self:hide_pinned(opts)
  end
end

---@param opts? {check: boolean}
function M:show_pinned(opts)
  if not (self.pinned_win and vim.api.nvim_win_is_valid(self.pinned_win.win)) then
    if opts and opts.check then
      self.sidebar.dirty = true
      return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
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
      self.sidebar.dirty = true
      return
    end
    if self.pinned_win.win == vim.api.nvim_get_current_win() then
      Editor:goto_main()
    end
    vim.api.nvim_win_close(self.pinned_win.win, true)
    self.pinned_win = nil
  end
end

return M
