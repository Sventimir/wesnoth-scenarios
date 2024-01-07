local recruit_costs = {
  { 8, 8, 8, 12, 12, 18 },
  { 12, 12, 12, 18, 18, 27 },
  { 18, 18, 18, 27, 27, 40 },
  { 27, 27, 27, 40, 40, 60 }
}
local recuit_types = {
  [8] = { "Peasant", "Woodsman", "Ruffian" },
  [12] = { "Spearman", "Bowman", "Footpad", "Thug", "Poacher"},
  [18] = { "Lieutenant" }
}

local village = wml.variables_proxy.village
village.owner_side = wesnoth.map.get_owner(village)
if village.owner_side and village.owner_side < 8 then
  village.unrest = village.unrest + mathx.random(1, 4) -- +d4
  
  local viewer, _ = wesnoth.get_viewing_side()
  local occupant = wesnoth.units.get(village.x, village.y)
  local occupant_level = 0
  local treshold = 10  -- 2d8 + 10 + 8 * (occupant's level + 1)
  if occupant then
    occupant_level = occupant.level + 1
    treshold = treshold + occupant_level * 8
  end
  for i = 0, 2, 1 do  
    treshold = treshold + mathx.random(1, 8)
  end
  
  if village.unrest > treshold then
    while village.unrest > recruit_costs[occupant_level][1] do
      if village.unrest < recruit_costs[occupant_level][6] then
        recruit_costs[occupant_level][6] = nil
      end
      if village.unrest < recruit_cost[occupant_level][4] then
        recruit_costs[occupant_level][5] = nil
        recruit_costs[occupant_level][4] = nil
      end
      local cost = mathx.random_choice(recruit_costs[occupant_level])
      local recruit_type = mathx.random_choice(recuit_types[cost])
      local locations = {}
      local radius = -1
      while #locations == 0 do
        radius = radius + 1
        locations = wesnoth.map.find({
            { "and", { x = village.x, y = village.y, radius = radius} },
            { "not", { { "filter", {} } } }
        })
      end
      local recruit = wesnoth.units.create({
          type = recruit_type,
          side = 8,
          canrecruit = cost == 18,
          x = locations[1].x,
          y = locations[1].y
      })
      wesnoth.units.to_map(recruit)
      if radius == 0 then
        if not wesnoth.sides.is_enemy(village.owner_side, viewer) then
          wesnoth.sides.remove_fog(viewer, village)
        end
        if #wesnoth.units.find_on_map({ side = 8, canrecruit = true }) > 0 then
          wesnoth.map.set_owner(village, 8)
        else
          wesnoth.map.set_owner(village, 0)
        end
      end
      if not wesnoth.sides.is_fogged(viewer, locations[1]) then
        wesnoth.units.scroll_to(recruit)
        wesnoth.show_message_dialog({
            portrait = recruit.portrait,
            title = wesnoth.map.get_label(village),
            message = "Wszędzie ruchawka, zniszczenie i pożoga!"
        })
      end
      village.unrest = village.unrest - cost
    end
  end
else
  village.unrest = 0
end
