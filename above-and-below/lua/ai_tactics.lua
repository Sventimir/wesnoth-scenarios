require("core")

local function base(side)
  local obj = { side = side }

  function obj:all()
    return wml.array_access.get("tactics.tactic", wesnoth.sides[self.side].variables)
  end

  function obj:find(role)
    for i, tactic in ipairs(self:all()) do
      if tactic.role == role then
        return { index = i, value = tactic }
      end
    end
  end

  function obj:set_role(role, unit)
    if role == nil then
      return
    end
    wesnoth.wml_actions.role({
        id = unit.id,
        role = role
    })
  end

  function obj:choose(unit)
    -- do nothing; no role is assigned
  end

  function obj:unit_lost(unit)
    -- do nothing
  end

  return obj
end

local function random(strategy)
  strategy.total_weight = 0

  function strategy:choose_random(unit)
    local idx = mathx.random(1, self.total_weight)
    for _, tactic in ipairs(self:all()) do
      local weight = tactic.weight or 1
      if idx <= weight then
        self:set_role(tactic.role, unit)
        return
      else
        idx = idx - weight
      end        
    end
  end

  strategy.choose = strategy.choose_random

  for _, tactic in ipairs(strategy:all()) do
    strategy.total_weight = strategy.total_weight + (tactic.weight or 1)
  end

  return strategy
end

local function most_fitting(chooser, strategy)
  strategy.chooser = chooser

  function strategy:choose(unit)
    local all = self:all()
    local best = all[1]
    for _, tactic in ipairs(all) do
      best = self.chooser.better(best, tactic)
    end
    self:set_role(best.role, unit)
    self.chooser.adjust_chosen(best)
  end

  function strategy:unit_lost(unit)
    local role = wesnoth.units.get(unit.id).role
    if role == nil then
      return
    end
    local tactic = self:find(role)
    self.chooser.adjust_lost(tactic)
  end
  
  return strategy
end

local count_chooser = {
  better = function(a, b)
    return a.required_count < b.required_count and b or a
  end,
  adjust_chosen = function(tactic)
    tactic.required_count = tactic.required_count - 1
  end,
  adjust_lost = function(tactic)
    tactic.required_count = tactic.required_count + 1
  end
}

local mod = {
  base = base,
  random = random,
  most_required = function(strategy) return most_fitting(count_chooser, strategy) end,
  most_fitting = most_fitting,
  choosers = {
    count = count_chooser
  },
  tactics = {}
}

function mod:choose_tactics(unit)
  self.tactics[unit.side]:choose(unit)
end

function mod:unit_lost(unit)
  self.tactics[unit.side]:unit_lost(unit)
end

for side in wesnoth.sides.iter({ {"not", {side = player_sides } } }) do
  if side.variables.tactics then
    local typ = side.variables.tactics.type
    mod.tactics[side.side] = mod[typ](mod.base(side.side))
  end
end

return mod
