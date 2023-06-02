local Window = require("edgy.window")

---@class Edgy.View.Opts
---@field ft string
---@field title? string
---@field size? Edgy.Size
---@field winbar? boolean
---@field pinned? boolean
---@field sidebar Edgy.Sidebar
---@field open? fun()|string
---@field close? fun()

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
    self.wins[#self.wins + 1] = index[win] or Window.new(win, self)
  end
  return #self.wins
end

function M:check_pinned()
  if not self.pinned or #self.wins > 0 then
    self:hide_pinned()
    return
  end
  if not (self.pinned_win and vim.api.nvim_win_is_valid(self.pinned_win.win)) then
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

function M:hide_pinned()
  if self.pinned_win and vim.api.nvim_win_is_valid(self.pinned_win.win) then
    if self.pinned_win.win == vim.api.nvim_get_current_win() then
      self.pinned_win:goto_main()
    end
    vim.api.nvim_win_close(self.pinned_win.win, true)
    self.pinned_win = nil
  end
end

return M
