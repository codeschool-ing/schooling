from fig import Fig

k = Fig("skip", 720, 230,
        {"en": "Ticking Wednesday's session with SessionRow memoised. CourseScreen and List render again. Row s1 "
               "receives the same session object and the same onToggle, so React compares, finds nothing changed, and "
               "skips it. Row s2 receives a new session object, done true, so it is drawn.",
         "pt": "Marcando a sessão de quarta com o SessionRow memoizado. O CourseScreen e o List renderizam de novo. A "
               "linha s1 recebe o mesmo objeto de sessão e o mesmo onToggle, então o React compara, não acha mudança e "
               "a pula. A linha s2 recebe um objeto de sessão novo, done true, então é desenhada."},
        {"en": "memo compares each prop; the same object is a skipped render.",
         "pt": "O memo compara cada prop; o mesmo objeto é uma renderização pulada."})
k.box(270, 14, 180, 30, "CourseScreen", mono=True, tone="wire", text_tone="paper")
k.box(270, 64, 180, 30, "List", mono=True, tone="wire", text_tone="paper")
k.line(360, 44, 360, 64)
k.box(90, 130, 230, 60, ["SessionRow · s1", {"en": "same session, same onToggle", "pt": "mesma sessão, mesmo onToggle"}],
      tone="dim", text_tone="paper", dashed=True, size=10)
k.box(400, 130, 230, 60, ["SessionRow · s2", {"en": "a new session: done true", "pt": "uma sessão nova: done true"}],
      tone="phosphor", size=10)
k.line(360, 94, 205, 130)
k.line(360, 94, 515, 130)
k.text(205, 212, {"en": "skipped", "pt": "pulada"}, anchor="middle", tone="dim", size=11)
k.text(515, 212, {"en": "drawn", "pt": "desenhada"}, anchor="middle", tone="phosphor", size=11)
FIGS = [k]
