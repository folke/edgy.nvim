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
        vim.keymap.set("n", key, function()
          local current_win = require("edgy.editor").get_win()
          if current_win ~= nil then
            action(current_win)
          end
        end, { buffer = buf, silent = true })
      end
    end
  end
end

return M
