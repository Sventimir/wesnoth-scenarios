generator = wesnoth.require("~add-ons/above-and-below/lua/generator/generator.lua")

local player_colors = { "red", "blue", "green" }

function labirynth(cfg)
  local labirynth = generator.map(cfg.width, cfg.height, generator.maze_hex, "Xu")

  labirynth.gen_turn = 0
  labirynth.gen_path = {}
  labirynth.starting_locations = {}

  function labirynth:init(start)
    table.insert(self.gen_path, 1, start)
    self.gen_path[1].open_from = nil
    self.gen_path[1].terrain = "Ker"
    self.gen_path[1].label = labirynth.gen_turn

    local dir = generator.direction.random()
    self:gen_step(dir, "Cer")
    dir = dir:rotate(2)
    for i = 1, 5 do
      self:gen_step(dir, "Cer")
      dir = dir:clockwise()
    end
  end

  function labirynth:enterance_chamber(center, terrain)
    self.enterance = self.gen_path[1]
    self.enterance.terrain = center
    self.enterance.starting_player = 1
    self.starting_locations[1] = self.enterance
    local player_to_place = 2
    local dir = generator.direction.random()
    for _ = 1, 6 do
      target = self.enterance:path_to(dir, terrain)
      if player_to_place <= cfg.player_count and not target:on_border() then
        target.starting_player = player_to_place
        self.starting_locations[player_to_place] = target
        player_to_place = player_to_place + 1
      end
      dir = dir:clockwise()
    end
    self:gen_backstep()
  end

  function labirynth:appropriate_enterance()
    local here = self.gen_path[1]
    return (self.exit.x == 1 and here.x == self.width) or
      (self.exit.x == self.width and here.x == 1) or
      (self.exit.y == 1 and here.y == self.height) or
      (self.exit.y == self.height and here.y == 1)
  end

  function labirynth:exit_chamber(terrain)
    self.exit = self.gen_path[1]
    local dir = generator.direction.random()
    for _ = 1, 6 do
      self.exit:path_to(dir, terrain)
      dir = dir:clockwise()
    end
    self:gen_backstep()
  end

  function labirynth:gen_step(dir, terrain)
    local src = self.gen_path[1]
    local target = src:neighbour(dir)
    if target:on_border() then
      if not self.exit then
        return self:exit_chamber("Ur^Ii")
      end
      if not self.enterance and self:appropriate_enterance()  then
        return self:enterance_chamber("Ker", "Cer")
      end
      self:gen_backstep()
    else
      src:path_to(dir, terrain)
      self.gen_turn = self.gen_turn + 1
      target.label = self.gen_turn
      table.insert(self.gen_path, 1, target)
    end
  end

  function labirynth:gen_backstep()
    table.remove(self.gen_path, 1)
  end

  labirynth.boss_start = labirynth:get(mathx.random(3, cfg.width - 2), mathx.random(3, cfg.height - 2))
  labirynth:init(labirynth.boss_start)

  while labirynth.gen_path[1] do
    local node = labirynth.gen_path[1]
    local neighbours = {}
    for dir in generator.direction.all() do
      local neighbour = node:neighbour(dir)
      if node:path_open_to(neighbour) then
        table.insert(neighbours, dir)
      end
    end
    if #neighbours > 0 then
      labirynth:gen_step(neighbours[mathx.random(1, #neighbours)], "Uu")
    else
      labirynth:gen_backstep()
    end
  end

  return labirynth
end

function generate_labirynth_scenario(cfg)
  local scenario = wesnoth.require("~add-ons/above-and-below/lua/act2/scenario_template.lua")
  local labirynth = labirynth(cfg)

  scenario.map_data = labirynth:as_map_data()

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
