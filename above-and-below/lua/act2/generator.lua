local player_colors = { "red", "blue", "green" }

local function north(x, y)
  return x, y - 1
end
local function northeast(x, y)
  return x + 1, y - (x % 2)
end
local function southeast(x, y)
  return x + 1, y - (x % 2) + 1
end
local function south(x, y)
  return x, y + 1
end
local function southwest(x, y)
  return x - 1, y - (x % 2) + 1
end
local function northwest(x, y)
  return x - 1, y - (x % 2)
end

local directions = {
  n = { counterclockwise = "nw", clockwise = "ne", opposite = "s", translate = north },
  ne = { counterclockwise = "n", clockwise = "se", opposite = "sw", translate = northeast },
  se = { counterclockwise = "ne", clockwise = "s", opposite = "nw", translate = southeast },
  s = { counterclockwise = "se", clockwise = "sw", opposite = "n", translate = south },
  sw = { counterclockwise = "s", clockwise = "nw", opposite = "ne", translate = southwest },
  nw = { counterclockwise = "sw", clockwise = "n", opposite = "se", translate = northwest }
}

local function tag_open_from(tag, node)
  if not node then return end
  if not node.open_from then return end
  if node.open_from == true then
    node.open_from = tag
  else
    node.open_from = (tag and tag.x == node.open_from.x and tag.y == node.open_from.y and tag) or nil
  end
end

local function path_open(src, target)
  if target and target.open_from then
    local open_from = target.open_from
    return open_from == true or (open_from.x == src.x and open_from.y == src.y)
  else
    return false
  end
end

function labirynth(cfg)
  local labirynth = { exits = {}, starting_locations = {} }
  local current_path = {}

  function node(x, y)
    local node = {
      x = x,
      y = y,
      terrain = "Xu",
      open_from = true
    }

    function node:neighbour(dir)
      return labirynth:get(dir.translate(self.x, self.y))
    end

    function node:path_to(dir)
      local target = self:neighbour(dir)
      target.open_from = nil
      target.terrain = "Uu"
      if target.x == 1 or target.x == cfg.width or target.y == 1 or target.y == cfg.height then
        table.insert(labirynth.exits, target)
      end
      tag_open_from(nil, self:neighbour(directions[dir.counterclockwise]))
      local dir_to_mark = dir.clockwise
      tag_open_from(nil, self:neighbour(directions[dir_to_mark]))
      for i = 1, 3 do
        dir_to_mark = directions[dir_to_mark].clockwise
        tag_open_from(self, self:neighbour(directions[dir_to_mark]))
      end
      local target_dir = directions[directions[dir.opposite].clockwise]
      for i = 1, 3 do
        target_dir = directions[target_dir.clockwise]
        tag_open_from(target, target:neighbour(target_dir))
      end
      return target
    end

    return node
  end

  for y = 1, cfg.height do
    local row = {}
    for x = 1, cfg.width do
      table.insert(row, node(x, y))
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
  local turn = 0
  current_path[1].label = turn
  while current_path[1] do
    local neighbours = {}
    for _, dir in pairs(directions) do
      local neighbour = current_path[1]:neighbour(dir)
      if neighbour then
      end
      if path_open(current_path[1], neighbour) then
        table.insert(neighbours, dir)
      end
    end
    if #neighbours > 0 then
      local dir = neighbours[mathx.random(1, #neighbours)]
      local target = current_path[1]:path_to(dir)
      turn = turn + 1
      target.label = turn
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
      team_name = 1,
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
    team_name = 2,
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
