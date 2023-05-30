local M = {}

---@alias SidebarPos "bottom"|"top"|"left"|"right"

---@class Config.View
---@field ft string
---@field title? string
---@field size? integer

---@class Config.Sidebar
---@field views (Config.View|string)[]
---@field size? number
---@field titles? boolean

---@class SidebarView
---@field ft string
---@field title string
---@field size? integer

---@class Config
local defaults = {
  ---@type table<SidebarPos, Config.Sidebar>
  layout = {},
}

---@type table<SidebarPos, Sidebar>
M.layout = {}

local wincmds = {
  bottom = "J",
  top = "K",
  right = "L",
  left = "H",
}

---@class Sidebar
---@field pos SidebarPos
---@field views SidebarView[]
---@field size integer
---@field titles boolean
---@field vertical boolean
---@field wins number[]
---@field min_size integer
local Sidebar = {}
Sidebar.__index = Sidebar

---@param pos SidebarPos
---@param opts Config.Sidebar
---@return Sidebar
function Sidebar.new(pos, opts)
  local vertical = pos == "left" or pos == "right"
  local self = setmetatable({
    pos = pos,
    views = {},
    size = opts.size or vertical and 30 or 10,
    titles = opts.titles or true,
    vertical = vertical,
  }, Sidebar)
  for _, v in ipairs(opts.views) do
    v = type(v) == "string" and { ft = v } or v
    if not v.title then
      v.title = v.ft:sub(1, 1):upper() .. v.ft:sub(2)
    end
    table.insert(self.views, v)
  end
  return self
end

---@param wins table<string, number[]>
function Sidebar:update(wins)
  ---@type number?
  local last
  self.wins = {}
  self.min_size = 0
  for _, view in ipairs(self.views) do
    for _, win in ipairs(wins[view.ft] or {}) do
      if not last then
        vim.api.nvim_win_call(win, function()
          vim.cmd("wincmd " .. wincmds[self.pos])
        end)
      else
        vim.fn.win_splitmove(win, last, { vertical = not self.vertical })
      end
      self.min_size = math.max(self.min_size, view.size or 0)
      last = win
      self.wins[#self.wins + 1] = win
      if self.titles then
        vim.wo[win].winbar = " " .. view.title
      end
    end
  end
end

function Sidebar:layout()
  local size = 0
  for _, win in ipairs(self.wins) do
    if self.vertical then
      size = size + vim.api.nvim_win_get_height(win)
    else
      size = size + vim.api.nvim_win_get_width(win)
    end
  end

  for _, win in ipairs(self.wins) do
    local height = math.max(self.size, self.min_size)
    local width = math.floor(size / #self.wins)
    if self.vertical then
      width, height = height, width
    end
    vim.api.nvim_win_set_height(win, height)
    vim.api.nvim_win_set_width(win, width)
  end
end

---@param opts? Config
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  for pos, s in pairs(opts.layout) do
    M.layout[pos] = Sidebar.new(pos, s)
  end
  local group = vim.api.nvim_create_augroup("layout", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "VimResized" }, {
    group = group,
    callback = M.update,
  })
  vim.api.nvim_create_autocmd({ "FileType" }, {
    callback = function()
      vim.schedule(M.update)
    end,
  })
  M.update()
end

function M.update()
  ---@type table<string, number[]>
  local wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft then
      wins[ft] = wins[ft] or {}
      table.insert(wins[ft], win)
    end
  end

  vim.o.eventignore = "all"
  local splitkeep = vim.o.splitkeep
  vim.o.splitkeep = "cursor"

  for _, pos in ipairs({ "bottom", "top", "left", "right" }) do
    if M.layout[pos] then
      M.layout[pos]:update(wins)
    end
  end
  for _, pos in ipairs({ "left", "right", "bottom", "top" }) do
    if M.layout[pos] then
      M.layout[pos]:layout()
    end
  end
  vim.o.splitkeep = splitkeep
  vim.o.eventignore = ""
end

return M
