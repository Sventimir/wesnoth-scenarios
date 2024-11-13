hex = wesnoth.require("~add-ons/above-and-below/lua/generator/hex.lua")

return {
  direction = wesnoth.require("~add-ons/above-and-below/lua/generator/direction.lua"),
  hex = hex.new,
  map = wesnoth.require("~add-ons/above-and-below/lua/generator/map.lua"),
  maze_hex = hex.maze_hex
}
