require("wesnoth-mock")
require("core")
WeightedSet = require("weighted_set")
Loc = require("act2/location")
require("act2/generator")

s, l = generate_labirynth_scenario({
    debug = true,
    width = 25,
    height = 25,
    player_count = 3,
    difficulty = 3
})
print(s.map_data)
