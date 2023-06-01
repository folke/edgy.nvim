local M = {}

function M.setup()
  local ffi = require("ffi")
  ffi.cdef([[
    void win_setheight_win(int width, void *wp);
    void *find_window_by_handle(int window, void *err);
  ]])

  vim.api.nvim_win_set_height = function(win, height)
    if height < 0 or height > vim.o.lines then
      return
    end
    local win_t = ffi.C.find_window_by_handle(win, nil)
    if win_t == nil then
      return
    end
    ffi.C.win_setheight_win(height, win_t)
  end
end

return M
