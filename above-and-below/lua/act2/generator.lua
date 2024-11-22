Vec = wesnoth.require("~add-ons/above-and-below/lua/generator/cubic_vector.lua")
Hex = wesnoth.require("~add-ons/above-and-below/lua/generator/hex.lua")
Map = wesnoth.require("~add-ons/above-and-below/lua/generator/map.lua")
Location = wesnoth.require("~add-ons/above-and-below/lua/act2/location.lua")
WeightedSet = wesnoth.require("~add-ons/above-and-below/lua/weighted_set.lua")

local player_colors = { "red", "blue", "green" }

function Hex:is_open_from(dir)
  return (not self.open_from) or self.open_from[Vec.unitary.id(dir)]
end

-- Hex.open_from is a number, whose bits correspond to the 6 directions
function Hex:mark_adjacent_to_path(...)
  local index = 0
  if not self.open_from then
    self.open_from = { true, true, true, true, true, true, true }
  end
  for dir in iter({ ... }) do
    index = index | (2 ^ Vec.unitary.id(dir))
  end
  for v in Vec.equidistant(1) do
    local i = Vec.unitary.id(v)
    if (2 ^ i & index) == 0 then
      self.open_from[i] = false
    end
  end
end

function Hex:seal()
  self.open_from = { false, false, false, false, false, false, false }
end

Maze = {}
Maze.__index = Maze

function Maze.new(cfg)
  local m = setmetatable({ map = Map.new(cfg.width, cfg.height, "Xu") }, Maze)
  m.debug = cfg.debug or false
  m.player_count = cfg.player_count
  m.gen_turn = 0
  m.gen_path = {}
  m.starting_locations = {}
  m.location_constructors = {
    exit_chamber = Location.exit_chamber,
  }
  for dir in Vec.equidistant(1) do
    local constr = Location.wide_corridor.new(dir, "Uu")
    m.location_constructors[constr:name()] = constr
    -- constr = Location.narrow_corridor.new(dir, "Uu")
    -- m.location_constructors[constr:name()] = constr
  end
  return m
end

function Maze:register_location_constructor(name, constr)
  self.location_constructors[name] = constr
end

function Maze:deregister_location_constructor(name)
  self.location_constructors[name] = nil
end

function Maze:generate()
  self.genesis = self.map:get(mathx.random(3, self.map.width - 2), mathx.random(3, self.map.height - 2))
  table.insert(self.gen_path, 1, self.genesis)
  if self.debug then
    self.genesis.label = self.gen_turn
  end
  local genesis_chamber = Location.castle:new("Ker", "Cer")
  genesis_chamber:generate(self)

  while self.gen_path[1] do
    local available_locs = WeightedSet.new()
    for _, constr in pairs(self.location_constructors) do
      available_locs:insert(constr, constr:priority_weight(self))
    end
    local constr = available_locs:random()
    if constr then
      local here = constr:generate(self)
      if here then
        table.insert(self.gen_path, 1, here[1])
      end
      self.gen_turn = self.gen_turn + 1
      if self.debug and here and not here[1].label then
        here[1].label = self.gen_turn
      end
    else
      self:gen_backstep()
    end
  end

  local location = 1
  local location_hex = 1
  local player_starts = {}
  while #player_starts < self.player_count do
    local h = self.starting_locations[location][location_hex]
    h.starting_player = #player_starts + 1
    table.insert(player_starts, h)
    if location == #self.starting_locations then
      location_hex = location_hex + 1
      location = 1
    else
      location = location + 1
    end
  end
  self.starting_locations = player_starts
end

function Maze:gen_backstep()
  table.remove(self.gen_path, 1)
end

function Maze:here()
  return self.gen_path[1]
end


function generate_labirynth_scenario(cfg)
  local scenario = wesnoth.require("~add-ons/above-and-below/lua/act2/scenario_template.lua")
  local labirynth = Maze.new(cfg)
  labirynth:generate()

  scenario.map_data = labirynth.map:as_map_data()

  local signpost = {
    image="scenery/signpost.png",
    submerge=1,
    visible_in_fog=true,
    x=labirynth.exit[1].x,
    y=labirynth.exit[1].y
  }
  table.insert(scenario, {"item", signpost})

  for player_id = 1, cfg.player_count do
    local leader_loc = labirynth.starting_locations[player_id]
    local side = {
      constroller = "human",
      color = player_colors[player_id],
      faction = "ab-humans",
      faction_lock = true,
      leader_lock = false,
      fog = true,
      shroud = true,
      gold = 0,
      hidden = false,
      income = 0,
      share_vision = "all",
      side = player_id,
      save_id = "adv" .. player_id,
      team_name = "Bohaterowie",
      team_user_name = "Bohaterowie",
      defeat_condition = "never",
      {"leader", {
         id="adv" .. player_id,
         x = leader_loc.x,
         y = leader_loc.y
      }}
    }
    table.insert(scenario, {"side", side})
  end

  local orcs = {
    allow_player = "no",
    constroller = "ai",
    color = "brown",
    faction = "Custom",
    faction_lock = true,
    gold = cfg.difficulty * 250,
    hidden = true,
    income = 0,
    no_leader = true,
    shroud = false,
    fog = true,
    side = cfg.player_count + 1,
    side_name = "Orkowie",
    team_name = "Orkowie",
    recruit = "Orcish Grunt,Troll Whelp,Wolf Rider,Orcish Archer,Orcish Assassin,Goblin Spearman",
    {"leader", {
       type = "Orcish Ruler",
       x = labirynth.genesis.x,
       y = labirynth.genesis.y
    }}
  }
  table.insert(scenario, {"side", orcs})

  for label in labirynth.map:labels_wml() do
    table.insert(scenario, label)
  end

  return scenario, labirynth
end
