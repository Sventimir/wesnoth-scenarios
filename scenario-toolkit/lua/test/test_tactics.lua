require("test/assert")
require("../wesnoth-mock")

wesnoth.sides.create(1)
wesnoth.sides[1].variables.tactics = {
  type = "most_required",
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
  type = "random",
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

tactics = require("../ai_tactics")

role3 = tactics.tactics[1]:find("role3").value
assert_equal(role3.required_count, 3)
assert_equal(role3.weight, 1)

tactics.tactics[1]:choose(wesnoth.units.get("unit1"))
assert_equal(wesnoth.units.get("unit1").role, "role3")

tactics.tactics[2]:choose(wesnoth.units.get("unit2"))
assert_equal(wesnoth.units.get("unit2").role, "role1")
