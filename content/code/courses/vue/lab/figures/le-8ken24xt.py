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


FIGURES = [("lifecycle-inside", attach)]
