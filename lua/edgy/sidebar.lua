local View = require("edgy.view")
local Util = require("edgy.util")

---@class Edgy.Sidebar.Opts
---@field views (Edgy.View.Opts|string)[]
---@field size? number
---@field wo? vim.wo

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
---@field vertical boolean
---@field state table<window,any>
---@field wo? vim.wo
---@field dirty boolean
---@field visible number
---@field stop boolean
local M = {}
M.__index = M

---@class Edgy.Size
---@field width? number
---@field height? number

---@param size number
---@param max number
function M.size(size, max)
  return math.max(size < 1 and math.floor(max * size) or size, 1)
end

---@param pos Edgy.Pos
---@param opts Edgy.Sidebar.Opts
---@return Edgy.Sidebar
function M.new(pos, opts)
  local vertical = pos == "left" or pos == "right"
  local self = setmetatable({
    pos = pos,
    views = {},
    size = opts.size or vertical and 30 or 10,
    vertical = vertical,
    wins = {},
    visible = 0,
    state = {},
    wo = opts.wo,
    dirty = true,
  }, M)
  for _, v in ipairs(opts.views) do
    v = type(v) == "string" and { ft = v } or v
    ---@cast v Edgy.View.Opts
    table.insert(self.views, View.new(v, self))
  end
  self:on_win_enter()
  return self
end

function M:on_win_enter()
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      vim.schedule(function()
        local win = vim.api.nvim_get_current_win()
        for _, w in ipairs(self.wins) do
          if w.win == win then
            if not w.visible then
              w:show()
            end
            break
          end
        end
      end)
    end,
  })
end

---@param wins table<string, number[]>
function M:update(wins)
  self.visible = 0
  for _, view in ipairs(self.views) do
    self.visible = self.visible + view:update(wins[view.ft] or {})
    wins[view.ft] = vim.tbl_filter(function(w)
      for _, win in ipairs(view.wins) do
        if win.win == w then
          return false
        end
      end
      return true
    end, wins[view.ft] or {})
  end
  self:_update({ check = true })
end

---@param opts? {check: boolean}
function M:_update(opts)
  self.wins = {}
  for _, view in ipairs(self.views) do
    view:layout(opts)
    vim.list_extend(self.wins, view.wins)
  end
  for w, win in ipairs(self.wins) do
    win.prev = self.wins[w - 1]
    win.next = self.wins[w + 1]
  end
end

function M:layout()
  if self.stop then
    return
  end
  if vim.v.exiting ~= vim.NIL then
    return
  end
  if not (self.dirty or #self.wins > 0) then
    return
  end
  if self.dirty then
    self:_update()
  end

  self.dirty = true
  ---@type number?
  local last
  for _, w in ipairs(self.wins) do
    -- move first window to the sidebar position
    -- and make floating windows normal windows
    if not last or vim.api.nvim_win_get_config(w.win).relative ~= "" then
      vim.api.nvim_win_call(w.win, function()
        vim.cmd("wincmd " .. wincmds[self.pos])
      end)
    end
    -- move other windows to the end of the sidebar
    if last then
      local ok, err = pcall(vim.fn.win_splitmove, w.win, last, { vertical = not self.vertical })
      if not ok then
        error("Edgy: Failed to layout windows.\n" .. err .. "\n" .. vim.inspect({
          win = vim.bo[vim.api.nvim_win_get_buf(w.win)].ft,
          last = vim.bo[vim.api.nvim_win_get_buf(last)].ft,
        }))
      end
    end
    last = w.win
  end
  self.dirty = false
end

function M:resize()
  if #self.wins == 0 then
    return
  end

  -- always override these options before resizing
  vim.o.winminheight = 0
  vim.o.winminwidth = 1

  local long = self.vertical and "height" or "width"
  local short = self.vertical and "width" or "height"

  local bounds = {
    width = self.vertical and M.size(self.size, vim.o.columns) or 0,
    height = self.vertical and 0 or M.size(self.size, vim.o.lines),
  }

  -- calculate the sidebar bounds
  for _, win in ipairs(self.wins) do
    if win.visible then
      local size = M.size(win.view.size[short] or 0, self.vertical and vim.o.columns or vim.o.lines)
      bounds[short] = math.max(bounds[short], size)
    end
    local size = self.vertical and vim.api.nvim_win_get_height(win.win)
      or vim.api.nvim_win_get_width(win.win)
    bounds[long] = bounds[long] + size
  end

  -- views with auto-sized windows
  local auto = {} ---@type Edgy.Window[]

  -- views with fixed-sized windows
  local fixed = {} ---@type Edgy.Window[]

  -- calculate window sizes
  local free = bounds[long]
  for _, win in ipairs(self.wins) do
    win[short] = bounds[short]
    win[long] = 1
    -- fixed-sized windows
    if win.visible and win.view.size[long] then
      win[long] = M.size(win.view.size[long], bounds[long])
      fixed[#fixed + 1] = win
    -- auto-sized windows
    elseif win.visible then
      auto[#auto + 1] = win
    -- hidden windows
    else
      win[long] = self.vertical and 1 or (vim.fn.strdisplaywidth(win.view.title) + 3)
    end
    free = free - win[long]
  end

  -- distribute free space to auto-sized windows,
  -- or fixed-sized windows when there are no auto-sized windows
  if free > 0 then
    local _wins = #auto > 0 and auto or #fixed > 0 and fixed or self.wins
    local extra = math.ceil(free / #_wins)
    for _, win in ipairs(_wins) do
      win[long] = win[long] + math.min(extra, free)
      free = math.max(free - extra, 0)
    end
  end

  -- resize windows
  local updates = {}
  for _, win in ipairs(self.wins) do
    local changes = win:resize()
    if not vim.tbl_isempty(changes) then
      updates[#updates + 1] = { win.view.title, changes }
    end
  end
  -- if #updates > 0 then
  --   dd("resize", updates)
  -- end
end

-- Save window state.
-- For hidden windows, save the previous state.
function M:save_state()
  local prev_state = self.state
  self.state = {}
  for _, win in ipairs(self.wins) do
    if win.visible or not prev_state[win.win] then
      vim.api.nvim_win_call(win.win, function()
        self.state[win.win] = vim.fn.winsaveview()
      end)
    else
      self.state[win.win] = prev_state[win.win]
    end
  end
end

function M:restore_state()
  for _, win in ipairs(self.wins) do
    local state = self.state[win.win]
    if state and win.visible then
      vim.api.nvim_win_call(win.win, function()
        vim.fn.winrestview({ topline = state.topline, leftcol = state.leftcol })
      end)
    end
  end
end

function M:close()
  for _, win in ipairs(self.wins) do
    pcall(vim.api.nvim_win_close, win.win, true)
  end
end

M.close = Util.noautocmd(M.close)

return M
