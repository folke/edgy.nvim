---@type Edgy.Config
local M = {}

---@alias Edgy.Pos "bottom"|"top"|"left"|"right"

---@class Edgy.Config
local defaults = {
  left = {}, ---@type (Edgy.View.Opts|string)[]
  bottom = {}, ---@type (Edgy.View.Opts|string)[]
  right = {}, ---@type (Edgy.View.Opts|string)[]
  top = {}, ---@type (Edgy.View.Opts|string)[]

  ---@type table<Edgy.Pos, {size:integer, wo?:vim.wo}>
  options = {
    left = { size = 30 },
    bottom = { size = 10 },
    right = { size = 30 },
    top = { size = 10 },
  },
  -- edgebar animations
  animate = {
    enabled = true,
    fps = 30, -- frames per second
    cps = 120, -- cells per second
    on_begin = function()
      vim.g.minianimate_disable = true
    end,
    on_end = function()
      vim.g.minianimate_disable = false
    end,
    -- Spinner for pinned views that are loading.
    -- if you have noice.nvim installed, you can use any spinner from it, like:
    -- spinner = require("noice.util.spinners").spinners.circleFull,
    spinner = {
      frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      interval = 80,
    },
  },
  -- enable this to exit Neovim when only edgy windows are left
  exit_when_last = false,
  -- close edgy when all windows are hidden instead of opening one of them
  -- disable to always keep at least one edgy split visible in each open section
  close_when_all_hidden = true,
  -- global window options for edgebar windows
  ---@type vim.wo
  wo = {
    -- Setting to `true`, will add an edgy winbar.
    -- Setting to `false`, won't set any winbar.
    -- Setting to a string, will set the winbar to that string.
    winbar = true,
    winfixwidth = true,
    winfixheight = false,
    winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
    spell = false,
    signcolumn = "no",
  },
  -- buffer-local keymaps to be added to edgebar buffers.
  -- Existing buffer-local keymaps will never be overridden.
  -- Set to false to disable a builtin.
  ---@type table<string, fun(win:Edgy.Window)|false>
  keys = {
    -- close window
    ["q"] = function(win)
      win:close()
    end,
    -- hide window
    ["<c-q>"] = function(win)
      win:hide()
    end,
    -- close sidebar
    ["Q"] = function(win)
      win.view.edgebar:close()
    end,
    -- next open window
    ["]w"] = function(win)
      win:next({ visible = true, focus = true })
    end,
    -- previous open window
    ["[w"] = function(win)
      win:prev({ visible = true, focus = true })
    end,
    -- next loaded window
    ["]W"] = function(win)
      win:next({ pinned = false, focus = true })
    end,
    -- prev loaded window
    ["[W"] = function(win)
      win:prev({ pinned = false, focus = true })
    end,
    -- increase width
    ["<c-w>>"] = function(win)
      win:resize("width", 2)
    end,
    -- decrease width
    ["<c-w><lt>"] = function(win)
      win:resize("width", -2)
    end,
    -- increase height
    ["<c-w>+"] = function(win)
      win:resize("height", 2)
    end,
    -- decrease height
    ["<c-w>-"] = function(win)
      win:resize("height", -2)
    end,
    -- reset all custom sizing
    ["<c-w>="] = function(win)
      win.view.edgebar:equalize()
    end,
  },
  icons = {
    closed = " ",
    open = " ",
  },
  -- enable this on Neovim <= 0.10.0 to properly fold edgebar windows.
  -- Not needed on a nightly build >= June 5, 2023.
  fix_win_height = vim.fn.has("nvim-0.10.0") == 0,
  debug = false,
}

---@type Edgy.Config
local options

---@type table<Edgy.Pos, Edgy.Edgebar>
M.layout = {}

---@param opts? Edgy.Config
function M.setup(opts)
  local Edgebar = require("edgy.edgebar")
  local Layout = require("edgy.layout")

  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  options = opts

  for _, pos in ipairs({ "bottom", "top", "right", "left" }) do
    local views = options[pos] or {}
    if #views > 0 then
      M.layout[pos] =
        Edgebar.new(pos, vim.tbl_deep_extend("force", options.options[pos], { views = views }))
    end
  end

  if options.fix_win_height then
    require("edgy.hacks").setup()
  end

  vim.api.nvim_set_hl(0, "EdgyIcon", { default = true, link = "SignColumn" })
  vim.api.nvim_set_hl(0, "EdgyIconActive", { default = true, link = "Constant" })
  vim.api.nvim_set_hl(0, "EdgyTitle", { default = true, link = "Title" })
  vim.api.nvim_set_hl(0, "EdgyWinBar", { default = true, link = "Winbar" })
  vim.api.nvim_set_hl(0, "EdgyNormal", { default = true, link = "NormalFloat" })

  require("edgy.editor").setup()
  require("edgy.state").setup()

  local group = vim.api.nvim_create_augroup("layout", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinResized" }, {
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
