from fig import Canvas


def flows(T):
    c = Canvas(720, 270, T(
        "The planner page and its four child components. The page owns sessions, week and selected. WeekTotal receives "
        "minutes as a prop and sends nothing back. WeekNav receives week and calls onchange with the week it wants. "
        "AddSession calls onadd with a date and minutes, and the page decides what a session is. CourseList is bound to "
        "selected, so its assignment travels up into the page's variable.",
        "A página do planner e os seus quatro componentes filhos. A página é dona de sessions, week e selected. O "
        "WeekTotal recebe minutes como prop e não devolve nada. O WeekNav recebe week e chama onchange com a semana que "
        "quer. O AddSession chama onadd com uma data e minutos, e a página decide o que é uma sessão. O CourseList é "
        "ligado a selected, então a atribuição dele sobe até a variável da página."))
    c.rect(20, 20, 680, 70, fill="var(--ink)", stroke="var(--amber)")
    c.text(360, 40, "+page.svelte", mono=True, size=11, fill="var(--amber)")
    c.text(360, 64, T("owns: sessions, week, selected", "dona de: sessions, week, selected"), size=10)
    kids = [(20, "WeekTotal", "minutes", None, False), (195, "WeekNav", "week", "onchange(next)", False),
            (370, "AddSession", None, "onadd({ date, minutes })", False), (545, "CourseList", "bind:selected", None, True)]
    for x, name, down, up, bound in kids:
        c.rect(x, 190, 155, 50, fill="var(--panel)", stroke="var(--phosphor)" if bound else "var(--wire)")
        c.text(x + 77, 215, name, mono=True, size=10.5)
        cx = x + 77
        if bound:
            c.line(cx - 10, 92, cx - 10, 186, stroke="var(--phosphor)", arrow=True)
            c.line(cx + 10, 188, cx + 10, 94, stroke="var(--phosphor)", arrow=True)
            c.text(cx - 16, 140, down, mono=True, size=9.5, fill="var(--phosphor)", anchor="end")
            continue
        if down:
            c.line(cx - 12, 92, cx - 12, 186, stroke="var(--paper-dim)", arrow=True)
            c.text(cx - 18, 125, down, mono=True, size=9.5, anchor="end", fill="var(--paper-dim)")
        if up:
            c.line(cx + 12, 188, cx + 12, 94, stroke="var(--amber)", arrow=True)
            c.text(cx + 18, 160, up, mono=True, size=9, anchor="start", fill="var(--amber)")
    c.text(20, 262, T("grey: a prop, down", "cinza: uma prop, descendo"), size=10, anchor="start", fill="var(--paper-dim)")
    c.text(240, 262, T("amber: a callback, up", "âmbar: um callback, subindo"), size=10, anchor="start", fill="var(--amber)")
    c.text(470, 262, T("blue: a binding, both ways", "azul: um binding, nos dois sentidos"), size=10, anchor="start", fill="var(--phosphor)")
    c.caption = T("Data down, choices up, and one binding where the child's whole job is to edit a value.",
                  "Dados descem, escolhas sobem, e um binding onde o trabalho inteiro do filho é editar um valor.")
    return c


FIGURES = [("bindable", flows)]
