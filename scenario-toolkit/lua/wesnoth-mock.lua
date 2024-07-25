require("core")

local sides = {}
local units = { _units = {} }

local function create_unit(wml)
  units._units[wml.id] = wml
end

local function get_unit(id)
  return units._units[id]
end

units.get = get_unit
units.create = create_unit

local function create(side)
  sides[side] = { variables = {} }
end

sides.create = create

local function array_get(key, tbl)
  local res = tbl
  for k in str.split(key, ".") do
    res = res[k]
  end
  return res
end

local function role(args)
  local u = get_unit(args.id)
  u.role = args.role
end



wesnoth = {
  sides = sides,
  units = units,
  wml_actions = { role = role }
}

wml = {
  array_access = {
    get = array_get
  }
}

