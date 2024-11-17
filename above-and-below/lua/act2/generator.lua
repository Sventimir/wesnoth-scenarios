Vec = wesnoth.require("~add-ons/above-and-below/lua/generator/cubic_vector.lua")
Hex = wesnoth.require("~add-ons/above-and-below/lua/generator/hex.lua")
Map = wesnoth.require("~add-ons/above-and-below/lua/generator/map.lua")

local player_colors = { "red", "blue", "green" }

function Hex:is_open_from(dir)
  return not (self.closed_from and self.closed_from[Vec.eigenvector.id(dir)])
end

function Hex:mark_adjacent_to_path(...)
  -- if it's already adjecent to another corrdor, close it completely
  if self.closed_from then
    self:seal()
  else
    self:seal()
    for _, dir in ipairs({ ... }) do
      self.closed_from[Vec.eigenvector.id(dir)] = false
    end
  end
end

function Hex:seal()
  self.closed_from = { true, true, true, true, true, true, true }
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
  return m
end

function Maze:generate(start)
  self.genesis = self.map:get(mathx.random(3, self.map.width - 2), mathx.random(3, self.map.height - 2))
  table.insert(self.gen_path, 1, self.genesis)
  self.genesis:seal()
  self.genesis.terrain = "Ker"
  if self.debug then
    self.genesis.label = self.gen_turn
  end
  self:chamber("Cer")

  while self.gen_path[1] do
    local here = self.gen_path[1]
    local available_dirs = as_table(
      filter(
        function(d)
          local neighbour = here:translate(d)
            return neighbour and neighbour:is_open_from(d) and
              not (self.enterance and self.exit and neighbour:on_border())
        end,
        Vec.equidistant(1)
      )
    )
    if #available_dirs > 0 then
      local dir = available_dirs[mathx.random(1, #available_dirs)]
      self:gen_step(dir)
    else
      self:gen_backstep()
    end
  end
end

function Maze:gen_step(dir)
  local here = self.gen_path[1]
  local target = here:translate(dir)
  if not self.exit and target:on_border() then
    return self:exit_chamber("Ur^Ii")
  end
  if self.exit and not self.enterance and self:appropriate_enterance() then
    return self:enterance_chamber("Ke", "Ce")
  end
  self.gen_turn = self.gen_turn + 1
  if self.debug then
    target.label = self.gen_turn
  end
  if target.terrain == "Xu" then
    target.terrain = "Ur"
  end
  local to_be_sealed = {
    target,
    here:translate(Vec.eigenvector.clockwise(dir)),
    here:translate(Vec.eigenvector.counterclockwise(dir))
  }
  for hex in iter(to_be_sealed) do
    if hex then hex:seal() end
  end
  table.insert(self.gen_path, 1, target)
end

function Maze:gen_backstep()
  table.remove(self.gen_path, 1)
  return self.gen_path[1]
end

function Maze:enterance_chamber(center, terrain)
  self.enterance = self.gen_path[1]
  self.enterance.terrain = center
  local hexes = self:chamber(terrain)
  local next_hex = filter(
    function(hex) return hex:on_border() == nil end,
    iter(hexes)
  )
  for i = 1, self.player_count do
    local hex = next_hex()
    hex.starting_player = i
    self.starting_locations[i] = hex
  end
  self:gen_backstep()
end

function Maze:appropriate_enterance()
  local here = self.gen_path[1]
  return (self.exit.x == 1 and here.x == self.map.width) or
    (self.exit.x == self.map.width and here.x == 1) or
    (self.exit.y == 1 and here.y == self.map.height) or
    (self.exit.y == self.map.height and here.y == 1)
end

function Maze:exit_chamber(terrain)
  self.exit = self.gen_path[1]
  self.exit.terrain = terrain
  local hexes = self:chamber(terrain)
  self:gen_backstep()
end

function Maze:chamber(terrain)
  local here = self.gen_path[1]
  local hexes = { here }
  for dir in Vec.equidistant(1) do
    local neighbour = here:translate(dir)
    if neighbour then
      if neighbour.terrain == "Xu" then
        neighbour.terrain = terrain
      end
      table.insert(hexes, neighbour)
    end
  end
  for dir in Vec.equidistant(2) do
    local wall = here:translate(dir)
    if wall then
      -- Some of wall hexes have 2 adjecant chamber hexes, some have 1. In the latter case
      -- all the vector components are even, so get the same result with each of the
      -- transformations below
      wall:mark_adjacent_to_path(dir:scale(0.5, mathx.floor), dir:scale(0.5, mathx.ceil))
    end
  end
  return hexes
end


function generate_labirynth_scenario(cfg)
  local scenario = wesnoth.require("~add-ons/above-and-below/lua/act2/scenario_template.lua")
  labirynth = Maze.new(cfg)
  labirynth:generate()

  scenario.map_data = labirynth.map:as_map_data()

  local signpost = {
    image="scenery/signpost.png",
    submerge=1,
    visible_in_fog=true,
    x=labirynth.exit.x,
    y=labirynth.exit.y
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
