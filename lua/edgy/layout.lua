---@class Edgy.Size
---@field width? number
---@field height? number

local M = {}

---@param size number
---@param max number
function M.size(size, max)
  return size < 1 and math.floor(max * size) or size
end

---@param wins Edgy.Window[]
---@param opts {vertical: boolean, size:number}
function M.layout(wins, opts)
  local width = opts.vertical and M.size(opts.size, vim.o.columns) or 0
  local height = opts.vertical and 0 or M.size(opts.size, vim.o.lines)

  -- calculate the sidebar size
  for _, win in ipairs(wins) do
    if opts.vertical then
      width = math.max(width, M.size(win.view.size.width or 0, vim.o.columns))
      height = height + vim.api.nvim_win_get_height(win.win)
    else
      width = width + vim.api.nvim_win_get_width(win.win)
      height = math.max(height, M.size(win.view.size.height or 0, vim.o.lines))
    end
  end

  -- calculate view sizes
  local free = opts.vertical and height or width
  local auto = 0
  for _, win in ipairs(wins) do
    if win.visible then
      if opts.vertical then
        if win.view.size.height then
          free = free - M.size(win.view.size.height, height)
        else
          auto = auto + 1
        end
      else
        if win.view.size.width then
          free = free - M.size(win.view.size.width, width)
        else
          auto = auto + 1
        end
      end
    else
      free = free - 1
    end
  end

  -- layout views
  for _, win in ipairs(wins) do
    if win.visible then
      if opts.vertical then
        if win.view.size.height then
          if auto == 0 and free > 0 then
            win:resize(width, free + M.size(win.view.size.height, height))
            free = 0
          else
            win:resize(width, M.size(win.view.size.height, height))
          end
        else
          win:resize(width, math.floor(free / auto))
        end
      else
        if win.view.size.width then
          if auto == 0 and free > 0 then
            win:resize(free + M.size(win.view.size.width, width), height)
            free = 0
          else
            win:resize(M.size(win.view.size.width, width), height)
          end
        else
          win:resize(math.floor(free / auto), height)
        end
      end
    else
      if opts.vertical then
        if #wins == 1 then
          win:resize(0, height)
        elseif not win.last then
          win:resize(width, 0)
        end
      else
        if #wins == 1 then
          win:resize(width, 0)
        elseif not win.last then
          win:resize(0, height)
        end
      end
    end
  end
end

---@alias LayoutTuple {[1]: ("row"|"col"|"leaf"), [2]: window|LayoutTuple[]}

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
  local Config = require("edgy.config")
  local done = {}
  for _, pos in ipairs({ "left", "right", "bottom", "top" }) do
    local sidebar = Config.layout[pos]
    if sidebar and #sidebar:wins() > 0 then
      local wins = vim.tbl_map(function(w)
        return w.win
      end, sidebar:wins())

      local found = vim.tbl_filter(function(w)
        return not vim.tbl_contains(done, w)
      end, M.get(pos))

      vim.list_extend(done, wins)
      if not vim.deep_equal(wins, found) then
        return true
      end
    end
  end
  return false
end

function M.update()
  local Config = require("edgy.config")

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

  -- Update the windows in each sidebar
  for _, pos in ipairs({ "bottom", "top", "left", "right" }) do
    if Config.layout[pos] then
      Config.layout[pos]:update(wins)
    end
  end

  -- Layout the sidebars when needed
  local dirty = M.needs_layout()
  if dirty then
    for _, pos in ipairs({ "bottom", "top", "left", "right" }) do
      if Config.layout[pos] then
        Config.layout[pos]:layout()
      end
    end
  end

  -- Resize the sidebar windows
  for _, pos in ipairs({ "left", "right", "bottom", "top" }) do
    if Config.layout[pos] then
      Config.layout[pos]:resize()
    end
  end

  vim.o.splitkeep = splitkeep
  vim.o.eventignore = ""
end

return M
