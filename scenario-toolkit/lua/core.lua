function as_table(iter)
  local t = {}
  for item in iter do
    table.insert(t, item)
  end
  return t
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

function display_table(t)
  for k, v in pairs(t) do
    print(string.format("%s = %s", k, v))
  end
end

int = require("int")
