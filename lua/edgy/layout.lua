local Util = require("edgy.util")
local Config = require("edgy.config")
local State = require("edgy.state")

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

-- check that all windows have the same size in the given direction
---@param pos Edgy.Pos
---@param wins window[]
function M.check_size(pos, wins)
  local size = nil ---@type number?
  for _, win in ipairs(wins) do
    local s = pos == "left"
      or pos == "right" and vim.api.nvim_win_get_width(win)
      or vim.api.nvim_win_get_height(win)
    size = size == nil and s or size
    if size ~= s then
      return false
    end
  end
  return true
end

function M.needs_layout()
  local done = {}
  for _, pos in ipairs({ "left", "right", "bottom", "top" }) do
    local edgebar = Config.layout[pos]
    if edgebar and edgebar.dirty then
      return true
    end
    if edgebar and #edgebar.wins > 0 then
      local needed = vim.tbl_map(function(w)
        return w.win
      end, edgebar.wins)

      local found = vim.tbl_filter(function(w)
        return not vim.tbl_contains(done, w)
      end, M.get(pos))

      vim.list_extend(done, needed)
      if not vim.deep_equal(needed, found) or not M.check_size(pos, found) then
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
---@param fn fun(edgebar: Edgy.Edgebar, pos: Edgy.Pos)
function M.foreach(pos, fn)
  for _, p in ipairs(pos) do
    if Config.layout[p] then
      fn(Config.layout[p], p)
    end
  end
end

---@return boolean changed whether the layout changed
local function update()
  ---@type table<string, number[]>
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft and not vim.b[buf].edgy_disable and not vim.w[win].edgy_disable then
      wins[ft] = wins[ft] or {}
      table.insert(wins[ft], win)
    end
  end

  local changed = false
  -- Update the windows in each edgebar
  M.foreach({ "bottom", "top", "left", "right" }, function(edgebar)
    if edgebar:update(wins) then
      changed = true
    end
  end)
  return changed
end

---@param opts? {full: boolean}
function M.layout(opts)
  opts = opts or {}

  local changed = update()
  local needs_layout = M.needs_layout()

  if opts.full and not (changed or needs_layout) then
    return false
  end

  if opts.full and needs_layout then
    State.save()
    Util.debug("full layout")
    M.foreach({ "bottom", "top", "left", "right" }, function(edgebar)
      edgebar:layout()
    end)
    -- State.restore()
  end

  local updated = false
  M.foreach({ "left", "right", "bottom", "top" }, function(edgebar)
    if edgebar:resize() then
      if not updated then
        State.save()
        updated = true
      end
      if not Config.animate.enabled then
        for _, win in ipairs(edgebar.wins) do
          win:apply_size()
        end
      end
    end
  end)

  if updated then
    if Config.animate.enabled then
      require("edgy.animate").update()
    else
      Util.debug("resize")
      State.restore()
    end
  end

  return true
end

-- M.resize = Util.throttle(M.wrap(M._resize), 300)
M.resize = Util.debounce(M.layout, 50)

M.update = Util.with_retry(Util.noautocmd(function()
  if not M.layout({ full = true }) then
    M.layout()
  end
end))

return M
