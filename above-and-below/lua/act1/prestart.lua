
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

-- Spawn wolves in the woods.
local forest_hexes = wesnoth.map.find({
    include_borders = false,
    terrain = "*^Fp",
    { "not", { area = "dwarven-land" } },
})
mathx.shuffle(forest_hexes)

local wolf_count = {
  EASY = 20,
  NORMAL = 35,
  HARD = 50
}

for i = 1, wolf_count[wesnoth.scenario.difficulty] do
  local u = wesnoth.units.create({
      type = "Sneaky_Wolf",
      side = monsters,
      x = forest_hexes[i].x,
      y = forest_hexes[i].y
  })
  wesnoth.units.to_map(u)
end
