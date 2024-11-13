local function hex(map, x, y, terrain)
  local node = {
    x = x,
    y = y,
    terrain = terrain or "Gg"
  }

  function node:neighbour(dir)
    return map:get(dir:translate(self.x, self.y))
  end

  return node
end

local function tag_open_from(tag, node)
  if not node then return end
  if not node.open_from then return end
  if node.open_from == true then
    node.open_from = tag
  else
    node.open_from = (tag and tag.x == node.open_from.x and tag.y == node.open_from.y and tag) or nil
  end
end

local function maze_hex(map, x, y, terrain)
  local node = hex(map, x, y, terrain)
  node.open_from = true

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
  new = hex,
  maze_hex = maze_hex
}
