require("core")
require("wesnoth-mock")
require("act2/generator")

s = generate_labirynth_scenario({ width = 20, height = 20, player_count = 3, difficulty = 3 })
print(s.map_data)
