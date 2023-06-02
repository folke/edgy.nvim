local Util = require("edgy.util")
local Config = require("edgy.config")

local M = {}

---@alias LayoutTuple {[1]: ("row"|"col"|"leaf"), [2]: window|LayoutTuple[]}

-- Get a list of all the windows in a certain direction
---@param node? LayoutTuple
---@param pos Edgy.Pos
---@param wins? window[]
---@return window[]
function M.get(pos, node, wins)
  wins = wins or {}
  node = node or vim.fn.winlayout()
  if node[1] == "leaf" then
    wins[#wins + 1] = node[2]
  elseif node[1] == "row" then
    if pos == "left" then
      M.get(pos, node[2][1], wins)
    elseif pos == "right" then
      M.get(pos, node[2][#node[2]], wins)
    else
      for _, child in ipairs(node[2]) do
        M.get(pos, child, wins)
      end
    end
  elseif node[1] == "col" then
    if pos == "top" then
      M.get(pos, node[2][1], wins)
    elseif pos == "bottom" then
      M.get(pos, node[2][#node[2]], wins)
    else
      for _, child in ipairs(node[2]) do
        M.get(pos, child, wins)
      end
    end
  end
  return wins
end

function M.needs_layout()
  local done = {}
  for _, pos in ipairs({ "left", "right", "bottom", "top" }) do
    local sidebar = Config.layout[pos]
    if sidebar and #sidebar.wins > 0 then
      local needed = vim.tbl_map(function(w)
        return w.win
      end, sidebar.wins)

      local found = vim.tbl_filter(function(w)
        return not vim.tbl_contains(done, w)
      end, M.get(pos))

      vim.list_extend(done, needed)
      if not vim.deep_equal(needed, found) then
        -- dd(pos, { needed = M.debug(needed), found = M.debug(found) })
        return true
      end
    end
  end
  return false
end

---@param wins window[]
function M.debug(wins)
  return vim.tbl_map(function(w)
    local buf = vim.api.nvim_win_get_buf(w)
    local name = vim.bo[buf].filetype
    if name == "" then
      name = vim.api.nvim_buf_get_name(buf)
    end
    return w .. " " .. name
  end, wins)
end

---@param pos Edgy.Pos[]
---@param fn fun(sidebar: Edgy.Sidebar, pos: Edgy.Pos)
function M.foreach(pos, fn)
  for _, p in ipairs(pos) do
    if Config.layout[p] then
      fn(Config.layout[p], p)
    end
  end
end

M.updating = false
M.tries = 0
M.max_tries = 10

function M.update()
  if M.updating then
    return
  end

  M.tries = M.tries + 1
  M.updating = true

  local sk = vim.o.splitkeep
  vim.o.splitkeep = "cursor"
  vim.o.winminheight = 0
  vim.o.winminwidth = 1

  vim.o.eventignore = "all"

  -- Don't do anything related to splitkeep while updating
  -- local splitkeep = vim.o.splitkeep
  -- vim.o.splitkeep = "cursor"

  local ok, err = pcall(M._update)

  if ok then
    M.tries = 0
  else
    if M.tries >= M.max_tries or Config.debug then
      Util.error(err)
    end
    if M.tries < M.max_tries then
      vim.schedule(M.update)
    end
  end

  -- vim.o.splitkeep = splitkeep
  vim.o.eventignore = ""
  vim.o.splitkeep = sk
  M.updating = false
end

function M._update()
  ---@type table<string, number[]>
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft then
      wins[ft] = wins[ft] or {}
      table.insert(wins[ft], win)
    end
  end
  -- Update the windows in each sidebar
  M.foreach({ "bottom", "top", "left", "right" }, function(sidebar)
    sidebar:update(wins)
    sidebar:state_save()
  end)

  -- Layout the sidebars when needed
  if M.tries > 1 or M.needs_layout() then
    M.foreach({ "bottom", "top", "left", "right" }, function(sidebar)
      sidebar:layout(wins)
    end)
  end

  -- Resize the sidebar windows
  M.foreach({ "left", "right", "bottom", "top" }, function(sidebar)
    sidebar:resize()
  end)

  for _, sidebar in pairs(Config.layout) do
    sidebar:state_restore()
  end
end

return M
