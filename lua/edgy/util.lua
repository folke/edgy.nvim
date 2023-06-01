local M = {}

function M.try(fn)
  if package.loaded["lazy.core.util"] then
    return require("lazy.core.util").try(fn)
  end
  local ok, err = pcall(fn)
  if not ok then
    M.error(err)
  end
end

function M.notify(msg, level)
  vim.notify(msg, level, { title = "edgy.nvim" })
end

function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

return M
