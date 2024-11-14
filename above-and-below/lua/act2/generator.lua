generator = wesnoth.require("~add-ons/above-and-below/lua/generator/generator.lua")

local player_colors = { "red", "blue", "green" }

local function hex(labirynth, x, y, terrain)
  local node = generator.hex.new(labirynth, x, y, terrain)
  node.open_from = true
  return node
end

function labirynth(cfg)
  local labirynth = generator.map(cfg.width, cfg.height, hex, "Xu")

  labirynth.gen_turn = 0
  labirynth.gen_path = {}
  labirynth.starting_locations = {}

  function labirynth:path_open_to(target)
    local here = self.gen_path[1]
    if target and target.open_from then
      local open_from = target.open_from
      return open_from == true or (open_from.x == here.x and open_from.y == here.y)
    else
      return false
    end
  end

  function labirynth:tag_open_from(tag, node)
    if not node then return end
    if not node.open_from then return end
    if node.open_from == true then
      node.open_from = tag
    else
      node.open_from = (tag and tag.x == node.open_from.x and tag.y == node.open_from.y and tag) or nil
    end
  end

  function labirynth:path_to(dir, terrain)
    local here = self.gen_path[1]
    local target = here:neighbour(dir)
    target.open_from = nil
    if target.terrain == "Xu" then
      target.terrain = terrain
    end
    self:tag_open_from(nil, here:neighbour(dir:counterclockwise()))
    local dir_to_mark = dir:clockwise()
    self:tag_open_from(nil, here:neighbour(dir_to_mark))
    for i = 1, 3 do
      dir_to_mark = dir_to_mark:clockwise()
      self:tag_open_from(here, here:neighbour(dir_to_mark))
    end
    local target_dir = dir:opposite():clockwise()
    for i = 1, 3 do
      target_dir = target_dir:clockwise()
      self:tag_open_from(target, target:neighbour(target_dir))
    end
    return target
  end

  function labirynth:chamber(terrain)
    local here = self.gen_path[1]
    local hexes = { here }
    for dir in generator.direction.all() do
      local neighbour = here:neighbour(dir)
      neighbour.terrain = terrain
      self:tag_open_from(here, neighbour)
      table.insert(hexes, neighbour)
      for _, r in ipairs({0, 1, 5}) do
        local wall = neighbour:neighbour(dir:rotate(r))
        if wall and wall.open_from == true then
          self:tag_open_from(neighbour, wall)
        end
      end
    end
    return hexes
  end

  function labirynth:generate(start)
    self.boss_start = self:get(mathx.random(3, cfg.width - 2), mathx.random(3, cfg.height - 2))
    table.insert(self.gen_path, 1, self.boss_start)
    self.boss_start.open_from = nil
    self.boss_start.terrain = "Ker"
    self.boss_start.label = labirynth.gen_turn
    self:chamber("Cer")
    table.insert(self.gen_path, 1, self.boss_start:neighbour(generator.direction.random()))

    while labirynth.gen_path[1] do
      local node = labirynth.gen_path[1]
      local neighbours = {}
      for dir in generator.direction.all() do
        local neighbour = node:neighbour(dir)
        if labirynth:path_open_to(neighbour) then
          table.insert(neighbours, dir)
        end
      end
      if #neighbours > 0 then
      local dir = neighbours[mathx.random(1, #neighbours)]
      labirynth:gen_step(dir, "Ur")
      else
        labirynth:gen_backstep()
      end
  end

  end

  function labirynth:enterance_chamber(center, terrain)
    self.enterance = self.gen_path[1]
    self.enterance.terrain = center
    local hexes = self:chamber(terrain)
    local next_hex = filter(
      function(hex) return hex:on_border() == nil end,
      iter(hexes)
    )
    for i = 1, cfg.player_count do
      local hex = next_hex()
      hex.starting_player = i
      self.starting_locations[i] = hex
    end
    return self:gen_backstep()
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
    self.exit.terrain = terrain
    self:chamber(terrain)
    return self:gen_backstep()
  end

  function labirynth:gen_step(dir, terrain)
    local src = self.gen_path[1]
    local target = src:neighbour(dir)
    if target:on_border() then
      if not self.exit then
        return self:exit_chamber("Ur^Ii")
      end
      if not self.enterance and self:appropriate_enterance()  then
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

  function labirynth:gen_backstep()
    table.remove(self.gen_path, 1)
    return self.gen_path[1]
  end

  return labirynth
end

function generate_labirynth_scenario(cfg)
  local scenario = wesnoth.require("~add-ons/above-and-below/lua/act2/scenario_template.lua")
  local labirynth = labirynth(cfg)
  labirynth:generate()

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
