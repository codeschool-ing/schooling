from fig import Canvas


def edge(T):
    c = Canvas(720, 220, T(
        "Three boxes in a row: browsers on the left, the edge in the middle, server.ts on the right. A request the edge "
        "has a fresh copy of is answered by the edge, a HIT, and never reaches server.ts. A request it has no fresh copy "
        "of is passed on, a MISS, and the answer is kept if its headers allow a shared cache to keep it.",
        "Três caixas em linha: navegadores à esquerda, o edge no meio, o server.ts à direita. Uma requisição de que o "
        "edge tem uma cópia fresca é respondida pelo edge, um HIT, e nunca chega ao server.ts. Uma de que ele não tem "
        "cópia fresca é repassada, um MISS, e a resposta é guardada se os cabeçalhos deixarem um cache compartilhado "
        "guardá-la."))
    boxes = [(30, T("browsers", "navegadores"), "many visitors"), (290, "edge.ts · :8000", None), (550, "server.ts · :3000", None)]
    for x, label, _ in boxes:
        c.rect(x, 70, 140, 60, fill="var(--panel)", stroke="var(--wire)", sw=1.4)
        c.text(x + 70, 100, label, size=11, mono=x != 30)
    c.line(172, 88, 288, 88, stroke="var(--phosphor)", arrow=True)
    c.text(230, 78, T("request", "requisição"), size=10, fill="var(--paper-dim)")
    c.line(288, 112, 172, 112, stroke="var(--phosphor)", arrow=True)
    c.text(230, 128, "HIT · age", size=10, mono=True, fill="var(--phosphor)")
    c.line(432, 88, 548, 88, stroke="var(--amber)", arrow=True, dash="4 3")
    c.text(490, 78, "MISS", size=10, mono=True, fill="var(--amber)")
    c.line(548, 112, 432, 112, stroke="var(--amber)", arrow=True, dash="4 3")
    c.text(490, 128, T("answer + headers", "resposta + cabeçalhos"), size=10, fill="var(--amber)")
    c.text(360, 160, T("kept if s-maxage or max-age allows,", "guardada se o s-maxage ou o max-age deixar,"), size=10, fill="var(--paper-dim)")
    c.text(360, 176, T("never if private, no-store or no-cache", "nunca se private, no-store ou no-cache"), size=10, fill="var(--paper-dim)")
    c.caption = T("A HIT is a request the origin never hears of.",
                  "Um HIT é uma requisição de que a origem nunca fica sabendo.")
    return c


FIGURES = [
    ("a-cdn", edge),
]
