return function(width, height, node, terrain)
  local map = {
    width = width,
    height = height,
    default_terrain = terrain
  }

  for y = 0, height do
    local row = {}
    for x = 0, width do
      row[x] = node(map, x, y, terrain)
    end
    map[y] = row
  end

  function map:get(x, y)
    return (self[y] or {})[x]
  end

  function map:as_map_data()
    local map = ""

    for y = 0, self.height do
      local row = self[y]
      for x = 0, self.width do
        local node = row[x]
        if node.starting_player then
          map = map .. node.starting_player .. " "
        end
        if x < self.width then
          map = map .. node.terrain .. ", "
        else
          map = map .. node.terrain .. "\n"
        end
      end
    end

    return map
  end

  return map
end
