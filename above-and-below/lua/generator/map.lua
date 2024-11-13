return function(width, height, node, terrain)
  local map = {
    width = width,
    height = height,
    default_terrain = terrain
  }

  for y = 1, height do
    local row = {}
    for x = 1, width do
      table.insert(row, node(map, x, y, terrain))
    end
    table.insert(map, row)
  end

  function map:get(x, y)
    return (self[y] or {})[x]
  end

  function map:as_map_data()
    local map = ""
    for x = 0, self.width + 1 do
      map = map .. "Xu"
      if x < self.width + 1 then
        map = map .. ", "
      else
        map = map .. "\n"
      end
    end
    for y, row in ipairs(self) do
      map = map .. "Xu, "
      for x, node in ipairs(row) do
        if node.starting_player then
          map = map .. node.starting_player .. " "
        end
        map = map .. node.terrain .. ", "
      end
      map = map .. "Xu\n"
    end
    for x = 0, self.width + 1 do
      map = map .. "Xu"
      if x < self.width + 1 then
        map = map .. ", "
      end
    end
    return map
  end

  return map
end
