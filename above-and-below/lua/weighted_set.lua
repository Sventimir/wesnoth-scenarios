Weighted = {}
Weighted.__index = Weighted

function Weighted.new(item, weight)
  return setmetatable({ item = item, weight = weight }, Weighted)
end

WeightedSet = {}
WeightedSet.__index = WeightedSet

function WeightedSet.new()
  return setmetatable({ items = {} }, WeightedSet)
end

function WeightedSet:insert(item, weight)
  table.insert(self.items, Weighted.new(item, weight))
end

function WeightedSet:random()
  local total_weight = fold(
    function(acc, item) return acc + item.weight end,
    0,
    iter(self.items)
  )
  if total_weight > 0 then
    local r = mathx.random(1, total_weight)
    for item in iter(self.items) do
      r = r - item.weight
      if r <= 0 then
        return item.item
      end
    end
  end
end

return WeightedSet
