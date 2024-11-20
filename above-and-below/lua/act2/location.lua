
Chamber = {}
Chamber.__index = Chamber

function Chamber:new(terrain)
  local c = setmetatable({}, Chamber)
  c.terrain = terrain
  return c
end

function Chamber:generate(m)
  local center = m:here()
  center.terrain = self:gen_terrain(Vec.new(0, 0))
  center:seal()
  for v in Vec.equidistant(1) do
    local hex = center:translate(v)
    if hex then
      hex.terrain = self:gen_terrain(v)
    end
  end
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

ExitChamber = Chamber:new("Gg")
ExitChamber.__index = ExitChamber

function ExitChamber:placement_condition(m)
  local here = m:here()
  return here and
    (here.x == 1 or here.x == m.map.width or
     here.y == 1 or here.y == m.map.height)
end

function ExitChamber:generate(m)
  Chamber.generaate(self, m)
  m:deregister_location_constructor("exit_chamber")
end

function ExitChamber:gen_terrain(_)
  return self.terrain .. "^Ii"
end

return {
  castle = Castle
}
