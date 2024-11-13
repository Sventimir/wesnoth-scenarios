local translations = {
  [0] = function(x, y, d) return x, y - 1 * d end, --north
  [1] = function(x, y, d) return x + 1, y - mathx.floor(d / 2) - (x % 2) end, --northeast
  [2] = function(x, y, d) return x + 1, y + mathx.floor(d / 2) + 1 - (x % 2) end, --southeast
  [3] = function(x, y, d) return x, y + 1 * d end, --south
  [4] = function(x, y, d) return x - 1, y + mathx.floor(d / 2) + 1 - (x % 2) end, --southwest
  [5] = function(x, y, d) return x - 1, y - mathx.floor(d / 2) - (x % 2) end, --northwest
}

local function direction(value)
  local dir = { value = value % 6 }

  function dir:opposite()
    return direction(self.value + 3)
  end

  function dir:clockwise()
    return direction(self.value + 1)
  end

  function dir:counterclockwise()
    return direction(self.value + 5)
  end

  function dir:rotate(times, counterclockwise)
    if counterclockwise == "random" then
      counterclockwise = mathx.random(0, 1) == 1
    end
    if counterclockwise then
      return direction(self.value + 5 * times)
    else
      return direction(self.value + times)
    end
  end

  function dir:translate(x, y, distance)
    return translations[self.value](x, y, distance or 1)
  end

  return dir
end

return {
  n = direction(0),
  ne = direction(1),
  se = direction(2),
  s = direction(3),
  sw = direction(4),
  nw = direction(5),
  random = function() return direction(mathx.random(0, 5)) end,
  all = function() return map(direction, take(6, int.nats())) end
}
