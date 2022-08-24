local store = {}

local cache = {}

---@generic P : any[]
---@generic R : any
---@param fn fun(...: P): R
---@param make_key fun(...: P): string
---@return fun(...: P): R
function cache.wrap(fn, make_key)
  store[fn] = {}

  return function(...)
    local key = make_key(...)

    if store[fn][key] == nil then
      store[fn][key] = fn(...) or false
    end

    return store[fn][key]
  end
end

return cache
