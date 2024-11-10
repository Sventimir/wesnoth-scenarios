local scenario = {
  id = "ab-act2",
  name = "Labirynth",
  carryover_percentage = 50,
  carryover_add = true,
  victory_when_enemies_defeated = false,
  {"time", {
     id = "underground",
     name = "Podziemia",
     image = "misc/time-schedules/schedule-underground.png",
     lawful_bonus = -25,
     red = -60,
     green = -45,
     blue = -25
  }}
}

return scenario
