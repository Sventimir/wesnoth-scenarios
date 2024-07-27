local function add(x, y)
  return x + y
end

local function sub(x, y)
  return x - y
end

local function mul(x, y)
  return x * y
end

local function div(x, y)
  return x / y
end

-- Note: These start with 1, just like array indices.
local function nats()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end

return {
  add = add,
  sub = sub,
  mul = mul,
  div = div,
  nats = nats
}
