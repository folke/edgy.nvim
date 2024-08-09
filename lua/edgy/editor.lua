local Config = require("edgy.config")

local M = {}

local uv = vim.uv or vim.loop

function M.setup()
  local group = vim.api.nvim_create_augroup("edgy_track", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    group = group,
    callback = function(event)
      if event.event == "BufEnter" then
        vim.b.edgy_enter = uv.hrtime()
      else
        vim.w.edgy_enter = uv.hrtime()
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    nested = true,
    callback = M.check_main,
  })

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.w[win].edgy_enter = vim.w[win].edgy_enter or uv.hrtime()
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.b[buf].edgy_enter = vim.b[buf].edgy_enter or uv.hrtime()
  end
end

-- Ensures that there is always a main window
-- when a edgebar is visible
function M.check_main()
  local wins = M.list_wins()

  if vim.tbl_isempty(wins.edgy) or not vim.tbl_isempty(wins.main) then
    return
  end

  if Config.exit_when_last then
    vim.cmd([[qa]])
  end

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
    vim.cmd("botright sb " .. bufs[1])
  else
    vim.cmd([[botright new]])
  end
end

-- Returns a table of all windows in the current tab
-- grouped by edgy, main and floating
function M.list_wins()
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

  for _, edgebar in pairs(Config.layout) do
    for _, win in ipairs(edgebar.wins) do
      wins.edgy[win.win] = win.win
      wins.main[win.win] = nil
    end
  end

  return wins
end

---@param pos? Edgy.Pos
---@param filter? fun(win:Edgy.Window):boolean
function M.select(pos, filter)
  local wins = {}
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      for _, win in ipairs(edgebar.wins) do
        if filter == nil or filter(win) then
          wins[#wins + 1] = win
        end
      end
    end
  end
  vim.ui.select(
    wins,
    {
      prompt = "Select Edgy Window:",
      ---@param w Edgy.Window
      format_item = function(w)
        local title = w.view.get_title()
        if pos == nil then
          title = "[" .. w.view.edgebar.pos .. "] " .. title
        end
        return title
      end,
      kind = "edgy.window",
    },
    ---@param win? Edgy.Window
    function(win)
      if win then
        win:focus()
      end
    end
  )
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

---@param win integer? A window ID
function M.get_win(win)
  win = win or vim.api.nvim_get_current_win()
  for _, edgebar in pairs(Config.layout) do
    for _, w in ipairs(edgebar.wins) do
      if w.win == win then
        return w
      end
    end
  end
end

---@param pos? Edgy.Pos
function M.close(pos)
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      edgebar:close()
    end
  end
end

---@param pos? Edgy.Pos
function M.open(pos)
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      edgebar:open()
    end
  end
end

---@param pos? Edgy.Pos
function M.equalize(pos)
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      edgebar:equalize()
    end
  end
end

---@param pos? Edgy.Pos
function M.toggle(pos)
  local has_open = false
  for p, edgebar in pairs(Config.layout) do
    if p == pos or pos == nil then
      if #edgebar.wins > 0 then
        has_open = true
      end
    end
  end
  if has_open then
    M.close(pos)
  else
    M.open(pos)
  end
end

return M
