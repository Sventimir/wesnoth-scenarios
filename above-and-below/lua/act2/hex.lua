local function north(x, y)
  return x, y - 1
end
local function northeast(x, y)
  return x + 1, y - (x % 2)
end
local function southeast(x, y)
  return x + 1, y - (x % 2) + 1
end
local function south(x, y)
  return x, y + 1
end
local function southwest(x, y)
  return x - 1, y - (x % 2) + 1
end
local function northwest(x, y)
  return x - 1, y - (x % 2)
end

local directions = {
  n = { counterclockwise = "nw", clockwise = "ne", opposite = "s", translate = north },
  ne = { counterclockwise = "n", clockwise = "se", opposite = "sw", translate = northeast },
  se = { counterclockwise = "ne", clockwise = "s", opposite = "nw", translate = southeast },
  s = { counterclockwise = "se", clockwise = "sw", opposite = "n", translate = south },
  sw = { counterclockwise = "s", clockwise = "nw", opposite = "ne", translate = southwest },
  nw = { counterclockwise = "sw", clockwise = "n", opposite = "se", translate = northwest }
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

local function path_open(src, target)
  if target and target.open_from then
    local open_from = target.open_from
    return open_from == true or (open_from.x == src.x and open_from.y == src.y)
  else
    return false
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
    return labirynth:get(dir.translate(self.x, self.y))
  end
  
  function node:path_to(dir, terrain)
    local target = self:neighbour(dir)
    target.open_from = nil
    target.terrain = terrain
    if target.x == 1 or target.x == labirynth.width or target.y == 1 or target.y == labirynth.height then
      table.insert(labirynth.exits, target)
    end
    hex.tag_open_from(nil, self:neighbour(directions[dir.counterclockwise]))
    local dir_to_mark = dir.clockwise
    hex.tag_open_from(nil, self:neighbour(directions[dir_to_mark]))
    for i = 1, 3 do
      dir_to_mark = directions[dir_to_mark].clockwise
      hex.tag_open_from(self, self:neighbour(directions[dir_to_mark]))
    end
    local target_dir = directions[directions[dir.opposite].clockwise]
    for i = 1, 3 do
      target_dir = directions[target_dir.clockwise]
      hex.tag_open_from(target, target:neighbour(target_dir))
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
  node = node,
  north = north,
  northeast = northeast,
  southeast = southeast,
  south = south,
  southwest = southwest,
  northwest = northwest,
  tag_open_from = tag_open_from,
  path_open = path_open
}
