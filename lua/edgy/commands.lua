local Editor = require("edgy.editor")

---@class Edgy.Commands
local M = {}

M.goto_main = Editor.goto_main
M.get_win = Editor.get_win
M.close = Editor.close
M.open = Editor.open
M.toggle = Editor.toggle
M.select = Editor.select

return M
