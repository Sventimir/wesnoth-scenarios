local Vec = wesnoth.require("~add-ons/above-and-below/lua/generator/cubic_vector.lua")

Hex = {}
Hex.__index = Hex

function Hex.new(map, x, y, terrain)
  return setmetatable({ map = map, x = x, y = y, terrain = terrain}, Hex)
end

function Hex:translate(v)
  return self.map:get(v:translate(self.x, self.y))
end

function Hex:circle(radius)
  return map(function(v) return self:translate(v) end, Vec.equidistant(radius))
end

function Hex:__tostring()
  return string.format("(%d, %d)", self.x, self.y)
end

function Hex:on_border()
  local dir = ""
  if self.x == 0 then
    dir = "n"
  end
  if self.x == self.map.width + 1 then
    dir = "s"
  end
  if self.y == 0 then
    dir = dir .. "w"
  end
  if self.y == self.map.height + 1 then
    dir = dir .. "e"
  end
  if dir == "" then
    return nil
  else
    return dir
  end
end

function Hex:as_vec()
  return Vec.new(self.y - mathx.floor(self.x / 2), self.x)
end

return Hex
