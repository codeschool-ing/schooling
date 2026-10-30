from fig import Canvas


def pushpull(T):
    c = Canvas(720, 250, T(
        "Two signals, planned and done, feed a computed, left, which a template reads. When done is set, a "
        "notification travels forward to left, marking it stale, and nothing is computed. When the template next "
        "reads left, left pulls the current values of planned and done back and computes once.",
        "Dois signals, planned e done, alimentam um computed, left, que um template lê. Quando done é definido, um "
        "aviso vai adiante até left, marcando-o como desatualizado, e nada é calculado. Quando o template lê left da "
        "próxima vez, left puxa de volta os valores atuais de planned e done e calcula uma vez."))
    def node(x, y, w, label, sub, col):
        c.rect(x, y, w, 46, fill="var(--panel)", stroke=col)
        c.text(x + w / 2, y + 16, label, mono=True, size=11)
        c.text(x + w / 2, y + 33, sub, size=9, fill="var(--paper-dim)")
    node(30, 40, 150, "planned", "signal(165)", "var(--wire)")
    node(30, 150, 150, "done", "signal(90)", "var(--amber)")
    node(290, 95, 170, "left", "computed", "var(--phosphor)")
    node(560, 95, 130, "{{ left() }}", T("the template", "o template"), "var(--wire)")
    c.line(180, 63, 288, 108, arrow=True)
    c.line(180, 173, 288, 130, stroke="var(--amber)", arrow=True)
    c.line(460, 118, 558, 118, arrow=True)
    c.text(105, 214, T("1. done.set(115)", "1. done.set(115)"), mono=True, size=10, fill="var(--amber)")
    c.text(235, 178, T("2. \"left is stale\"", "2. \"left está velho\""), size=9.5, anchor="start", fill="var(--amber)")
    c.path("M558 136 C 520 200, 420 200, 400 145", stroke="var(--phosphor)", dash="4 3")
    c.line(402, 150, 400, 145, stroke="var(--phosphor)", arrow=True)
    c.text(500, 205, T("3. the next read pulls", "3. a próxima leitura puxa"), size=9.5, fill="var(--phosphor)")
    c.text(375, 70, T("4. computes once, then remembers", "4. calcula uma vez, depois lembra"), size=9.5, fill="var(--phosphor)")
    c.caption = T("A change only marks what depends on it as stale. The computation happens when somebody reads.",
                  "Uma mudança só marca como velho o que depende dela. O cálculo acontece quando alguém lê.")
    return c


FIGURES = [("computed", pushpull)]
