local negotiating_side = wml.variables_proxy.unit.side
negotiator = wesnoth.units.find_on_map({
    side = negotiating_side,
    canrecruit = true
})[1]

local dwarf_lord = wesnoth.units.get("dwarf-lord")
local scout = wml.variables_proxy.second_unit
wesnoth.wml_actions.move_unit({
    id = dwarf_lord.id,
    to_x = scout.x,
    to_y = scout.y,
    fire_event = false
})
local locations = wesnoth.map.find({
    x = dwarf_lord.x,
    y = dwarf_lord.y,
    radius = 2
})
for side in wesnoth.sides.iter({ side = player_sides }) do
  side:remove_shroud(locations)
  side:remove_fog(locations)
end

local messages = {
    "A cóż to za przybysze starają się wkroczyć na nasz ziemie? Ani kroku dalej!",
    "Spokojnie, nie mamy złych zamiarów. Przybyliśmy tu w pokoju.",
    "Wasze zamiary niewiele mnie interesują, mówiąc oględnie. Na tym szlaku pobieramy myto. Płacisz - przechodzisz. Nie płacisz - zawracasz. Proste.",
    "Ile chcecie?",
    "Dziesięć sztuk złota od łebka.",
    "Dzięć sztuk złota od łebka? Widzisz ilu nas jest?",
    "Możecie spróbować przejść bez płacenia. Po tej operacji z pewnością będzie was mniej. Kto wie może nawet będzie was stać na myto? Chociaż mówiąc szczerze nie wyglądacie na szczególnie majętnych. Tak czy inaczej, opłata nie podlega negocjacjom.", 
}
local speakers = {dwarf_lord, negotiator}
aab_run_dialog(speakers, messages)

local units = wesnoth.units.find_on_map({ side = player_sides })
local toll = #units * 10

local total_funds = 0
for side in wesnoth.sides.iter({ side = player_sides }) do
  total_funds = total_funds + side.gold
end

local choice = {
  speaker = negotiator.id,
  side_for = negotiator.side,
  variable = "pay_the_toll",
  wait_description = string.format("%s rozważa propozycję krasnoluda.", negotiator.name)
}

local answers = {}
if total_funds >= toll then
  answers[true] = string.format("Zgoda, zapłacimy. To będzie %d sztuk złota.", toll)
  answers[false] = "Po moim trupie. Albo po twoim za chwilę przejdziemy. Do broni towarzysze!"
else
  answers[false] = string.format("Niestety, nie mamy %d sztuk złota. A przejść musimy, więc sam rozumiesz. Gotuj się na śmierć.", toll)
end

for val, msg in pairs(answers) do
  table.insert(choice, {"option", {
    message = msg,
    value = val
  }})
end

wesnoth.wml_actions.message(choice)
local others = wesnoth.sides.find({
    side = player_sides,
    { "not", { side = negotiating_side } }
})
for _, side in ipairs(others) do
  wesnoth.wml_actions.message({
      speaker = negotiator.id,
      side_for = side.side,
      message = answers[wml.variables_proxy.pay_the_toll]
  })
end

if wml.variables_proxy.pay_the_toll then
  gui.show_narration({
      portrait = dwarf_lord.portrait,
      title = dwarf_lord.name,
      message = "Interesy z wami to prawdziwa przyjemność. Przepuścić ich, chłopcy! A może potrzebujecie najemników? Wiem, że niejeden z nas chętnie zaciągnie się przygodą. Na przygodę? Ha. nieważne! Krasnolud nie gardzi złotem."
  })
  local dwarves_side = wesnoth.sides.get(dwarves)
  dwarves_side.team_name = 1
  dwarves_side.gold = dwarves_side.gold + toll

  for side in wesnoth.sides.iter({ side = player_sides }) do
    units = wesnoth.units.find_on_map({ side = side.side })
    local amount = #units * 10
    side.gold = side.gold - amount
    local leader = wesnoth.units.find_on_map({ side = side.side, canrecruit = true })[1]
    wesnoth.wml_actions.allow_extra_recruit({
        id = leader.id,
        extra_recruit="Dwarvish Guardsman,Dwarvish Fighter,Dwarvish Thunderer,Dwarvish Scout,Dwarvish Ulfserker"
    })
  end

  wesnoth.wml_actions.micro_ai({
      side = necromancers,
      ca_id = "bat_north_hunter",
      ai_type = "zone_guardian",
      action = "delete"
  })
  wesnoth.wml_actions.micro_ai({
      side = necromancers,
      ca_id = "zone_guardian",
      ai_type = "bottleneck_defense",
      action = "delete"
  })
else
  messages = {
    "Tylko spróbujcie, a dowiecie się, jakie to nieprzyjemne uczucie nosić gips.",
    "Musiałeś sporo obrywać, skoro tyle o tym wiesz.",
    "Ohoho, nie chłopcze, nie sprowokujesz mnie tak łatwo. Trzymać pozycje chłopcy. Nadchodzą!"
  }
  aab_run_dialog(speakers, messages)
end

-- Back to the castle
wesnoth.wml_actions.move_unit({
    id = dwarf_lord.id,
    to_x = 20,
    to_y = 11,
    fire_event = false
})

wesnoth.wml_actions.allow_extra_recruit({
    id = dwarf_lord.id,
    extra_recruit="Dwarvish Fighter,Dwarvish Scout"
})
