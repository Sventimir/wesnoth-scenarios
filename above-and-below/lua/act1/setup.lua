wesnoth.require("~add-ons/above-and-below/lua/core.lua")

-- Put guardians in dwarven villages.
function spawn_dwarven_village_guards()
  local dwarven_villages = wesnoth.map.find({
      area = "dwarven-land",
      gives_income = true
  })
  
  for _, village in ipairs(dwarven_villages) do
    wesnoth.map.set_owner(village, dwarves)
    guard = wesnoth.units.create({
        type = "Dwarvish Guardsman",
        side = dwarves,
        x = village.x,
        y = village.y
    })
    wesnoth.units.to_map(guard)
  end
end

ai_tactics = wesnoth.require("~add-ons/above-and-below/lua/ai_tactics.lua")

dialogue = wesnoth.require("~add-ons/above-and-below/lua/dialogue.lua")
