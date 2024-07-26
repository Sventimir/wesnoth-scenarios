require("test/assert")
require("../wesnoth-mock")
tactics = require("../ai_tactics")

wesnoth.sides.create(1)
wesnoth.sides[1].variables.tactics = {
  tactic = {
    {
      role = "role1",
      required_count = 1,
      weight = 1
    },
    {
      role = "role2",
      required_count = 2,
      weight = 2
    },
    {
      role = "role3",
      required_count = 3,
      weight = 1
    },
    {
      role = "role4",
      required_count = 2,
      weight = 1
    }
  }
}

wesnoth.sides.create(2)
wesnoth.sides[2].variables.tactics = {
  tactic = {
    {
      role = "role1",
      required_count = 0,
      weight = 1
    },
    {
      role = "role2",
      required_count = 0,
      weight = 2
    },
    {
      role = "role3",
      required_count = 0,
      weight = 1
    },
    {
      role = "role4",
      required_count = 0,
      weight = 1
    }
  }
}

wesnoth.units.create({
  id = "unit1",
  side = 1,
  role = nil
})

wesnoth.units.create({
  id = "unit2",
  side = 2,
  role = nil
})

t = tactics.most_required(tactics.base(1))
role3 = t:find("role3").value
assert_equal(role3.required_count, 3)
assert_equal(role3.weight, 1)

t:choose(wesnoth.units.get("unit1"))
assert(wesnoth.units.get("unit1").role == "role3")

random = tactics.random(tactics.base(2))
random:choose(wesnoth.units.get("unit2"))
assert_equal(wesnoth.units.get("unit2").role, "role1")
