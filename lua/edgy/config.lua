local M = {}

---@alias Edgy.Pos "bottom"|"top"|"left"|"right"

---@class Edgy.Config
local defaults = {
  ---@type table<Edgy.Pos, Edgy.Sidebar.Opts>
  layout = {},
  icons = {
    closed = " ",
    open = " ",
  },
  hacks = true,
  ---@type vim.wo
  wo = {
    winbar = true,
    winfixwidth = true,
    winfixheight = false,
    winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
    spell = false,
    signcolumn = "no",
  },
  debug = true,
}

---@type Edgy.Config
local options

---@type table<Edgy.Pos, Edgy.Sidebar>
M.layout = {}

---@param opts? Edgy.Config
function M.setup(opts)
  local Sidebar = require("edgy.sidebar")
  local Layout = require("edgy.layout")

  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  options = opts

  for pos, s in pairs(opts.layout) do
    M.layout[pos] = Sidebar.new(pos, s)
  end

  if options.hacks then
    require("edgy.hacks").setup()
  end

  vim.api.nvim_set_hl(0, "EdgyIcon", { default = true, link = "SignColumn" })
  vim.api.nvim_set_hl(0, "EdgyTitle", { default = true, link = "Title" })
  vim.api.nvim_set_hl(0, "EdgyWinBar", { default = true, link = "Winbar" })
  vim.api.nvim_set_hl(0, "EdgyNormal", { default = true, link = "NormalFloat" })

  require("edgy.editor").setup()

  local group = vim.api.nvim_create_augroup("layout", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "WinNew", "WinResized" }, {
    group = group,
    callback = Layout.update,
  })
  vim.api.nvim_create_autocmd({ "FileType", "VimResized" }, {
    callback = function()
      vim.schedule(Layout.update)
    end,
  })
  Layout.update()
end

return setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    ---@cast options Edgy.Config
    return options[key]
  end,
})
