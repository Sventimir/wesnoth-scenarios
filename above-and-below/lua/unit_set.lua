require("core")

function make(units)
  local set = {}

  if type(units) == "table" then
    for _, unit in ipairs(units) do
      table.insert(set, unit)
    end
  else
    for unit in units do
      table.insert(set, unit)
    end
  end

  function set:filter(predicate)
    return make(filter(predicate, iter(self)))
  end

  function set:random()
    return mathx.random_choice(self)
  end

  function set:insert(unit)
    for i, u in ipairs(self) do
      if u.id == unit.id then
        self[i] = unit
        return
      end
    end
    table.insert(self, unit)
  end

  function set:pop(predicate)
    for i, u in ipairs(self) do
      if predicate(u) then
        return table.remove(self, i)
      end
    end
  end

  return set
end


return {
  make = make
}
