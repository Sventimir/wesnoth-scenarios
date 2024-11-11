hex = wesnoth.require("~add-ons/above-and-below/lua/act2/hex")
directions = hex.directions

local player_colors = { "red", "blue", "green" }

function labirynth(cfg)
  local labirynth = {
    exits = {},
    starting_locations = {},
    width = cfg.width,
    height = cfg.height
  }
  local current_path = {}

  for y = 1, cfg.height do
    local row = {}
    for x = 1, cfg.width do
      table.insert(row, hex.node(labirynth, x, y))
    end
    table.insert(labirynth, row)
  end

  function labirynth:get(x, y)
    return (self[y] or {})[x]
  end

  function labirynth:as_map()
    local map = ""
    for x = 0, cfg.width + 1 do
      map = map .. "Xu"
      if x < cfg.width + 1 then
        map = map .. ", "
      else
        map = map .. "\n"
      end
    end
    for y, row in ipairs(self) do
      map = map .. "Xu, "
      for x, node in ipairs(row) do
        if node.starting_player then
          map = map .. node.starting_player .. " "
        end
        map = map .. node.terrain .. ", "
      end
      map = map .. "Xu\n"
    end
    for x = 0, cfg.width + 1 do
      map = map .. "Xu"
      if x < cfg.width + 1 then
        map = map .. ", "
      end
    end
    return map
  end

  labirynth.boss_start = labirynth:get(mathx.random(1, cfg.width), mathx.random(1, cfg.height))
  table.insert(current_path, 1, labirynth.boss_start)
  current_path[1].open_from = nil
  current_path[1].terrain = "Uu"
  -- local turn = 0
  -- current_path[1].label = turn
  while current_path[1] do
    local neighbours = {}
    for _, dir in pairs(directions) do
      local neighbour = current_path[1]:neighbour(dir)
      if neighbour then
      end
      if hex.path_open(current_path[1], neighbour) then
        table.insert(neighbours, dir)
      end
    end
    if #neighbours > 0 then
      local dir = neighbours[mathx.random(1, #neighbours)]
      local target = current_path[1]:path_to(dir)
      -- turn = turn + 1
      -- target.label = turn
      table.insert(current_path, 1, target)
    else
      table.remove(current_path, 1)
    end
  end

  for i = 1, cfg.player_count do
    local l = table.remove(labirynth.exits, mathx.random(1, #labirynth.exits))
    l.starting_player = i
    table.insert(labirynth.starting_locations, l)
  end

  return labirynth
end

function generate_labirynth_scenario(cfg)
  local scenario = wesnoth.require("~add-ons/above-and-below/lua/act2/scenario_template.lua")
  local labirynth = labirynth(cfg)

  scenario.map_data = labirynth:as_map()

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
