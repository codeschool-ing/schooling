from fig import Canvas


def flow(T):
    c = Canvas(720, 230, T(
        "A loop of four boxes, the data flowing one way around it. A component's template reads signals. An event "
        "in the component calls a method of the store. The method replaces the store's private state. The "
        "computed signals that depend on the state follow, and the template reads them again.",
        "Um laço de quatro caixas, os dados correndo num sentido só. O template de um componente lê signals. Um "
        "evento no componente chama um método do store. O método troca o estado privado do store. Os signals "
        "computed que dependem do estado acompanham, e o template os lê de novo."))
    boxes = [
        (40, 40, T("component", "componente"), T("template reads signals", "o template lê signals"), "var(--phosphor)"),
        (460, 40, T("method", "método"), "toggle(), add()", "var(--amber)"),
        (460, 150, T("state", "estado"), "private data", "var(--amber)"),
        (40, 150, "computed", "sessions(), weekTotals()", "var(--phosphor)"),
    ]
    for x, y, title, sub, col in boxes:
        c.rect(x, y, 220, 50, stroke=col)
        c.text(x + 110, y + 18, title, size=10.5, mono=(title == "computed"))
        c.text(x + 110, y + 35, sub, size=9.5, mono=sub.endswith(")") or sub.startswith("private"), fill="var(--paper-dim)")
    c.line(262, 65, 456, 65, arrow=True)
    c.text(360, 56, T("an event calls", "um evento chama"), size=9, fill="var(--paper-dim)")
    c.line(570, 92, 570, 146, arrow=True)
    c.text(578, 122, T("replaces", "troca"), size=9, anchor="start", fill="var(--paper-dim)")
    c.line(456, 175, 264, 175, arrow=True)
    c.text(360, 166, T("follow", "acompanham"), size=9, fill="var(--paper-dim)")
    c.line(150, 148, 150, 94, arrow=True)
    c.text(158, 122, T("read again", "lidos de novo"), size=9, anchor="start", fill="var(--paper-dim)")
    c.text(360, 218, T("nothing else writes the state", "nada mais escreve o estado"), size=9.5, fill="var(--amber)")
    c.caption = T("Data flows one way: events become method calls, methods replace the state, and what depends on it follows.",
                  "Os dados correm num sentido: eventos viram chamadas de método, métodos trocam o estado, e o que depende dele acompanha.")
    return c


FIGURES = [("the-pattern", flow)]
