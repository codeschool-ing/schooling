from fig import Canvas


def attach(T):
    c = Canvas(720, 240, T(
        "Two cases. Above: TickerUser's setup calls useTicker, which calls onMounted and onUnmounted while "
        "TickerUser is the component being set up, so both hooks are attached to TickerUser and run when it "
        "is mounted and removed. Below: a click handler calls useTicker after setup is over; no component is "
        "being set up, so the hooks attach to nothing, Vue warns, and the timer never starts.",
        "Dois casos. Em cima: o setup do TickerUser chama useTicker, que chama onMounted e onUnmounted enquanto "
        "o TickerUser é o componente sendo montado, então os dois hooks ficam presos ao TickerUser e rodam quando "
        "ele é montado e removido. Embaixo: um handler de clique chama useTicker depois que o setup acabou; "
        "nenhum componente está sendo montado, então os hooks não se prendem a nada, o Vue avisa, e o timer "
        "nunca começa."))
    c.rect(20, 20, 680, 90, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(30, 103, T("during setup: the hooks find their component", "durante o setup: os hooks acham o seu componente"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.rect(40, 46, 150, 44, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(115, 68, "TickerUser", mono=True, size=11, fill="var(--phosphor)")
    c.rect(250, 46, 150, 44, fill="var(--panel)", stroke="var(--wire)")
    c.text(325, 68, "useTicker()", mono=True, size=11)
    c.rect(460, 46, 220, 44, fill="var(--panel)", stroke="var(--wire)")
    c.text(570, 60, "onMounted", mono=True, size=10.5)
    c.text(570, 78, "onUnmounted", mono=True, size=10.5)
    c.line(192, 68, 248, 68, stroke="var(--wire)", arrow=True)
    c.line(402, 68, 458, 68, stroke="var(--wire)", arrow=True)
    c.path("M570,44 C560,26 140,26 120,44", stroke="var(--phosphor)")
    c.line(124, 40, 120, 45, stroke="var(--phosphor)", arrow=True)
    c.rect(20, 130, 680, 90, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(30, 213, T("from a click: nobody is being set up", "num clique: ninguém está sendo montado"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.rect(40, 160, 150, 44, fill="var(--ink)", stroke="var(--amber)")
    c.text(115, 182, "@click", mono=True, size=11, fill="var(--amber)")
    c.rect(250, 160, 150, 44, fill="var(--panel)", stroke="var(--wire)")
    c.text(325, 182, "useTicker()", mono=True, size=11)
    c.rect(460, 160, 220, 44, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    c.text(570, 174, "onMounted", mono=True, size=10.5, fill="var(--amber)")
    c.text(570, 192, T("[Vue warn]: no instance", "[Vue warn]: nenhuma instância"), size=10, fill="var(--amber)")
    c.line(192, 182, 248, 182, stroke="var(--wire)", arrow=True)
    c.line(402, 182, 458, 182, stroke="var(--wire)", arrow=True)
    c.caption = T("A composable's hooks belong to whichever component is being set up when it is called, and to "
                  "nothing if none is.",
                  "Os hooks de um composable pertencem ao componente que está sendo montado quando ele é chamado, "
                  "e a nada se nenhum estiver.")
    return c


def identity(T):
    c = Canvas(720, 250, T(
        "Two halves. On the left, React: state is found by position. On render 1 three hooks are called, the first "
        "inside an if, in positions 1, 2 and 3. On render 2 the condition has changed and the hook inside the if is "
        "not called, so the next hook takes position 1 and the one after takes position 2: each later hook reads the "
        "state of the one before it. On the right, Vue: setup runs once, the composable useWeek is called inside it, "
        "inside an if if need be, and the component holds the objects it returns, monday, a ref, and sunday, a "
        "computed. The state is the object itself, not its place in a list.",
        "Duas metades. À esquerda, o React: o estado é encontrado pela posição. Na renderização 1 três hooks são "
        "chamados, o primeiro dentro de um if, nas posições 1, 2 e 3. Na renderização 2 a condição mudou e o hook "
        "dentro do if não é chamado, então o hook seguinte fica com a posição 1 e o que vem depois dele com a "
        "posição 2: cada hook seguinte lê o estado do anterior. À direita, o Vue: o setup roda uma vez, o composable "
        "useWeek é chamado dentro dele, dentro de um if se for preciso, e o componente guarda os objetos que ele "
        "devolve, monday, um ref, e sunday, um computed. O estado é o próprio objeto, não o seu lugar numa lista."))
    c.text(180, 18, T("React: state by position", "React: estado pela posição"), size=11, weight="600",
           fill="var(--amber)")
    c.text(105, 44, T("render 1", "renderização 1"), size=10, fill="var(--paper-dim)")
    c.text(265, 44, T("render 2: the if is false", "renderização 2: o if é falso"), size=10, fill="var(--paper-dim)")
    first = [T("hook inside the if", "hook dentro do if"), T("next hook", "hook seguinte"), T("the one after", "o depois dele")]
    second = [T("next hook", "hook seguinte"), T("the one after", "o depois dele"), None]
    for i in range(3):
        y = 58 + i * 46
        c.text(22, y + 17, str(i + 1), mono=True, size=10.5, fill="var(--paper-dim)")
        c.rect(40, y, 130, 34, fill="var(--panel)", stroke="var(--wire)")
        c.text(105, y + 17, first[i], size=10)
        if second[i]:
            c.rect(200, y, 130, 34, fill="var(--ink)", stroke="var(--amber)")
            c.text(265, y + 17, second[i], size=10, fill="var(--amber)")
            c.line(172, y + 17, 196, y + 17, stroke="var(--amber)", dash="3 3", arrow=True)
        else:
            c.rect(200, y, 130, 34, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
    c.text(180, 212, T("each later hook reads the state of the one before it", "cada hook seguinte lê o estado do anterior"),
           size=10, fill="var(--amber)")
    c.line(360, 14, 360, 236, stroke="var(--scan)", dash="4 4")
    c.text(540, 18, T("Vue: state by the object", "Vue: estado pelo objeto"), size=11, weight="600",
           fill="var(--phosphor)")
    c.rect(390, 50, 140, 44, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(460, 64, "setup()", mono=True, size=10.5, fill="var(--phosphor)")
    c.text(460, 82, T("runs once", "roda uma vez"), size=9.5)
    c.line(460, 96, 460, 124, stroke="var(--phosphor)", arrow=True)
    c.rect(390, 126, 140, 44, fill="var(--panel)", stroke="var(--wire)")
    c.text(460, 140, "useWeek()", mono=True, size=10.5)
    c.text(460, 158, T("inside an if: allowed", "dentro de um if: pode"), size=9.5)
    for i, name in enumerate(["monday: ref", "sunday: computed"]):
        y = 70 + i * 60
        c.rect(565, y, 135, 34, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(632, y + 17, name, mono=True, size=10)
        c.line(532, 148, 561, y + 17, stroke="var(--phosphor)", arrow=True)
    c.text(540, 212, T("the component holds the same objects for its whole life", "o componente guarda os mesmos objetos a vida toda"),
           size=10, fill="var(--phosphor)")
    c.caption = T("React finds a hook's state by the order of the calls; Vue by the ref the composable made.",
                  "O React acha o estado de um hook pela ordem das chamadas; o Vue, pelo ref que o composable criou.")
    return c


FIGURES = [("lifecycle-inside", attach), ("versus-hooks", identity)]
