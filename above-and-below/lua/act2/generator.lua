Vec = wesnoth.require("~add-ons/above-and-below/lua/generator/cubic_vector.lua")
Hex = wesnoth.require("~add-ons/above-and-below/lua/generator/hex.lua")
Map = wesnoth.require("~add-ons/above-and-below/lua/generator/map.lua")

local player_colors = { "red", "blue", "green" }

new_hex = Hex.new
function Hex.new(map, x, y, terrain)
  local h = new_hex(map, x, y, terrain)
  h.open_from = true
  return h
end

Maze = {}
Maze.__index = Maze

function Maze.new(cfg)
  local m = setmetatable({ map = Map.new(cfg.width, cfg.height, "Xu") }, Maze)
  m.player_count = cfg.player_count
  m.gen_turn = 0
  m.gen_path = {}
  m.starting_locations = {}
  return m
end

function Maze:path_open_to(target)
  local here = self.gen_path[1]
  if target and target.open_from then
    local open_from = target.open_from
    return open_from == true or (open_from.x == here.x and open_from.y == here.y)
  else
      return false
  end
end

function Maze:tag_open_from(tag, node)
  if not node then return end
  if not node.open_from then return end
  if node.open_from == true then
    node.open_from = tag
  else
      node.open_from = (tag and tag.x == node.open_from.x and tag.y == node.open_from.y and tag) or nil
  end
end

function Maze:path_to(dir, terrain)
  local here = self.gen_path[1]
  local target = here:translate(dir)
  target.open_from = nil
  if target.terrain == "Xu" then
    target.terrain = terrain
  end
  for dir in Vec.equidistant(1) do
    local neighbour = target:translate(dir)
    self:tag_open_from(target, neighbour)
  end
  return target
end

function Maze:chamber(terrain)
  local here = self.gen_path[1]
  local hexes = { here }
  for dir in Vec.equidistant(1) do
    local neighbour = here:translate(dir)
    neighbour.terrain = terrain
    self:tag_open_from(here, neighbour)
    table.insert(hexes, neighbour)
    for d in Vec.equidistant(1) do
      local wall = neighbour:translate(d)
      if wall and wall.open_from == true then
        self:tag_open_from(neighbour, wall)
      end
    end
  end
  return hexes
end

function Maze:generate(start)
  self.boss_start = self.map:get(mathx.random(3, self.map.width - 2), mathx.random(3, self.map.height - 2))
  table.insert(self.gen_path, 1, self.boss_start)
  self.boss_start.open_from = nil
  self.boss_start.terrain = "Ker"
  self.boss_start.label = self.gen_turn
  self:chamber("Cer")
  table.insert(self.gen_path, 1, self.boss_start:translate(Vec.eigenvector.random()))

  while self.gen_path[1] do
    local node = self.gen_path[1]
    local neighbours = {}
    for dir in Vec.equidistant(1) do
      local neighbour = node:translate(dir)
      if self:path_open_to(neighbour) then
        table.insert(neighbours, dir)
      end
    end
    if #neighbours > 0 then
      local dir = neighbours[mathx.random(1, #neighbours)]
      self:gen_step(dir, "Ur")
    else
      self:gen_backstep()
    end
  end  
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
  return self:gen_backstep()
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
  self:chamber(terrain)
  return self:gen_backstep()
end

function Maze:gen_step(dir, terrain)
  local src = self.gen_path[1]
  local target = src:translate(dir)
  if target:on_border() then
    if not self.exit and self.gen_turn > 10 then
      return self:exit_chamber("Ur^Ii")
    end
    if self.exit and not self.enterance and self:appropriate_enterance()  then
      return self:enterance_chamber("Ke", "Ce")
    end
    return self:gen_backstep()
  else
    self:path_to(dir, terrain)
    self.gen_turn = self.gen_turn + 1
    target.label = self.gen_turn
    table.insert(self.gen_path, 1, target)
    return target
  end
end

function Maze:gen_backstep()
  table.remove(self.gen_path, 1)
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
       x = labirynth.boss_start.x,
       y = labirynth.boss_start.y
    }}
  }
  table.insert(scenario, {"side", orcs})

  for y, row in ipairs(labirynth) do
    for x, node in ipairs(row) do
      if node.label then
        table.insert(scenario, {"label", {
                                  x = x,
                                  y = y,
                                  text = node.label,
        }})
        end
    end
  end
  return scenario
end
