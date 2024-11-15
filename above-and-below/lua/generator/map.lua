wesnoth.require("~add-ons/above-and-below/lua/generator/hex.lua")

Map = {}
Map.__index = Map

function Map.new(width, height, terrain)
  local m = setmetatable({ width = width, height = height, default_terrain = terrain }, Map)

  for y = 0, height + 1 do
    local row = {}
    for x = 0, width + 1 do
      row[x] = Hex.new(m, x, y, terrain)
    end
    m[y] = row
  end

  return m
end

function Map:get(x, y)
  return (self[y] or {})[x]
end

function Map:as_map_data()
  local map = ""
  
  for y = 0, self.height + 1 do
    local row = self[y]
    for x = 0, self.width + 1 do
      local node = row[x]
      if node.starting_player then
        map = map .. node.starting_player .. " "
      end
      if x < self.width + 1 then
          map = map .. node.terrain .. ", "
      else
        map = map .. node.terrain .. "\n"
      end
    end
  end

  return map
end

return Map
