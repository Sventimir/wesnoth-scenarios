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

