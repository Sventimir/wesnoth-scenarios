require("wesnoth-mock")
require("core")
require("act2/generator")

s, l = generate_labirynth_scenario({
    debug = true,
    width = 25,
    height = 25,
    player_count = 3,
    difficulty = 3
})
print(s.map_data)
