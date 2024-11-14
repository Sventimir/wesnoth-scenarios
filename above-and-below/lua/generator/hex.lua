local direction = wesnoth.require("~add-ons/above-and-below/lua/generator/direction.lua")

local function hex(map, x, y, terrain)
  local node = {
    x = x,
    y = y,
    terrain = terrain or "Gg"
  }

  function node:neighbour(dir)
    return map:get(dir:translate(self.x, self.y))
  end

  function node:on_border()
    local dir = ""
    if self.x == 0 then
      dir = "n"
    end
    if self.x == map.width + 1 then
        dir = "s"
    end
    if self.y == 0 then
      dir = dir .. "w"
    end
    if self.y == map.height + 1 then
      dir = dir .. "e"
    end

    if dir == "" then
      return nil
    else
      return dir
    end
  end

  function node:circle(radius)
    local function it(state, current)
      if state.step < radius then
        state.step = state.step + 1
      else
        if state.dir.value == direction.ne.value then
          return
        else
          state.step = 1
          state.dir = state.dir:clockwise()
        end
      end
      local x, y = state.dir:translate(current.x, current.y)
      local node = map:get(x, y)
      return node or it(state, { x = x, y = y })
    end
    local state = { dir = direction.se, step = 0 }
    return it, state, { x = self.x, y = self.y - radius }
  end

  return node
end

return {
  new = hex
}
