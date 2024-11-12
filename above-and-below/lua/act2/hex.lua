local translations = {
  [0] = function(x, y) return x, y - 1 end, --north
  [1] = function(x, y) return x + 1, y - (x % 2) end, --northeast
  [2] = function(x, y) return x + 1, y - (x % 2) + 1 end, --southeast
  [3] = function(x, y) return x, y + 1 end, --south
  [4] = function(x, y) return x - 1, y - (x % 2) + 1 end, --southwest
  [5] = function(x, y) return x - 1, y - (x % 2) end, --northwest
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

  function dir:translate(x, y)
    return translations[self.value](x, y)
  end

  return dir
end

local directions = {
  n = direction(0),
  ne = direction(1),
  se = direction(2),
  s = direction(3),
  sw = direction(4),
  nw = direction(5),
  random = function() return direction(mathx.random(0, 5)) end,
  all = function() return map(direction, take(6, int.nats())) end
}

local function tag_open_from(tag, node)
  if not node then return end
  if not node.open_from then return end
  if node.open_from == true then
    node.open_from = tag
  else
    node.open_from = (tag and tag.x == node.open_from.x and tag.y == node.open_from.y and tag) or nil
  end
end

local function node(labirynth, x, y)
  local node = {
    x = x,
    y = y,
    terrain = "Xu",
    open_from = true
  }
  
  function node:neighbour(dir)
    return labirynth:get(dir:translate(self.x, self.y))
  end

  function node:path_open_to(target)
    if target and target.open_from then
      local open_from = target.open_from
      return open_from == true or (open_from.x == self.x and open_from.y == self.y)
    else
      return false
    end
  end

  function node:path_to(dir, terrain)
    local target = self:neighbour(dir)
    target.open_from = nil
    target.terrain = terrain
    if target.x == 1 or target.x == labirynth.width or target.y == 1 or target.y == labirynth.height then
      table.insert(labirynth.exits, target)
    end
    tag_open_from(nil, self:neighbour(dir:counterclockwise()))
    local dir_to_mark = dir:clockwise()
    tag_open_from(nil, self:neighbour(dir_to_mark))
    for i = 1, 3 do
      dir_to_mark = dir_to_mark:clockwise()
      tag_open_from(self, self:neighbour(dir_to_mark))
    end
    local target_dir = dir:opposite():clockwise()
    for i = 1, 3 do
      target_dir = target_dir:clockwise()
      tag_open_from(target, target:neighbour(target_dir))
    end
    return target
    end

  function node:label_turn_visited()
    return {"label", {x = x, y = y, text = node.turn_visited}}
  end
  
  return node
end

return {
  directions = directions,
  node = node
}
