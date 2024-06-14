--- vim.uv

local Layout = require("edgy.layout")
local Util = require("edgy.util")
local Config = require("edgy.config")

local uv = vim.uv or vim.loop

local M = {}

---@class Edgy.Animate
---@field height number
---@field width number
---@field topline number
---@field view WinView

---@type table<Edgy.Window, Edgy.Animate>
M.state = setmetatable({}, { __mode = "k" })
M.timer = uv.new_timer()

---@param win Edgy.Window
function M.get_state(win)
  if not M.state[win] then
    local edgebar = win.view.edgebar
    local long = edgebar.vertical and "height" or "width"
    local short = edgebar.vertical and "width" or "height"
    local bounds = {
      width = vim.api.nvim_win_get_width(win.win),
      height = vim.api.nvim_win_get_height(win.win),
    }
    local hidden_size = edgebar.vertical and (vim.o.laststatus == 1 or vim.o.laststatus == 2) and 2
      or 1
    ---@diagnostic disable-next-line: missing-fields
    M.state[win] = {
      [long] = #edgebar.wins == 1 and bounds[long] or hidden_size,
      [short] = #edgebar.wins == 1 and 1
        or (type(edgebar.size) == "function" and edgebar.size() or edgebar.size),
      view = vim.api.nvim_win_call(win.win, vim.fn.winsaveview),
    }
    for _, w in ipairs(edgebar.wins) do
      M.state[win][short] = math.max(M.state[win][short], M.state[w] and M.state[w][short] or 0)
    end
  end
  return M.state[win]
end

---@param win Edgy.Window
function M.step(win, step)
  step = step or (Config.animate.cps / Config.animate.fps)
  local state = M.get_state(win)
  local updated = false
  local buf = vim.api.nvim_win_get_buf(win.win)
  for _, key in ipairs({ "width", "height" }) do
    local current = vim.api["nvim_win_get_" .. key](win.win)
    local dim = win[key]
    if dim and type(dim) == "function" then
      dim = dim()
    end
    if vim.bo[buf].buftype == "terminal" then
      state[key] = dim
    else
      if dim and state[key] ~= dim then
        if state[key] > dim then
          state[key] = math.max(state[key] - step, dim)
        else
          state[key] = math.min(state[key] + step, dim)
        end
      end
    end
    if current ~= state[key] then
      vim.api["nvim_win_set_" .. key](win.win, math.floor(state[key] + 0.5))
    end
    updated = updated or current ~= dim
  end
  return updated
end

function M.wins()
  local wins = {} ---@type Edgy.Window[]
  Layout.foreach({ "bottom", "top", "left", "right" }, function(edgebar)
    for _, win in ipairs(edgebar.wins) do
      if win:is_valid() then
        wins[#wins + 1] = win
      end
    end
  end)
  return wins
end

function M.animate(step)
  local wins = M.wins()

  local views = {} ---@type table<Edgy.Window, WinView>
  for _, win in ipairs(wins) do
    views[win] = vim.api.nvim_win_call(win.win, vim.fn.winsaveview)
  end

  local updated = false
  for _, win in ipairs(wins) do
    if M.step(win, step) then
      updated = true
    end
  end

  for win, view in pairs(views) do
    vim.api.nvim_win_call(win.win, function()
      local height = vim.api.nvim_win_get_height(0)
      local topline_min = math.max(view.lnum - height + 1, 1)
      local topline_max = view.lnum
      local topline = math.min(topline_max, math.max(topline_min, M.state[win].view.topline))
      vim.fn.winrestview({ lnum = view.lnum, topline = topline })
    end)
  end
  return updated
end

M.animate = Util.noautocmd(M.animate)

function M.is_active()
  return M.timer:is_active()
end

function M.stop()
  M.timer:stop()
end

function M.update()
  if M.is_active() then
    return
  end

  for _, win in ipairs(M.wins()) do
    if M.state[win] then
      -- update topline for existing windows
      M.state[win].view = vim.api.nvim_win_call(win.win, vim.fn.winsaveview)
    end
  end

  Config.animate.on_begin()

  if M.animate(0) then
    local step = 0
    local ms = 1000 / Config.animate.fps
    M.timer:start(
      ms,
      ms,
      vim.schedule_wrap(function()
        step = step + 1
        if not M.animate() then
          M.timer:stop()
          Config.animate.on_end()
          Util.debug("animation complete")
        end
      end)
    )
  end
end

return M
