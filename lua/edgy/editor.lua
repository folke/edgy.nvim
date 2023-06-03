local M = {}

function M.setup()
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("edgy_track", { clear = true }),
    callback = function(event)
      if event.event == "BufEnter" then
        vim.b.edgy_enter = vim.loop.hrtime()
      else
        vim.w.edgy_enter = vim.loop.hrtime()
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("edgy_track_closed", { clear = true }),
    nested = true,
    callback = M.check_main,
  })

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.w[win].edgy_enter = vim.w[win].edgy_enter or vim.loop.hrtime()
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.b[buf].edgy_enter = vim.b[buf].edgy_enter or vim.loop.hrtime()
  end
end

-- Ensures that there is always a main window
-- when a sidebar is visible
function M.check_main()
  local wins = M.list_wins()
  if vim.tbl_isempty(wins.main) and not vim.tbl_isempty(wins.edgy) then
    -- skip buffers shown in floating windows and edgy windows
    local skip = {}
    for _, win in pairs(wins.floating) do
      local buf = vim.api.nvim_win_get_buf(win)
      skip[buf] = buf
    end
    for _, win in pairs(wins.edgy) do
      local buf = vim.api.nvim_win_get_buf(win)
      skip[buf] = buf
    end

    -- get all other buffers
    ---@type buffer[]
    local bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if not skip[buf] then
        table.insert(bufs, buf)
      end
    end

    -- sort by last enter time
    table.sort(bufs, function(a, b)
      return (vim.b[a].edgy_enter or 0) > (vim.b[b].edgy_enter or 0)
    end)

    if #bufs > 0 then
      vim.cmd("botright sb " .. vim.api.nvim_buf_get_name(bufs[1]))
    else
      vim.cmd([[botright new]])
    end
  end
end

-- Returns a table of all windows in the current tab
-- grouped by edgy, main and floating
function M.list_wins()
  local Config = require("edgy.config")
  ---@class Edgy.list_wins
  local wins = {
    ---@type table<window, window>
    edgy = {},
    ---@type table<window, window>
    main = {},
    ---@type table<window, window>
    floating = {},
  }

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if M.is_floating(win) then
      wins.floating[win] = win
    else
      wins.main[win] = win
    end
  end

  for _, sidebar in pairs(Config.layout) do
    for _, win in ipairs(sidebar.wins) do
      wins.edgy[win.win] = win.win
      wins.main[win.win] = nil
    end
  end

  return wins
end

-- Move the cursor to the last entered main window
function M.goto_main()
  local wins = vim.tbl_values(M.list_wins().main)

  -- sort by last enter time
  table.sort(wins, function(a, b)
    return (vim.w[a].edgy_enter or 0) > (vim.w[b].edgy_enter or 0)
  end)

  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
  end
end

function M.is_floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

---@param win? window
function M.get_win(win)
  local Config = require("edgy.config")
  win = win or vim.api.nvim_get_current_win()
  for _, sidebar in pairs(Config.layout) do
    for _, w in ipairs(sidebar.wins) do
      if w.win == win then
        return w
      end
    end
  end
end

return M
