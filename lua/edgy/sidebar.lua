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
---@field size integer
---@field titles boolean
---@field vertical boolean
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
  }, M)
  for _, v in ipairs(opts.views) do
    v = type(v) == "string" and { ft = v } or v
    ---@cast v Edgy.View.Opts
    table.insert(self.views, View.new(v))
  end
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      for _, w in ipairs(self:wins()) do
        if w.win == win then
          if not w.visible then
            w:show()
          end
          break
        end
      end
    end,
  })
  return self
end

---@param wins table<string, number[]>
function M:update(wins)
  for _, view in ipairs(self.views) do
    view:update(wins[view.ft] or {})
  end
  self:update_visible()
end

function M:update_visible()
  local wins = self:wins()

  if #wins == 0 then
    return
  end

  if #wins == 1 then
    wins[1].visible = true
    return
  end

  local visible = 0
  local last = 1
  for w, win in ipairs(wins) do
    if win.visible then
      visible = visible + 1
    elseif win.changed > wins[last].changed then
      last = w
    end
  end
  if visible == 0 then
    if wins[last + 1] then
      wins[last + 1].visible = true
    else
      wins[last - 1].visible = true
    end
  end
end

function M:layout()
  ---@type number?
  local last
  for _, w in ipairs(self:wins()) do
    local win = w.win
    if not last then
      vim.api.nvim_win_call(win, function()
        vim.cmd("wincmd " .. wincmds[self.pos])
      end)
    else
      vim.fn.win_splitmove(win, last, { vertical = not self.vertical })
    end
    last = win
  end
end

function M:resize()
  Layout.layout(self:wins(), { vertical = self.vertical, size = self.size })
end

function M:wins()
  ---@type Edgy.Window[]
  local wins = {}
  for _, view in ipairs(self.views) do
    vim.list_extend(wins, view.wins)
  end
  return wins
end

return M
