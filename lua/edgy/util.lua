local M = {}

---@param opts {finally:fun()}
function M.try(fn, opts)
  opts = opts or {}
  local ok, err = pcall(fn)

  if opts.finally then
    pcall(opts.finally)
  end

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

function M.info(msg)
  M.notify(msg, vim.log.levels.INFO)
end

function M.debug(msg)
  if require("edgy.config").debug then
    M.info(msg)
  end
end

---@generic F: fun()
---@param fn F
---@param max_retries? number
---@return F
function M.with_retry(fn, max_retries)
  max_retries = max_retries or 3
  local retries = 0
  local function try()
    local ok, ret = pcall(fn)
    if ok then
      retries = 0
    else
      if retries >= max_retries or require("edgy.config").debug then
        M.error(ret)
      end
      if retries < max_retries then
        return vim.schedule(try)
      end
    end
  end
  return try
end

---@generic F: fun()
---@param fn F
---@return F
function M.noautocmd(fn)
  return function(...)
    vim.o.eventignore = "all"
    local ok, ret = pcall(fn, ...)
    vim.o.eventignore = ""
    if not ok then
      error(ret)
    end
    return ret
  end
end

--- @generic F: function
--- @param fn F
--- @param ms? number
--- @return F
function M.throttle(fn, ms)
  ms = ms or 200
  local timer = assert(vim.loop.new_timer())
  local waiting = 0
  return function()
    if timer:is_active() then
      waiting = waiting + 1
      return
    end
    waiting = 0
    fn() -- first call, execute immediately
    timer:start(ms, 0, function()
      if waiting > 1 then
        vim.schedule(fn) -- only execute if there are calls waiting
      end
    end)
  end
end

--- @generic F: function
--- @param fn F
--- @param ms? number
--- @return F
function M.debounce(fn, ms)
  ms = ms or 50
  local timer = assert(vim.loop.new_timer())
  local waiting = 0
  return function()
    if timer:is_active() then
      waiting = waiting + 1
    else
      waiting = 0
      fn()
    end
    timer:start(ms, 0, function()
      if waiting then
        vim.schedule(fn) -- only execute if there are calls waiting
      end
    end)
  end
end

return M
