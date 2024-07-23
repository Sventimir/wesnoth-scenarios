function aab_run_dialog(speakers, messages, first_speaker, next_speaker)
  local next_speaker = next_speaker or function(current_speaker)
    if current_speaker < #speakers then
      return current_speaker + 1
    else
      return 1
    end
  end
  local current_speaker = first_speaker or 1
  local current_message = 1
  while current_message <= #messages do
    local speaker = speakers[current_speaker]
    gui.show_narration({
      portrait = speaker.portrait,
      title = speaker.name,
      message = messages[current_message]
    })
    current_message = current_message + 1
    current_speaker = next_speaker(current_speaker)
  end
end

-- Put guardians in dwarven villages.
local dwarven_villages = wesnoth.map.find({
    area = "dwarven-land",
    gives_income = true
})

for _, village in ipairs(dwarven_villages) do
  wesnoth.map.set_owner(village, dwarves)
  guard = wesnoth.units.create({
      type = "Dwarvish Guardsman",
      side = dwarves,
      x = village.x,
      y = village.y
  })
  wesnoth.units.to_map(guard)
end

function make_tactics(side)
  local obj = { side = side, total_weight = 0 }

  function obj:all()
    return wml.array_access.get("tactics.tactic", wesnoth.sides[self.side].variables)
  end

  function obj:find(role)
    for i, tactic in ipairs(self:all()) do
      if tactic.role == role then
        return { index = i, value = tactic}
      end
    end
  end

  function obj:adjust_count(role, value)
    local tactic = self:find(role)
    if tactic == nil then
      return
    end
    -- sadly, with different access methods, arrays are indexed differently :/
    local v = string.format("tactics.tactic[%d].count", tactic.index - 1)
    wesnoth.sides[self.side].variables[v] = tactic.value.count + value
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

  function obj:choose_random(unit)
    local idx = mathx.random(1, self.total_weight)
    for _, tactic in ipairs(self:all()) do
      if idx <= tactic.weight then
        self:set_role(tactic.role, unit)
        self:adjust_count(tactic.role, -1)
        return
      else
        idx = idx - tactic.weight
      end        
    end
  end

  function obj:choose_most_required(unit)
    local most_needed = { role = nil, count = 0 }
    for _, tactic in ipairs(self:all()) do
      if tactic.count > most_needed.count then
        most_needed = tactic
      end
    end
    if most_needed.role == nil then
      self:choose_random(unit)
    else
      self:set_role(most_needed.role, unit)
      self:adjust_count(most_needed.role, -1)
    end
  end
  
  for _, tactic in ipairs(obj:all()) do
    obj.total_weight = obj.total_weight + tactic.weight
  end

  return obj
end

tactics = {}
for side in wesnoth.sides.iter() do
  if side.variables.tactics ~= nil then
    tactics[side.side] = make_tactics(side.side)
  end
end

function choose_tactic(unit)
  local side = unit.side
  if tactics[side] == nil then
    return
  end
  if side == dwarves then
    tactics[side]:choose_most_required(unit)
  else
    tactics[side]:choose_random(unit)
  end
end
