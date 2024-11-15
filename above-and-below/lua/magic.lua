-- Define various magical abilities and items
function is_magical(attack)
  return any(
    function(special) return special[2].id == "magical" end,
    iter(attack.specials)
  )
end

function item(props)
  local this = props

  function this:to_wml(options)
    local wml = {
      name = self.name,
      image = self.image,
      description = self.description,
      cannot_use_message = self.cannot_use_message,
      duration = "forever",
    }
    for effect in iter(self.effects) do
      table.insert(wml, { "effect", effect })
    end
    for key, val in pairs(options) do
      wml[key] = val
    end
    return wml
  end

  function this:place_on_map(x, y, options)
    local event_id = self.id .. "pickup"
    self.location = { x = x, y = y }
    wesnoth.wml_actions.item({
        name = self.id,
        x = x,
        y = y,
        image = self.image,
    })
    wesnoth.game_events.add({
        id = event_id,
        name = "moveto",
        first_time_only = false,
        filter = {{ "filter", self.location }},
        action = function()
          local unit = wesnoth.units.find_on_map(self.location)[1]
          local ranged_attack = any(
            function(attack) return attack.range == "ranged" and is_magical(attack) end,
            iter(unit.attacks)
          )
          if ranged_attack then
            self:grant({ id = unit.id }, options)
            self:remove_from_map()
            wesnoth.game_events.remove(event_id)
          else
            gui.show_narration({ message = self.cannot_use_message }) 
          end
        end
    })
  end

  function this:drop_from(unit, options)
    this:place_on_map(unit.x, unit.y, options)
  end

  function this:grant(filter, options)
    local wml = self:to_wml(options or {})
    table.insert(wml, { "filter", filter })
    wesnoth.wml_actions.object(wml)
  end

  function this:remove_from_map()
    wesnoth.wml_actions.remove_item(self.location)
    self.location = nil
  end
 
  return this
end


return {
  attack = {
    is_magical = is_magical,
  },
  item = item
}
