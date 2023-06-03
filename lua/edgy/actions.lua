local Config = require("edgy.config")

local M = {}

---@param win Edgy.Window
function M.setup(win)
  local buf = vim.api.nvim_win_get_buf(win.win)
  if vim.b[buf].edgy_keys then
    return
  end
  vim.b[buf].edgy_keys = true
  for key, action in pairs(Config.keys) do
    if action then
      local ret = vim.fn.maparg(key, "n", false, true)
      -- dont override existing mappings
      if ret.buffer ~= 1 then
        local rhs = type(action) == "function" and action
          or function()
            local w = require("edgy.editor").get_win()
            M[action](w)
          end
        vim.keymap.set("n", key, rhs, { buffer = buf, silent = true })
      end
    end
  end
end

---@param win Edgy.Window
function M.close(win)
  vim.api.nvim_win_close(win.win, false)
end

---@param win Edgy.Window
function M.hide(win)
  win:show(false)
end

---@param win Edgy.Window
function M.close_sidebar(win)
  require("edgy").close(win.view.sidebar.pos)
end

return M
