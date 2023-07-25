local Config = require("edgy.config")

---@class Edgy.Window
---@field visible boolean
---@field view Edgy.View
---@field win window
---@field width? number
---@field height? number
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

  ---@type vim.wo
  local wo = vim.tbl_deep_extend("force", {}, Config.wo, view.edgebar.wo or {}, view.wo or {})

  if wo.winbar == true then
    if vim.api.nvim_win_get_height(win) == 1 then
      vim.api.nvim_win_set_height(win, 2)
    end
    wo.winbar = "%!v:lua.edgy_winbar(" .. win .. ")"
  elseif wo.winbar == false then
    wo.winbar = nil
  end
  for k, v in pairs(wo) do
    -- special treatment for winhighlight
    -- add to existing winhighlight
    if k == "winhighlight" then
      local whl = vim.split(vim.wo[self.win].winhighlight, ",")
      vim.list_extend(whl, vim.split(v, ","))
      whl = vim.tbl_filter(function(hl)
        return hl ~= ""
      end, whl)
      v = table.concat(whl, ",")
    end
    vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
  end
  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(event)
      if tonumber(event.match) == self.win then
        self.view.edgebar:on_hide(self)
        return true
      end
    end,
  })
  require("edgy.actions").setup(self)
  return self
end

---@param dim "width" | "height"
function M:dim(dim)
  return vim.w[self.win]["edgy_" .. dim] or self.view.size[dim]
end

function M:is_valid()
  return vim.api.nvim_win_is_valid(self.win)
end

---@param visibility? boolean
function M:show(visibility)
  self.visible = visibility == nil and true or visibility or false
  if self.visible and self:is_pinned() then
    -- self.visible = false
    return self.view:open_pinned()
  end

  if not self.visible then
    self.view.edgebar:on_hide(self)
  end

  vim.cmd([[redrawstatus!]])
  require("edgy.layout").update()
end

function M:hide()
  self:show(false)
end

function M:close()
  vim.api.nvim_win_close(self.win, false)
end

---@param opts? {pinned?:boolean, visible?:boolean, focus?:boolean}
function M:next(opts)
  return self:sibling("next", opts)
end

---@param opts? {pinned?:boolean, visible?:boolean, focus?:boolean}
function M:prev(opts)
  return self:sibling("prev", opts)
end

---@param dir "next" | "prev"
---@param opts? {pinned?:boolean, visible?:boolean, focus?:boolean}
function M:sibling(dir, opts)
  opts = opts or {}
  local inc = dir == "next" and 1 or -1
  local idx = self.idx + inc
  while self.view.edgebar.wins[idx] do
    local win = self.view.edgebar.wins[idx]
    if
      (opts.pinned == nil or opts.pinned == win:is_pinned())
      and (opts.visible == nil or opts.visible == win.visible)
    then
      if opts.focus then
        win:focus()
      end
      return win
    end
    idx = idx + inc
  end
end

function M:focus()
  vim.api.nvim_set_current_win(self.win)
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
  local icon_hl = self:is_pinned() and not self.view.opening and "EdgyIcon" or "EdgyIconActive"
  local icon = self.visible and Config.icons.open or Config.icons.closed
  if self.view.opening then
    local spinner = Config.animate.spinner
    local ms = vim.loop.hrtime() / 1000000
    local frame = math.floor(ms / spinner.interval) % #spinner.frames
    icon = spinner.frames[frame + 1]
  end

  parts[#parts + 1] = "%#" .. icon_hl .. "#" .. icon .. "%*%<"
  parts[#parts + 1] = "%#EdgyTitle# " .. self.view.title .. "%*"
  parts[#parts + 1] = "%T"

  return table.concat(parts)
end

function M:needs_resize()
  return self.width ~= vim.api.nvim_win_get_width(self.win)
    or self.height ~= vim.api.nvim_win_get_height(self.win)
end

-- Resize the given dimension by the given amount
-- When amount is nil, reset to the default size
---@param dim "width" | "height"
---@param amount number? Defaults to 2
function M:resize(dim, amount)
  local value = vim.w[self.win]["edgy_" .. dim] or self[dim]
  value = value + (amount or 0)
  if not amount or value == self[dim] then
    vim.w[self.win]["edgy_" .. dim] = nil
    return
  end
  vim.w[self.win]["edgy_" .. dim] = value
  require("edgy.layout").update()
end

function M:apply_size()
  if not self:is_valid() then
    return
  end

  local changes = {}
  for _, key in ipairs({ "width", "height" }) do
    local current = vim.api["nvim_win_get_" .. key](self.win)
    local needed = self[key]
    if type(needed) == "function" then
      needed = needed()
    end
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
