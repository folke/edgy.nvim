local M = {}

function M.setup()
  local ffi = require("ffi")
  ffi.cdef([[
    void win_setheight_win(int width, void *wp);
    void *find_window_by_handle(int window, void *err);
    bool skip_win_fix_cursor;
  ]])

  vim.api.nvim_win_set_height = function(win, height)
    if height < 0 or height > vim.o.lines then
      return
    end
    local win_t = ffi.C.find_window_by_handle(win, nil)
    if win_t == nil then
      return
    end
    ffi.C.skip_win_fix_cursor = win ~= vim.api.nvim_get_current_win()
    ffi.C.win_setheight_win(height, win_t)
    ffi.C.skip_win_fix_cursor = false
  end
end

return M
