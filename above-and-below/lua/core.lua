if not pcall(function() return require end) then
  require = wesnoth.require
end

function as_table(iter, state, ctrl)
  local t = {}
  for item in iter, state, ctrl do
    table.insert(t, item)
  end
  return t
end

function iter(tbl)
  local i = 0
  return function()
    i = i + 1
    return tbl[i]
  end
end

function take(n, iter, state, ctrl)
  local i = 0
  return function(_, ctrl)
    i = i + 1
    if i <= n then
      return iter(state, ctrl)
    end
  end
end


function drop(n, iter, state, ctrl)
  for _ = 1, n do
    iter()
  end
  return function(_, ctrl)
    return iter(state, ctrl)
  end
end


function map(f, iter, state, ctrl)
  local state = { ctrl = ctrl, intern = state }
  return function(_, ctrl)
    state.ctrl = iter(state.intern, state.ctrl)
    if state.ctrl == nil then
      return nil
    else
      return f(state.ctrl)
    end
  end
end

function fold(f, acc, iter, state, ctrl)
  local res = acc
  for item in iter, state, ctrl do
    res = f(res, item)
  end
  return res
end

function filter(predicate, iter, state, ctrl)
  local state = { ctrl = ctrl, intern = state }
  return function(_, ctrl)
    state.ctrl = iter(state.intern, state.ctrl)
    while state.ctrl ~= nil and not predicate(state.ctrl) do
      state.ctrl = iter(state.intern, state.ctrl)
    end
    return state.ctrl
  end
end

function filter_map(f, iter, state, ctrl)
  local state = { ctrl = ctrl, intern = state }
  return function()
    state.ctrl = iter(state.intern, state.ctrl)
    while state.ctrl ~= nil do
      local res = f(state.ctrl)
      if res ~= nil then
        return res
      else
        state.ctrl = iter(state.intern, state.ctrl)
      end
    end
  end
end

function zip(iter1, iter2)
  return function() 
    local x = iter1()
    local y = iter2()
    if x and y then
      return x, y
    end
  end
end

function cycle(tbl)
  local i = 0
  return function()
    if i < #tbl then
      i = i + 1
    else
      i = 1
    end
    return tbl[i]
  end
end

function chain(...)
  local iters = {...}
  local i = 1
  return function()
    local item = iters[i]()
    while item == nil and i < #iters do
      i = i + 1
      item = iters[i]()
    end
    return item
  end
end

-- Returns the first item (if any) in the iterator that satisfies the predicate.
function any(iterator, f)
  for item in iterator do
    if f == nil or f(item) then
      return item
    end
  end
end

function all(f, iterator)
  for item in iterator do
    if not f(item) then
      return false
    end
  end
  return true
end

function get(key)
  return function(tbl)
    return tbl[key]
  end
end

function display_table(t)
  print("table:")
  for k, v in pairs(t) do
    print(string.format("%s = %s", k, v))
  end
end

function keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

int = require("int")
str = require("str")
