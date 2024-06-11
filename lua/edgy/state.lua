local Editor = require("edgy.editor")
local Util = require("edgy.util")

local M = {}

---@alias WinView {topline:number, lnum:number, col:number}
---@type WinView[]
M.state = {}
M.layout = nil
M.tracking = true
M.cursors = {}

function M.setup()
  M.layout = M.layout_wins()
  M.save()

  -- always update view state when the cursor moves
  vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function(ev)
      local win = vim.fn.bufwinid(ev.buf)
      if win ~= -1 then
        M.update({ win = win, event = "CursorMoved" })
      end
    end,
  })

  -- update view state when layout didn't change
  -- This is needed to properly deal with new windows entering the layout.
  -- New windows mess up the view state, so we don't track changes after a new
  -- window is created until the next restore.
  vim.api.nvim_create_autocmd("WinScrolled", {
    callback = function()
      if M.is_enabled() then
        for win, info in pairs(vim.v.event) do
          if win ~= "all" and (info.topline > 0 or info.height > 0 or info.width > 0) then
            M.update({ win = tonumber(win), event = "WinScrolled" })
          end
        end
      end
    end,
  })
end

-- update view state for a window or the current window
---@param opts? {win?: number, event?: string}
function M.update(opts)
  opts = opts or {}
  local win = (opts.win and opts.win > 0) and opts.win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  ---@type boolean, WinView
  local ok, state = pcall(vim.api.nvim_win_call, win, vim.fn.winsaveview)
  if ok then
    if opts.event == "CursorMoved" then
      local cursor = vim.api.nvim_win_get_cursor(win)
      if vim.deep_equal(M.cursors[win], cursor) then
        return
      end
      state = M.state[win] or state
      state.col = cursor[2]
      state.lnum = cursor[1]
    end
    M.state[win] = state
  end
end

-- safe to enable tracking after layout was restored
function M.enable()
  if not M.tracking then
    Util.debug("tracking on")
    M.layout = M.layout_wins()
    M.tracking = true
  end
end

-- disables tracking when layout changes
function M.is_enabled()
  if M.tracking then
    local layout = M.layout_wins()
    if not vim.deep_equal(layout, M.layout) then
      Util.debug("tracking off")
      M.tracking = false
    end
  end
  return M.tracking
end

-- get all windows in the current layout
function M.layout_wins()
  local queue = { vim.fn.winlayout() }
  ---@type table<number, number>
  local wins = {}
  while #queue > 0 do
    local node = table.remove(queue)
    if node[1] == "leaf" then
      wins[node[2]] = node[2]
    else
      vim.list_extend(queue, node[2])
    end
  end
  return wins
end

-- save view state for all windows in the current layout
-- that don't have a saved state yet
function M.save()
  -- skip if tracking is disabled
  -- Needed to prevent an issue with splitkeep
  -- https://github.com/vim/vim/pull/12488
  if not M.is_enabled() then
    return
  end

  local wins = M.layout_wins()
  for _, win in pairs(wins) do
    if not M.state[win] then
      M.update({ win = win })
    end
  end
end

-- restore view state for all edgebar windows only
function M.restore()
  local wins = Editor.list_wins().edgy
  for win, s in pairs(M.state) do
    if wins[win] and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      -- never restore terminal buffers to prevent flickering
      if vim.bo[buf].buftype ~= "terminal" then
        pcall(vim.api.nvim_win_call, win, function()
          vim.fn.winrestview(s)
        end)
        M.cursors[win] = vim.api.nvim_win_get_cursor(win)
      end
    else
      M.state[win] = nil
    end
  end
  M.enable()
end

-- wrap a function to save and restore view state
function M.wrap(fn)
  return function(...)
    M.save()
    local ok, ret = pcall(fn, ...)
    M.restore()
    if not ok then
      error(ret)
    end
    return ret
  end
end

return M
