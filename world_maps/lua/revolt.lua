local recruit_costs = { 8, 8, 8, 12, 12, 18 }
local recuit_types = {
  [8] = { "Peasant", "Woodsman", "Ruffian" },
  [12] = { "Spearman", "Bowman", "Footpad", "Thug", "Poacher"},
  [18] = { "Lieutenant" }
}

local v = wml.variables_proxy.village
v.owner_side = wesnoth.get_village_owner(v.x, v.y)
if v.owner_side and v.owner_side < 8 then
  for i = 0, 2, 1 do
    v.unrest = v.unrest + mathx.random(1, 6) -- +2d6
  end
  
  local occupant = wesnoth.get_unit(v.x, v.y)
  local treshold = 10  -- 2d8 + 10 + 8 * (occupant's level + 1)
  if occupant then
    treshold = treshold + (occupant.level + 1) * 8
  end
  for i = 0, 2, 1 do  
    treshold = treshold + mathx.random(1, 8)
  end
  
  if v.unrest > treshold then
    while v.unrest > 8 do
      if v.unrest < 18 then
        recruit_costs[6] = nil
      end
      if v.unrest < 12 then
        recruit_costs[5] = nil
        recruit_costs[4] = nil
      end
      local cost = mathx.random_choice(recruit_costs)
      local recruit_type = mathx.random_choice(recuit_types[cost])
      local locations = {}
      local radius = -1
      while #locations == 0 do
        radius = radius + 1
        locations = wesnoth.map.find({
            { "and", { x = v.x, y = v.y, radius = radius} },
            { "not", { { "filter", {} } } }
        })
      end
      local recruit = wesnoth.create_unit({
          type = recruit_type,
          side = 8,
          canrecruit = cost == 18,
          x = locations[1].x,
          y = locations[1].y
      })
      wesnoth.put_unit(recruit)
      if radius == 0 then
        if #wesnoth.get_units({ side = 8, canrecruit = true }) > 0 then
          wesnoth.map.set_owner(v, 8)
        else
          wesnoth.map.set_owner(v, 0)
        end
      end
      wesnoth.show_message_dialog({
          portrait = recruit.portrait,
          message = "Wszędzie ruchawka, zniszczenie i pożoga!"
      })
      wesnoth.message("x = " .. v.x .. ", y = " .. v.y .. ", radius = " .. radius ..
                      ", treshold = " .. treshold .. ", unrest = " .. v.unrest ..
                      ", location = (" .. locations[1].x ..", " .. locations[1].y .. ")")
      v.unrest = v.unrest - cost
    end
  end
else
  v.unrest = 0
end
