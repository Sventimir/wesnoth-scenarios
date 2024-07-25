local function make(side)
  local obj = { side = side, total_weight = 0 }

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

return { make = make }
