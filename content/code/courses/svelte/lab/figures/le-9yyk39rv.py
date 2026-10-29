from fig import Canvas


def shared(T):
    c = Canvas(720, 270, T(
        "One server process answering two visitors. On the left, with a module: both requests import the same module, "
        "which holds one visitor object; Ana's request sets its name, and the stranger's request, a moment later, reads "
        "the same object and is greeted as Ana. On the right, with context: each request creates its own page component, "
        "and each component sets its own visitor in context, so each greeting reads its own.",
        "Um processo de servidor atendendo dois visitantes. À esquerda, com um módulo: as duas requisições importam o mesmo "
        "módulo, que guarda um único objeto visitor; a requisição da Ana define o nome, e a do desconhecido, um instante "
        "depois, lê o mesmo objeto e é cumprimentada como Ana. À direita, com contexto: cada requisição cria o seu próprio "
        "componente de página, e cada componente põe o seu próprio visitor no contexto, então cada saudação lê o seu."))
    for col, (title, keyed) in enumerate([(T("a module: one for every request", "um módulo: um para todas as requisições"), False),
                                          (T("context: one per request", "contexto: um por requisição"), True)]):
        x0 = 20 + col * 360
        c.text(x0 + 160, 20, title, size=11, weight="600", fill="var(--amber)" if not keyed else "var(--phosphor)")
        c.rect(x0, 40, 150, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(x0 + 75, 60, "?name=Ana", mono=True, size=10)
        c.rect(x0 + 170, 40, 150, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(x0 + 245, 60, T("no name", "sem nome"), size=10.5)
        if not keyed:
            c.rect(x0 + 60, 130, 200, 50, fill="var(--ink)", stroke="var(--amber)")
            c.text(x0 + 160, 148, "visitor.svelte.js", mono=True, size=10, fill="var(--amber)")
            c.text(x0 + 160, 166, "{ name: 'Ana' }", mono=True, size=10, fill="var(--amber)")
            c.line(x0 + 75, 80, x0 + 130, 128, stroke="var(--paper-dim)", arrow=True)
            c.line(x0 + 245, 80, x0 + 190, 128, stroke="var(--paper-dim)", arrow=True)
            c.text(x0 + 75, 220, "Hello, Ana.", mono=True, size=10.5)
            c.text(x0 + 245, 220, "Hello, Ana.", mono=True, size=10.5, fill="var(--amber)")
        else:
            for k, (nm, out) in enumerate([("{ name: 'Ana' }", "Hello, Ana."), ("{ name: null }", "Hello, stranger.")]):
                x = x0 + k * 170
                c.rect(x, 130, 150, 50, fill="var(--ink)", stroke="var(--phosphor)")
                c.text(x + 75, 148, T("its own context", "o seu contexto"), size=9.5, fill="var(--phosphor)")
                c.text(x + 75, 166, nm, mono=True, size=10, fill="var(--phosphor)")
                c.line(x + 75, 80, x + 75, 128, stroke="var(--paper-dim)", arrow=True)
                c.text(x + 75, 220, out, mono=True, size=10.5)
    c.text(360, 256, T("the same code, the same server: only where the value lives differs",
                       "o mesmo código, o mesmo servidor: só muda onde o valor mora"), size=10, fill="var(--paper-dim)")
    c.caption = T("A module-level value is shared by every request the server answers. A context belongs to one.",
                  "Um valor no nível do módulo é compartilhado por toda requisição que o servidor atende. Um contexto pertence a uma.")
    return c


FIGURES = [("server-state", shared)]
