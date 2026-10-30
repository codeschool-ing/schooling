from fig import Fig

c = Fig("caught", 720, 270,
        {"en": "The planner's tree with error boundaries. The root holds App, which holds WeekNav, WeekSummary and "
               "CourseList. CourseList holds three ErrorBoundary components, one per course, each around a CourseCard. "
               "The statistics CourseCard throws; the error travels up to the boundary directly above it, which draws "
               "the fallback card. The other two boundaries and everything above them are untouched.",
         "pt": "A árvore do planejador com error boundaries. A raiz tem o App, que tem WeekNav, WeekSummary e "
               "CourseList. O CourseList tem três componentes ErrorBoundary, um por curso, cada um em volta de um "
               "CourseCard. O CourseCard de estatística lança um erro; o erro sobe até o boundary logo acima dele, que "
               "desenha o cartão de reserva. Os outros dois boundaries e tudo acima deles ficam intactos."},
        {"en": "An error goes up to the nearest boundary and no further.",
         "pt": "Um erro sobe até o boundary mais próximo, e não passa dele."})
c.box(290, 10, 140, 30, "App", mono=True, tone="wire", text_tone="paper")
for x, n in [(40, "WeekNav"), (210, "WeekSummary"), (470, "CourseList")]:
    c.box(x, 70, 150, 30, n, mono=True, tone="wire", text_tone="paper")
    c.line(360, 40, x + 75, 70)
for i, (name, tone) in enumerate([("statistics", "amber"), ("spanish", "phosphor"), ("chemistry", "phosphor")]):
    x = 300 + i * 140
    c.line(545, 100, x + 60, 130)
    c.box(x, 130, 120, 30, "ErrorBoundary", mono=True, tone=tone, size=10)
    c.line(x + 60, 160, x + 60, 190)
    c.box(x, 190, 120, 40, ["CourseCard", name], mono=True, tone=tone if i else "amber", size=10, dashed=(i == 0))
c.path("M 296 214 C 270 200 270 160 296 148", tone="amber", head_at=(286, 154, 296, 148))
c.text(260, 182, {"en": "throws", "pt": "lança"}, anchor="end", tone="amber", size=10.5)
c.text(360, 254, {"en": "the fallback card", "pt": "o cartão de reserva"}, anchor="middle", tone="amber", size=10.5)
c.text(570, 254, {"en": "drawn as before", "pt": "desenhados como antes"}, anchor="middle", tone="phosphor", size=10.5)
c.text(40, 130, {"en": "untouched:", "pt": "intactos:"}, tone="dim", size=10.5)
c.text(40, 148, {"en": "the week, the summary", "pt": "a semana, o resumo"}, tone="dim", size=10.5)

r = Fig("reset", 720, 230,
        {"en": "Two rows, each going from the week of 12 October to the week of 19 October. Top row, boundaries keyed "
               "by course id: in the week of 12 October the boundary fails, and in the week of 19 October it is the "
               "same boundary, still failed. Bottom row, the list keyed by the week: the week of 12 October has its own "
               "list, which fails; the week of 19 October gets a new list with new boundaries, and its cards draw.",
         "pt": "Duas linhas, cada uma indo da semana de 12 de outubro para a de 19 de outubro. Linha de cima, "
               "boundaries com key pelo id do curso: na semana de 12 o boundary falha, e na semana de 19 é o mesmo "
               "boundary, ainda falho. Linha de baixo, a lista com key pela semana: a semana de 12 tem a sua lista, que "
               "falha; a semana de 19 ganha uma lista nova com boundaries novos, e os cartões aparecem."},
        {"en": "A boundary keeps its failure while its key stays; a new key starts it fresh.",
         "pt": "Um boundary guarda a falha enquanto a key fica; uma key nova o recomeça."})
for row, (label, second, tone, note) in enumerate([
        ("key={course.id}", ["failed: true", {"en": "the same boundary", "pt": "o mesmo boundary"}], "amber",
         {"en": "still the fallback", "pt": "ainda a reserva"}),
        ("key={monday}", ["failed: false", {"en": "a new boundary", "pt": "um boundary novo"}], "phosphor",
         {"en": "the cards draw", "pt": "os cartões aparecem"})]):
    y = 40 + row * 95
    r.text(20, y - 12, label, mono=True, tone=tone, size=11)
    r.box(20, y, 200, 50, [{"en": "week of 12 Oct", "pt": "semana de 12 Oct"}, "failed: true"], tone="amber", size=10.5)
    r.arrow(222, y + 25, 298, y + 25)
    r.text(260, y + 15, "Next week", mono=True, tone="dim", anchor="middle", size=9.5)
    r.box(300, y, 220, 50, [{"en": "week of 19 Oct", "pt": "semana de 19 Oct"}] + [second[0]], tone=tone, size=10.5,
          dashed=(row == 0))
    r.text(410, y + 64, second[1], anchor="middle", tone="dim", size=10)
    r.text(540, y + 25, note, tone=tone, size=11)

FIGS = [c, r]
