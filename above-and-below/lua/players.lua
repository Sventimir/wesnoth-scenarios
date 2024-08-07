require("core")

local function sides_except(except)
  local f = { side = player_sides }
  if except then
    table.insert(f, { "not", { side = except } })
  end
  return wesnoth.sides.iter(f)
end

local function heroes(filter)
  local filt = { side = player_sides, canrecruit = true }
  for k, v in pairs(filter or {}) do
    filt[k] = v
  end
  return wesnoth.units.find_on_map(filt)
end

return {
  heroes = heroes,
  sides_except = sides_except,
}
