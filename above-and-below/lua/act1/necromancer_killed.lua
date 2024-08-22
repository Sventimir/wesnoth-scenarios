-- Note: after this event has fired, the following magic item remains
-- defined and can be granted again to another unit that picks up the
-- necklace dropped if the apprentice is killed.
vampiric_necklace = magic.item({
    id = "vampiric-necklace",
    name = "Wampiryczny Naszyjnik",
    image = "items/ankh-necklace.png",
    description = "Ten artefakt daje noszącemu magowi zdolność wyssania życia.",
    cannot_use_message = "Tylko magowie mogą korzystać z mocy tego naszyjnika.",
    effects = {
      {
        apply_to = "attack",
        range = "ranged",
        { "set_specials", {
            mode = "append",
            { "drains", {
                id = "drains",
                name = "drains",
            }}
        }}
      }
    }
})

local locs = locations.empty_hexes_near(7, 5)
local loc = locs[mathx.random(#locs)]
local apprentice = wesnoth.units.create({
    type = "Dark Adept",
    id = "dark-apprentice",
    side = necromancer,
    x = loc.x,
    y = loc.y,
})
wesnoth.units.to_map(apprentice)
vampiric_necklace:grant({ id = apprentice.id }, { silent = true })

function is_mage(u)
  local side = wesnoth.sides[u.side]
  return any(iter(side.recruit), function(unit_type) return unit_type == "Mage" end)
end

local leaders = players.heroes()
mathx.shuffle(leaders)

local killer = wesnoth.units.find_on_map({
    side = wml.variables_proxy.second_unit.side,
    canrecruit = true,
})[1]

-- If a mage player killed the necromancer, then he is the negotiator.
-- Otherwise, if there are mage players, one of them is the negotiator.
-- Otherwise the killer (who is not a mage) is the negotiator.
-- NOTE: without the second argument, `any` returns the first item
-- returned by the iterator, if any.
-- NOTE: leaders were shuffled at random, so if there are multiple mage
-- players, one of them will be chosen at random if a non-mage killed
-- the necromancer.
local negotiator = any(
  chain(
    filter(is_mage, iter({ killer })),
    filter(is_mage, iter(leaders)),
    iter({ killer })
  )
)

local d = dialogue.exchange(
  { apprentice, negotiator },
  {
    "Ratujcie, ratujcie, zacny panie rycerzu!",
    "A co to za obszrpaniec wyskoczył z piwnicy tego podłego nekromanty?",
    "Ja... ekhem",
    "Tylko nie kręć! Byłeś jego uczniem, prawda?",
    "Ja nie..., to znaczy tak... to znaczy ja nie chciałem... On mnie zmusił... Tak, omamił mnie czarami!",
    "Wyluzuj, chłopcze, tu nie gildia magów, tu się walczy o przetrwanie. Każdy walczy tak jak umie.",
    "E... tak, panie. Walczyłem o przetrwanie!"
  }
)

local mage_sides = filter_map(
  function(u) if is_mage(u) then return u.side end end,
  iter(leaders)
)

-- WML variables don't distinguish types. If a string can be parsed as a number, it
-- is immediately converted and fails to compare equal to the same string passed in
-- again. This is a crude workaround this issue. 
mage_sides = as_table(mage_sides)
if #mage_sides > 1 then
  mage_sides = table.concat(mage_sides, ",") -- a string
else
  mage_sides = mage_sides[1] -- a number, as Wesnoth would convert a string anyway
end

local response = dialogue.choice(
  negotiator, 
  {
    [mage_sides] = "Walczyłeś o przetrwanie nekromanty, a teraz będziesz walczył o moje. Proste.",
    [0] = "Koniec żartów. Nikt przyzwoity nie zajmuje się nekromancją. Giń!",
  },
  "can_recruit_dark_adepts"
)
response.wait_description = "Spogląda podejrzliwie na ucznia nekromanty."
for side in players.sides_except(negotiator.side) do
  response:add_viewer(side.side)
end

d:add(response)
d:play()

if wml.variables_proxy.can_recruit_dark_adepts ~= 0 then
  wesnoth.wml_actions.modify_unit({
      { "filter", { id = apprentice.id } },
      side = negotiator.side,
  })
  gui.show_narration({
      portrait=apprentice.portrait,
      title=apprentice.name,
      message="Jest nas więcej, panie. Chętnie zaciągniemy się pod wasze sztandary."
  })
end
-- Other consequences of the choice are applied by scenario WML.
