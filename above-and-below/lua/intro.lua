local messages = {
  "Nasza podróż rozpoczyna się. Musimy przeprawić się przez góry przed nami.",
  "Po co tak właściwie?",
  "Mamy do spełnienia niezwykle ważną misję, jednak omawianie jej szczegółów w tym momencie nie wydaje mi się konieczne.",
  "Racja. Czasu jest mało. Musimy wędrować prosto na północny wschód.",
  "Nie będzie to łatwe. Słyszałem, że te góry są nawiedzone.",
  "Owszem, a do tego pełne niebezpieczeństw, z których najmniejszym są żyjące tu krasnoludy.",
  "W każdym razie pod względem wzrostu.",
  "Tak.",
  "…",
  "Przed nami tyle różnych dróg.",
  "Uuuuu…",
  "O Baziolu, co ja tutaj robię?",
  "A co ty tutaj robisz?",
  "Coś mi się widzi, że z tego dialogu wyszło dno…",
  "Zero?",
  "Czyli nic. Trudno.",
  "W drogę. Nie ma czasu do stracenia."
}

aab_run_dialog(
  wesnoth.units.find({ side = player_sides, canrecruit = true }),
  messages,
  mathx.random(1, players_count)
)
