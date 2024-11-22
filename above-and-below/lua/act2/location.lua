Vec = wesnoth.require("~add-ons/above-and-below/lua/generator/cubic_vector.lua")

Chamber = {}
Chamber.__index = Chamber

function Chamber:new(terrain)
  local c = setmetatable({}, Chamber)
  c.terrain = terrain
  return c
end

function Chamber:generate(m)
  local center = m:here()
  local hexes = { center }
  center.terrain = self:gen_terrain(Vec.new(0, 0))
  center:seal()
  for v in Vec.equidistant(1) do
    local hex = center:translate(v)
    if hex then
      hex:mark_adjacent_to_path(v)
      hex.terrain = self:gen_terrain(v)
    end
    table.insert(hexes, hex)
  end
  for dir in Vec.equidistant(2) do
    local wall = center:translate(dir)
    if wall then
      wall:mark_adjacent_to_path(table.unpack(as_table(dir:split_into_unitary())))
    end
  end
  return hexes
end

Castle = Chamber:new("Ch")
Castle.__index = Castle

function Castle:new(keep, castle)
  local c = setmetatable({}, Castle)
  c.keep = string.sub(keep, 0, 1) == "K" and keep or keep .. "^Kov"
  c.terrain = string.sub(castle, 0, 1) == "C" and castle or castle .. "^Cov"
  return c
end

function Castle:gen_terrain(v)
  if v:length() == 0 then
    return self.keep
  else
    return self.terrain
  end
end

ExitChamber = Chamber:new("Ur")
ExitChamber.__index = ExitChamber

function ExitChamber:priority_weight(m)
  local here = m:here()
  if m.gen_turn > 10 and here and
    (here.x == 1 or here.x == m.map.width or
     here.y == 1 or here.y == m.map.height)
  then
    return 10000
  else
    return 0
  end
end

function ExitChamber:generate(m)
  m:deregister_location_constructor("exit_chamber")
  m:register_location_constructor("enterance_chamber", EnteranceChamber)
  m.exit = Chamber.generate(self, m)
  m:gen_backstep()
end

function ExitChamber:gen_terrain(_)
    return self.terrain .. "^Ii"
end

EnteranceChamber = Castle:new("Ke", "Ce")
EnteranceChamber.__index = EnteranceChamber

function EnteranceChamber:generate(m)
  table.insert(m.starting_locations, Castle.generate(self, m))
  if #m.starting_locations >= m.player_count then
    m:deregister_location_constructor("enterance_chamber")
  end
  m:gen_backstep()
end

function EnteranceChamber:priority_weight(m)
  local here = m:here()
  local exit = m.exit[1]
  if here and (
    (here.x == 1 and exit.x == m.map.width) or
    (here.x == m.map.width and exit.x == 1) or
    (here.y == 1 and exit.y == m.map.height) or
    (here.y == m.map.height and exit.y == 1))
  then
    return 10000
  else
    return 0
  end
end

NarrowCorridor = {}
NarrowCorridor.__index = NarrowCorridor

function NarrowCorridor.new(dir, terrain)
  return setmetatable({ dir = dir, terrain = terrain }, NarrowCorridor)
end

function NarrowCorridor:priority_weight(m)
  local here = m:here()
  local target = here:translate(self.dir)
  return target and not target:on_border() and target:is_open_from(self.dir) and 1 or 0
end

function NarrowCorridor:name()
  return string.format("narrow_corridor(%s, %s)", self.dir, self.terrain)
end

function NarrowCorridor:generate(m)
  local here = m:here()
  local target = here:translate(self.dir)
  if target.terrain == "Xu" then
    target.terrain = "Uu"
  end
  local vs = {
    self.dir,
    Vec.unitary.clockwise(self.dir),
    Vec.unitary.counterclockwise(self.dir),
    }
  for v in iter(vs) do
    local hex = here:translate(v)
    if hex then
      hex:seal()
    end
    hex = target:translate(v)
    if hex then
      hex:mark_adjacent_to_path(v)
    end
  end
  return { target }
end

WideCorridor = {}
WideCorridor.__index = WideCorridor

function WideCorridor.new(dir, terrain)
  return setmetatable({ dir = dir, terrain = terrain }, WideCorridor)
end

function WideCorridor:name()
  return string.format("wide_corridor(%s, %s)", self.dir, self.terrain)
end

function WideCorridor:priority_weight(m)
  local here = m:here()
  local vecs = {
    self.dir,
    Vec.unitary.clockwise(self.dir),
    Vec.unitary.counterclockwise(self.dir)
  }
  for v in iter(vecs) do
    local hex = here:translate(v)
    if not hex or hex:on_border() or not hex:is_open_from(v) then
      return 0
    end
  end
  return 100
end

WideCorridor.opposite_dir = {
  clockwise = "counterclockwise",
  counterclockwise = "clockwise"
}

function WideCorridor:mark_adjacent_to_path(hex, v, dir, count)
  local to_unlock = take(count, Vec.unitary[dir .. "_rotations"](v))
  hex:mark_adjacent_to_path(table.unpack(as_table(to_unlock)))
end

function WideCorridor:generate_adjacent_hex(here, dir)
  local v = Vec.unitary[dir](self.dir)
  local hex = here:translate(v)
  if hex.terrain == "Xu" then
    hex.terrain = self.terrain
  end
  self:mark_adjacent_to_path(hex, v, dir, 4)
end

function WideCorridor:generate(m)
  local here = m:here()
  local target = here:translate(self.dir)

  if target.terrain == "Xu" then
    target.terrain = self.terrain
  end
  target:seal()

  self:mark_adjacent_to_path(
    target:translate(self.dir),
    Vec.unitary.clockwise(self.dir),
    "counterclockwise",
    3
  )

  for dir in iter({ "clockwise", "counterclockwise" }) do
    self:generate_adjacent_hex(here, dir)
    local rotated = Vec.unitary[dir](self.dir)
    self:mark_adjacent_to_path(
      target:translate(rotated),
      Vec.unitary[dir](self.dir),
      dir,
      4
    )
    self:mark_adjacent_to_path(
      here:translate(rotated:scale(2)),
      Vec.unitary[dir](rotated),
      self.opposite_dir[dir],
      4
    )
    self:mark_adjacent_to_path(
      here:translate(rotated + Vec.unitary[dir](rotated)),
      rotated,
      dir,
      4
    )
  end

  return { target }
end

return {
  castle = Castle,
  exit_chamber = ExitChamber,
  enterance_chamber = EnteranceChamber,
  narrow_corridor = NarrowCorridor,
  wide_corridor = WideCorridor
}
