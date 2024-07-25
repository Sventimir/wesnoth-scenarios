require("../wesnoth-mock")
tactics = require("../ai_tactics")

wesnoth.units.create({
  id = "unit1",
  side = 1,
  role = nil
})

local unit = wesnoth.units.get("unit1")

wesnoth.sides.create(1)
wesnoth.sides[1].variables.tactics = {
  tactic = {
    {
      role = "role1",
      count = 1,
      weight = 1
    },
    {
      role = "role2",
      count = 2,
      weight = 2
    },
    {
      role = "role3",
      count = 3,
      weight = 1
    },
    {
      role = "role4",
      count = 2,
      weight = 1
    }
  }
}

t = tactics.make(1)
role3 = t:find("role3").value
assert(role3.count == 3)
assert(role3.weight == 1)

chosen = t:choose_most_required(unit)
