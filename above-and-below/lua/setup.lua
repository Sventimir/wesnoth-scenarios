function aab_run_dialog(speakers, messages, first_speaker, next_speaker)
  local next_speaker = next_speaker or function(current_speaker)
    if current_speaker < #speakers then
      return current_speaker + 1
    else
      return 1
    end
  end
  local current_speaker = first_speaker or 1
  local current_message = 1
  while current_message <= #messages do
    local speaker = speakers[current_speaker]
    gui.show_narration({
      portrait = speaker.portrait,
      title = speaker.name,
      message = messages[current_message]
    })
    current_message = current_message + 1
    current_speaker = next_speaker(current_speaker)
  end
end

-- Put guardians in dwarven villages.
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

-- The following 2 functions are extremely messy due to using a mixture of
-- a deprecated and new API for accessing WML variables. The new API is 
-- cleaner, nicer and generally better, but it seems unable to update variables.
-- This should be refactored to use the new API only as soon as possible.
-- In particular, the old API, unlike LUA standard library, starts array indices
-- from 0 rather than 1. This is not the case with new API, so we need to convert
-- indices by subtracting 1. Please, take this code away before I vomit.
function choose_tactic(unit)
  local tactics = wesnoth.sides.get(unit.side).variables.tactics
  local idx = nil
  if tactics == nil then
    return
  end
  if tactics.total_count > 0 then
    for i, t in ipairs(tactics) do
      if t[2].count > 0 then
        idx = i
        break
      end
    end
  end
  if idx == nil then
    local c = mathx.random(1, tactics.total_weight)
    for i, t in ipairs(tactics) do
      c = c - t[2].weight
      if c <= 0 then
        idx = i
        break
      end
    end
  end
  if idx == nil or tactics[idx][2].role == nil then
    return
  end
  wesnoth.wml_actions.role({
      id=unit.id,
      role=tactics[idx][2].role
  })
  local addr = string.format("tactics.tactic[%d].count", idx - 1)
  wesnoth.set_side_variable(unit.side, addr, tactics[idx][2].count - 1)
  wesnoth.set_side_variable(unit.side, "tactics.total_count", tactics.total_count - 1)
end

function request_replacement(unit)
  local tactics = wesnoth.sides.get(unit.side).variables.tactics
  if unit.role == nil or tactics == nil then
    return
  end
  for _, tactic in ipairs(tactics) do
    if tactic[1].role == unit.role then
      local addr = string.format("tactics.tactic[%d].count", idx)
      wesnoth.set_side_variable(unit.side, addr, tactic[1].count + 1)
      wesnoth.set_side_variable(unit.side, "tactics.total_count", tactics.total_count + 1)
      break
    end
  end
end
