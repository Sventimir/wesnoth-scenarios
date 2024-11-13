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

  return node
end

return {
  new = hex
}
