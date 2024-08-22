-- Define various magical abilities and items
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

  function this:grant(filter, options)
    local wml = self:to_wml(options or {})
    table.insert(wml, { "filter", filter })
    wesnoth.wml_actions.object(wml)
  end
 
  return this
end


return {
  item = item
}
