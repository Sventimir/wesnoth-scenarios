require("core")

function line(speaker, message)
  local l = { speaker = speaker, message = message }

  function l:play()
    gui.show_narration({
      portrait = self.speaker.portrait,
      title = self.speaker.name,
      message = self.message
    })
  end

  return l
end

function choice(speaker, options, var)
  local c = {
    speaker = speaker or {},
    viewers = {},
    options = options,
    var = var or "dialog_choice"
  }

  function c:add_option(value, text)
    self.options[value] = text
  end

  function c:add_viewer(side)
    table.insert(self.viewers, side)
  end

  function c:play()
    local dialog = {
      speaker = self.speaker.id,
      side_for = self.speaker.side,
      variable = self.var,
      wait_description = self.wait_description
    }
    for value, text in pairs(self.options) do
      table.insert(dialog, { "option", {
                               message = text,
                                value = value
      }})
    end
    wesnoth.wml_actions.message(dialog)

    for _, side in ipairs(self.viewers) do
      gui.show_narration({
        portrait = self.speaker.portrait,
        title = self.speaker.name,
        message = self.options[wml.variables[self.var]]
      })
    end

    function c:clear_var()
      wesnoth.wml_actions.clear_variable({ name = self.var })
    end

    return wml.variables[self.var]
  end

  return c
end

function make(...)
  local d = ... or {}

  function d:add(line)
    table.insert(self, line)
  end

  function d:play()
    for _, line in ipairs(self) do
      line:play()
    end
  end

  return d
end

function exchange(speakers, messages)
  local d = make()

  for i, message in ipairs(messages) do
    d:add(line(speakers[(i % #speakers) + 1], messages[i]))
  end

  return d
end

return {
  line = line,
  choice = choice,
  make = make,
  exchange = exchange
}
