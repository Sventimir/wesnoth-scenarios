local messages = {
  "Tam dokąd chciałem, już nie dojdę…",
  "…szkoda zdzierac nóg.",
  "Raczej gardła, łośku. To koniec."
}

local current_leader = wml.variables_proxy.unit or {}
local leaders = wesnoth.units.find_on_map({
    side = player_sides,
    canrecruit = true,
    { "not", { id = current_leader.id } }
})
mathx.shuffle(leaders)
if not current_leader.id then
  current_leader = table.remove(leaders, 1)
end

display_table(messages)

local d = dialogue.make()
d:add(dialogue.line(current_leader, messages[1]))

for m in drop(1, iter(messages)) do
  local speaker = table.remove(leaders, 1)
  d:add(dialogue.line(speaker, m))
  table.insert(leaders, current_leader)
  current_leader = speaker
end

d:play()

wesnoth.wml_actions.endlevel({
    result = "defeat",
    reveal_map = false
})
