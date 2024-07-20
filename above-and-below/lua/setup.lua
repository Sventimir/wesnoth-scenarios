function aab_run_dialog(speakers, messages, first_speaker, next_speaker)
  local next_speaker = next_speaker or function(current_speaker)
    if current_speaker < #speakers then
      return current_speaker + 1
    else
      return 1
    end
  end
  local current_speaker = first_speaker or 1
  local current_message = 1
  while current_message <= #messages do
    wesnoth.show_message_dialog({
      portrait = speakers[current_speaker].portrait,
      message = messages[current_message]
    })
    current_message = current_message + 1
    current_speaker = next_speaker(current_speaker)
  end
end
