local Util = require("edgy.util")
local Config = require("edgy.config")
local Editor = require("edgy.editor")

---@class Edgy.Window
---@field visible boolean
---@field view Edgy.View
---@field win window
---@field width? number
---@field height? number
---@field opening boolean
---@field idx integer
local M = {}
M.__index = M

---@type table<window, Edgy.Window>
M.cache = setmetatable({}, { __mode = "v" })

---@param win window
---@param view Edgy.View
function M.new(win, view)
  local self = setmetatable({}, M)
  self.visible = true
  self.view = view
  self.idx = 1
  self.win = win
  M.cache[win] = self
  self.opening = false

  ---@type vim.wo
  local wo = vim.tbl_deep_extend("force", {}, Config.wo, view.sidebar.wo or {}, view.wo or {})

  if wo.winbar == true then
    if vim.api.nvim_win_get_height(win) == 1 then
      vim.api.nvim_win_set_height(win, 2)
    end
    wo.winbar = "%!v:lua.edgy_winbar(" .. win .. ")"
  elseif wo.winbar == false then
    wo.winbar = nil
  end
  for k, v in pairs(wo) do
    vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
  end
  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(event)
      if tonumber(event.match) == self.win then
        self.view.sidebar:on_hide(self)
        return true
      end
    end,
  })
  require("edgy.actions").setup(self)
  return self
end

function M:is_valid()
  return vim.api.nvim_win_is_valid(self.win)
end

---@param visibility? boolean
function M:show(visibility)
  self.visible = visibility == nil and true or visibility or false
  if self.visible and self:is_pinned() then
    -- self.visible = false
    return self:open()
  end

  if not self.visible then
    self.view.sidebar:on_hide(self)
  end

  vim.cmd([[redrawstatus!]])
  self.view.sidebar:resize()
end

function M:hide()
  self:show(false)
end

function M:close()
  vim.api.nvim_win_close(self.win, false)
end

function M:open()
  if self.opening then
    return
  end
  self.opening = true
  vim.schedule(function()
    Editor:goto_main()
    if type(self.view.open) == "function" then
      Util.try(self.view.open)
    elseif type(self.view.open) == "string" then
      Util.try(function()
        vim.cmd(self.view.open)
      end)
    else
      Util.error("View is pinned and has no open function")
    end
  end)
end

function M:is_pinned()
  return self.view.pinned_win == self
end

function M:toggle()
  self:show(not self.visible)
end

function M:winbar()
  ---@type string[]
  local parts = {}

  parts[#parts + 1] = "%" .. self.win .. "@v:lua.edgy_click@"
  local icon_hl = self:is_pinned() and "EdgyIcon" or "EdgyIconActive"
  parts[#parts + 1] = "%#"
    .. icon_hl
    .. "#"
    .. (self.visible and Config.icons.open or Config.icons.closed)
    .. "%*%<"
  parts[#parts + 1] = "%#EdgyTitle# " .. self.view.title .. "%*"
  parts[#parts + 1] = "%T"

  return table.concat(parts)
end

function M:resize()
  if not self:is_valid() then
    return
  end

  local changes = {}
  for _, key in ipairs({ "width", "height" }) do
    local current = vim.api["nvim_win_get_" .. key](self.win)
    local needed = self[key]
    if current ~= needed then
      changes[key] = { current, needed }
      vim.api["nvim_win_set_" .. key](self.win, needed)
    end
  end
  return changes
end

---@diagnostic disable-next-line: global_usage
function _G.edgy_winbar(win)
  local window = M.cache[win]
  return window and window:winbar() or ""
end

---@diagnostic disable-next-line: global_usage
function _G.edgy_click(win)
  local window = M.cache[win]
  if window then
    window:toggle()
  end
end

return M
