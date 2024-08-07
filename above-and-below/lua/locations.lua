require("core")


-- Returns the set of all the empty hexes as close as possible to the given hex.
-- If the given hex is empty, it is returned.
-- Otherwise all the adjecent empty hexes (if any) are returned.
-- If there are none, all the hexes adjecent to those are considered
-- and so forth, until one or more empty hexes are found.
function empty_hexes_near(x, y)
  local locations = {}
  local radius = -1
  while #locations == 0 do
    radius = radius + 1
    locations = wesnoth.map.find({
        { "and", { x = x, y = y, radius = radius} },
        { "not", { { "filter", {} } } } -- not containing any unit.
    })
  end
  return locations
end


return {
  empty_hexes_near = empty_hexes_near
}
