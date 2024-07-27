local messages = {
  "Tam dokąd chciałem, już nie dojdę…",
  "…szkoda zdzierac nóg.",
  "Raczej gardła, łośku. To koniec."
}
local first_speaker = wml.variables_proxy.unit or { side = 1 }

aab_run_dialog(
  wesnoth.units.find({ side = player_sides, canrecruit = true }),
  messages,
  first_speaker.side
)

wesnoth.wml_actions.endlevel({
    result = "defeat",
    reveal_map = false
})
