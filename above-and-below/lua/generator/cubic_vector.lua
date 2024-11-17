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
  return string.format("[%d, %d, %d]", self:sw(), self.s, self.se)
end

function Vec:scale(f, round)
  local rnd = round or mathx.floor
  return Vec.new(rnd(self.s * f), rnd(self.se * f))
end

function Vec:translate(x, y)
  local round = (x % 2 == 0) and mathx.ceil or mathx.floor
  return x + self.se, y + self.s + round(self.se / 2)
end

function Vec:length()
  return mathx.max(mathx.abs(self.s), mathx.abs(self.se), mathx.abs(self.s + self.se))
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
    with_nats(function(n) return Vec.new(-radius, n) end), -- (-1, 0)
    with_nats(function(n) return Vec.new(-n - 1, radius) end), -- (-1, 1)
    with_nats(function(n) return Vec.new(n, radius - n) end), -- (0, 1)
    with_nats(function(n) return Vec.new(radius, -n) end), -- (1, 0)
    with_nats(function(n) return Vec.new(n + 1, -radius) end), -- (1, -1)
    with_nats(function(n) return Vec.new(-n, -radius + n) end) -- (0, -1)
  )
end

Vec.eigenvector = {
  n = Vec.new(-1, 0), -- 1
  ne = Vec.new(-1, 1), -- 2
  se = Vec.new(0, 1), -- 5
  s = Vec.new(1, 0), -- 7
  sw = Vec.new(1, -1), -- 6
  nw = Vec.new(0, -1) -- 3
}

function Vec.eigenvector.id(v)
  return (v.s + 1) * 3 + v.se + 1
end

local eigenvector_names = { [0] = "n", "ne", "se", "s", "sw", "nw" }

function Vec.eigenvector.random()
  return Vec.eigenvector[eigenvector_names[mathx.random(0, 5)]]
end

-- Return a triplet of 3 eigenvectors that are not equal and not opposite of each other.
function Vec.eigenvector.random_triplet()
  local choice = mathx.random(0, 5)
  return Vec.eigenvector[eigenvector_names[choice]],
    Vec.eigenvector[eigenvector_names[(choice + 1) % 6]],
    Vec.eigenvector[eigenvector_names[(choice + 2) % 6]]
end

function Vec.eigenvector.clockwise(v)
  return Vec.new(v.s + v.se, -v.s)
end

function Vec.eigenvector.counterclockwise(v)
  return Vec.new(-v.se, v.se + v.s)
end

return Vec
