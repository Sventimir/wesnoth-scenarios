local d = dialogue.make()
local killer = wesnoth.units.get(wml.variables_proxy.second_unit.id)
local leaders = players.heroes()
mathx.shuffle(leaders)

local treasure = {
  EASY = 300,
  NORMAL = 150,
  HARD = 90,
}
local prize = treasure[wesnoth.scenario.difficulty] / #leaders
local messages = {
  "Widać zabawiał się ze swoimi goblinami na różne sposoby.",
  "Nie, durniu, on chciał powiedzieć, że ten ork natrzepał w życiu sporo loota.",
  "Teraz to wszystko należy do nas.",
  "Podzielimy się kasą po równo, prawda?",
  "...",
  "...",
  "...",
  "Oczywiście! Nie ma problemu!",
  "A temu cwania… to jest chciałem powiedzieć zuchowi, co go zaciukał, należy się medal!",
}

d:add(dialogue.line(killer, "Obczajcie! Ten gość był nieźle nadziany?"))
for speaker, message in zip(cycle(leaders), iter(messages)) do
  d:add(dialogue.line(speaker, message))
end

d:play()

killer.experience = killer.experience + killer.max_experience
wesnoth.units.advance(killer)
gui.show_narration({
  portrait = killer.portrait,
  title = killer.name,
  message = "For peace in the kingdom!!"
})

wesnoth.wml_actions.sound({ name = "gold.ogg" })
for side in wesnoth.sides.iter({ side = player_sides }) do
  side.gold = side.gold + prize
end

local bats = wesnoth.units.find_on_map({ side = necromancer, canrecruit = false })
for bat in iter(bats) do
  bat.role = "exit-guard"
end
