local messages = {
  "Tam dokąd chciałem, już nie dojdę…",
  "…szkoda zdzierac nóg.",
  "Raczej gardła, łośku. To koniec."
}
aab_run_dialog(
  wesnoth.units.find({ side = player_sides, canrecruit = true }),
  messages
)

wesnoth.wml_actions.endlevel({
    result = "defeat",
    reveal_map = false
})
