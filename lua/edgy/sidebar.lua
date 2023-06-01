local View = require("edgy.view")
local Layout = require("edgy.layout")

---@class Edgy.Sidebar.Opts
---@field views (Edgy.View.Opts|string)[]
---@field size? number
---@field titles? boolean

local wincmds = {
  bottom = "J",
  top = "K",
  right = "L",
  left = "H",
}

---@class Edgy.Sidebar
---@field pos Edgy.Pos
---@field views Edgy.View[]
---@field wins Edgy.Window[]
---@field size integer
---@field titles boolean
---@field vertical boolean
---@field state table<window,any>
local M = {}
M.__index = M

---@param pos Edgy.Pos
---@param opts Edgy.Sidebar.Opts
---@return Edgy.Sidebar
function M.new(pos, opts)
  local vertical = pos == "left" or pos == "right"
  local self = setmetatable({
    pos = pos,
    views = {},
    size = opts.size or vertical and 30 or 10,
    titles = opts.titles or true,
    vertical = vertical,
    wins = {},
    state = {},
  }, M)
  for _, v in ipairs(opts.views) do
    v = type(v) == "string" and { ft = v } or v
    ---@cast v Edgy.View.Opts
    table.insert(self.views, View.new(v))
  end
  self:on_win_enter()
  return self
end

function M:on_win_enter()
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      for _, w in ipairs(self.wins) do
        if w.win == win then
          if not w.visible then
            w:show()
          end
          break
        end
      end
    end,
  })
end

---@param wins table<string, number[]>
function M:update(wins)
  self.wins = {}
  for _, view in ipairs(self.views) do
    view:update(wins[view.ft] or {})
    vim.list_extend(self.wins, view.wins)
  end
  for w, win in ipairs(self.wins) do
    win.prev = self.wins[w - 1]
    win.next = self.wins[w + 1]
  end
end

function M:layout()
  ---@type number?
  local last
  for _, w in ipairs(self.wins) do
    local win = w.win
    if not last then
      vim.api.nvim_win_call(win, function()
        vim.cmd("wincmd " .. wincmds[self.pos])
      end)
    else
      local ok, err = pcall(vim.fn.win_splitmove, win, last, { vertical = not self.vertical })
      if not ok then
        vim.notify("Edgy: Failed to layout windows.\n" .. err .. "\n" .. vim.inspect({
          win = vim.bo[vim.api.nvim_win_get_buf(win)].ft,
          last = vim.bo[vim.api.nvim_win_get_buf(last)].ft,
        }), vim.log.levels.ERROR, { title = "edgy.nvim" })
      end
    end
    last = win
  end
end

function M:resize()
  if #self.wins == 0 then
    return
  end
  Layout.layout(self.wins, { vertical = self.vertical, size = self.size })
end

function M:state_save()
  self.state = {}
  for _, win in ipairs(self.wins) do
    vim.api.nvim_win_call(win.win, function()
      self.state[win.win] = vim.fn.winsaveview()
    end)
  end
end

function M:state_restore()
  for _, win in ipairs(self.wins) do
    local state = self.state[win.win]
    if state then
      vim.api.nvim_win_call(win.win, function()
        vim.fn.winrestview(state)
      end)
    end
  end
end

return M
