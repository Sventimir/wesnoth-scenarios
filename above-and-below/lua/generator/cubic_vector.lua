wesnoth.require("~add-ons/above-and-below/lua/core.lua")

Vec = {}
Vec.__index = Vec

function Vec.new(s, se)
  return setmetatable({ s = s, se = se}, Vec)
end

function Vec:sw()
  return - self.s - self.se
end

function Vec:__add(other)
  return Vec.new(self.s + other.s, self.se + other.se)
end

function Vec:__sub(other)
  return Vec.new(self.s - other.s, self.se - other.se)
end

function Vec:__unm()
  return Vec.new(-self.s, -self.se)
end

function Vec:__eq(other)
  return self.s == other.s and self.se == other.se
end

function Vec:__tostring()
  return string.format("(%d, %d, %d)", self:sw(), self.s, self.se)
end

function Vec:scale(f)
  return Vec.new(self.s * f, self.se * f)
end

function Vec:translate(x, y)
  return x + self.se, y + self.s + math.floor(self.se / 2)
end

function Vec:length()
  return math.max(math.abs(self.s), math.abs(self.se), math.abs(self.s + self.se))
end

-- We've got two possibilities. Either self.s and self.se have the same sign,
-- or they have different signs. If the same, then self:sw() is always the
-- greatest, so we select pairs of natural numbers that add up to the radius.
-- If different, then greater of the two is the radius, so we select that as
-- a constant and any other number that is smaller.
function Vec.equidistant(radius)
  local function with_nats(f)
    local state = -1
    return function()
      state = state + 1
      if state < radius then
        return f(state)
      end
    end
  end
  return chain(
    with_nats(function(n) return Vec.new(n, radius - n) end), -- (0, 1)
    with_nats(function(n) return Vec.new(-n, -radius + n) end), -- (0, -1)
    with_nats(function(n) return Vec.new(radius, -n) end), -- (1, 0)
    with_nats(function(n) return Vec.new(-radius, n) end), -- (-1, 0)
    with_nats(function(n) return Vec.new(-n - 1, radius) end), -- (-1, 1)
    with_nats(function(n) return Vec.new(n + 1, -radius) end) -- (1, -1)
  )
end

Vec.eigenvector = {
  n = Vec.new(-1, 0),
  ne = Vec.new(-1, 1),
  se = Vec.new(0, 1),
  s = Vec.new(1, 0),
  sw = Vec.new(1, -1),
  nw = Vec.new(0, -1)
}

function Vec.eigenvector.random()
  local names = { "n", "ne", "se", "s", "sw", "nw" }
  return Vec.eigenvector[names[mathx.random(1, 6)]]
end

return Vec
