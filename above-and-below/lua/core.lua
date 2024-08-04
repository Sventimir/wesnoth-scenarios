if not pcall(function() return require end) then
  require = wesnoth.require
end

function as_table(iter)
  local t = {}
  for item in iter do
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

function take(n, iter)
  local i = 0
  return function()
    i = i + 1
    if i <= n then
      return iter()
    end
  end
end


function drop(n, iter)
  for _ = 1, n do
    iter()
  end
  return function()
    return iter()
  end
end


function map(f, iter)
  return function()
    local item = iter()
    if item == nil then
      return nil
    else
      return f(item)
    end
  end
end

function fold(f, acc, iter)
  local res = acc
  for item in iter do
    res = f(res, item)
  end
  return res
end

function filter(predicate, iter)
  return function()
    local item = iter()
    while item ~= nil and not predicate(item) do
      item = iter()
    end
    return item
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

int = require("int")
str = require("str")
