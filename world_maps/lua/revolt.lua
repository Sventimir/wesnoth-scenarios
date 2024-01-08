function recruitment_cost(occupant_level, level)
  return (4 * occupant_level + 12) * (1.5 ^ level)
end

local recruit_levels = { 0, 0, 0, 1, 1, 2 }
local recuit_types = {
  [0] = { "Peasant", "Woodsman", "Ruffian" },
  [1] = { "Spearman", "Bowman", "Footpad", "Thug", "Poacher"},
  [2] = { "Lieutenant" }
}

local village = wml.variables_proxy.village
village.owner_side = wesnoth.map.get_owner(village)
if village.owner_side and village.owner_side < 8 then
  village.unrest = village.unrest + mathx.random(1, 6) -- +d6

  local viewer, _ = wesnoth.interface.get_viewing_side()
  local occupant = wesnoth.units.get(village.x, village.y)
  local occupant_level = -1
  if occupant then
    occupant_level = occupant.level
  end
  local threshold = recruitment_cost(occupant_level, 0) * village.unrest_threshold / 10
  
  if village.unrest > threshold then
    while village.unrest > recruitment_cost(occupant_level, 0) do
      if village.unrest < recruitment_cost(occupant_level, 6) then
        recruit_levels[6] = nil
      end
      if village.unrest < recruitment_cost(occupant_level, 1) then
        recruit_levels[5] = nil
        recruit_levels[4] = nil
      end
      local level = mathx.random_choice(recruit_levels)
      local cost = recruitment_cost(occupant_level, level)
      local recruit_type = mathx.random_choice(recuit_types[level])
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
          canrecruit = level == 2,
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
        local label = wesnoth.map.get_label(village)
        wesnoth.show_message_dialog({
            portrait = recruit.portrait,
            title = label.text,
            message = "Wszędzie ruchawka, zniszczenie i pożoga!"
        })
      end
      village.unrest = village.unrest - cost
    end
    village.unrest_threshold = mathx.random(0, 30)
  end
else
  village.unrest = 0
end
