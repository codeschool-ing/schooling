from fig import Canvas


def chain(T):
    c = Canvas(720, 230, T(
        "The chain of values in the planner page. week is state. thisWeek is derived from week and the sessions. total "
        "and byCourse are both derived from thisWeek. The markup reads total, byCourse and week. Pressing Previous week "
        "sets week, and the change travels along the chain to the label, the course minutes and the total.",
        "A cadeia de valores da página do planner. week é estado. thisWeek é derivado de week e das sessões. total e "
        "byCourse são os dois derivados de thisWeek. A marcação lê total, byCourse e week. Apertar Previous week define "
        "week, e a mudança percorre a cadeia até o rótulo, os minutos dos cursos e o total."))
    def box(x, y, w, label, sub, stroke):
        c.rect(x, y, w, 50, fill="var(--ink)", stroke=stroke)
        c.text(x + w / 2, y + 19, label, mono=True, size=11, fill="var(--paper)" if stroke == "var(--wire)" else stroke)
        c.text(x + w / 2, y + 37, sub, size=9.5, fill="var(--paper-dim)")
    box(20, 40, 120, "week", "$state", "var(--amber)")
    box(20, 140, 120, "sessions", T("data", "dados"), "var(--wire)")
    box(200, 90, 130, "thisWeek", "$derived", "var(--phosphor)")
    box(390, 40, 130, "total", "$derived", "var(--phosphor)")
    box(390, 140, 130, "byCourse", "$derived.by", "var(--phosphor)")
    c.rect(580, 40, 120, 150, fill="var(--panel)", stroke="var(--wire)")
    c.text(640, 60, T("the markup", "a marcação"), size=10.5, weight="600")
    for i, s in enumerate(["Week of …", "… min", "… minutes"]):
        c.text(640, 95 + i * 30, s, mono=True, size=10, fill="var(--paper-dim)")
    c.line(140, 65, 198, 108, stroke="var(--phosphor)", arrow=True)
    c.line(140, 165, 198, 122, stroke="var(--wire)", arrow=True)
    c.line(330, 108, 388, 68, stroke="var(--phosphor)", arrow=True)
    c.line(330, 122, 388, 160, stroke="var(--phosphor)", arrow=True)
    c.line(520, 65, 578, 155, stroke="var(--phosphor)", arrow=True)
    c.line(520, 165, 578, 125, stroke="var(--phosphor)", arrow=True)
    c.path("M80 40 C 80 15, 600 10, 620 36", stroke="var(--amber)", dash="4 3")
    c.line(617, 32, 621, 38, stroke="var(--amber)", arrow=True)
    c.text(360, 214, T("a button sets week; everything downstream is recalculated when next read",
                       "um botão define week; tudo o que vem depois é recalculado quando for lido de novo"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("Only week is set by hand. Every other value on the way to the screen is derived from it.",
                  "Só week é definido à mão. Todo outro valor no caminho até a tela é derivado dele.")
    return c


def proxy(T):
    c = Canvas(720, 250, T(
        "The sessions array inside a $state proxy. The proxy holds one signal per property it has been asked about: "
        "the array's length, and for the session of the 24th its minutes and its done. The total read minutes, so it "
        "is on that signal's list; the toggle button read done. Assigning session.done reaches the button and not the "
        "total; pushing a session changes length and reaches everything that walked the array.",
        "O array de sessões dentro de um proxy $state. O proxy guarda um signal por propriedade que já foi lida: o "
        "length do array e, para a sessão do dia 24, os seus minutes e o seu done. O total leu minutes, então está na "
        "lista desse signal; o botão de alternar leu done. Atribuir session.done chega ao botão e não ao total; um push "
        "muda o length e chega a tudo o que percorreu o array."))
    c.rect(20, 30, 330, 200, fill="var(--panel)", stroke="var(--amber)", dash="5 3")
    c.text(36, 48, T("$state proxy around sessions", "proxy $state em volta de sessions"), size=10.5, anchor="start", fill="var(--amber)")
    c.rect(40, 66, 120, 36, fill="var(--ink)", stroke="var(--amber)")
    c.text(100, 84, "length", mono=True, size=10.5, fill="var(--amber)")
    c.text(54, 140, "sessions[5]", mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    c.rect(54, 154, 120, 40, fill="var(--ink)", stroke="var(--amber)")
    c.text(114, 174, "minutes", mono=True, size=10.5, fill="var(--amber)")
    c.rect(194, 154, 120, 40, fill="var(--ink)", stroke="var(--amber)")
    c.text(254, 174, "done", mono=True, size=10.5, fill="var(--amber)")
    readers = [(60, T("everything that walked the array", "tudo o que percorreu o array")),
               (120, "total, byCourse"),
               (180, T("the session's toggle button", "o botão de alternar da sessão"))]
    for y, s in readers:
        c.rect(450, y, 250, 40, fill="var(--panel)", stroke="var(--phosphor)")
        c.text(575, y + 20, s, size=10.5, mono=(s == "total, byCourse"))
    c.line(160, 84, 448, 80, stroke="var(--phosphor)", arrow=True)
    c.path("M114 154 C 114 112, 380 128, 440 139", stroke="var(--phosphor)")
    c.line(436, 138, 446, 140, stroke="var(--phosphor)", arrow=True)
    c.line(314, 178, 448, 198, stroke="var(--phosphor)", arrow=True)
    c.text(400, 40, T("readers", "leitores"), size=10, fill="var(--paper-dim)", anchor="start")
    c.caption = T("One signal per property that was read. Marking a session done reaches its button, and not the total.",
                  "Um signal por propriedade lida. Marcar uma sessão como feita chega ao botão dela, e não ao total.")
    return c


FIGURES = [("derived", chain), ("deep-state", proxy)]
