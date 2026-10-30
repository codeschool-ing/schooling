"""Lesson 4: the window a phone keeps."""
from fig import Fig

T = {
    "en": dict(
        aria="A timeline of three years of sessions, from November 2023 to October 2026. The last twelve weeks before 21 October 2026, and everything after it, are the window the phone keeps: 1,772 of 20,000 sessions. Everything earlier that was sent to the server is pruned. One old session, edited offline and not yet sent, is kept outside the window.",
        pruned="older than the window, and sent: pruned", window="the window: kept",
        weeks="12 weeks back, and everything ahead", today="today",
        kept="edited offline, not sent: kept", count="1,772 of 20,000 sessions stay",
        cap="The device keeps the part of the history its screens reach, and the rows it has not sent yet, wherever they fall.",
    ),
    "pt": dict(
        aria="Uma linha do tempo com três anos de sessões, de novembro de 2023 a outubro de 2026. As últimas doze semanas antes de 21 de outubro de 2026, e tudo o que vem depois, são a janela que o celular guarda: 1.772 de 20.000 sessões. Tudo o que é anterior e já foi enviado ao servidor é apagado. Uma sessão antiga, editada offline e ainda não enviada, fica guardada fora da janela.",
        pruned="mais antigo que a janela, e enviado: apagado", window="a janela: guardada",
        weeks="12 semanas para trás, e tudo à frente", today="hoje",
        kept="editada offline, não enviada: guardada", count="ficam 1.772 de 20.000 sessões",
        cap="O aparelho guarda a parte do histórico que as telas alcançam, e as linhas que ainda não enviou, onde quer que caiam.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l04-window", 720, 200, t["aria"])
    x0, x1 = 30, 690
    def X(month):  # months since 2023-11
        return round(x0 + (x1 - x0) * month / 36, 1)
    wx = X(33.0)
    f.rect(x0, 70, wx - x0, 34, stroke="wire", fill="ink", dashed=True)
    f.rect(wx, 70, x1 - wx, 34, stroke="phosphor", fill="panel")
    f.text(round((x0 + wx) / 2, 1), 87, t["pruned"], size=10, fill="paper-dim", italic=True)
    f.text(x1, 38, t["window"], anchor="end", size=10, bold=True, fill="phosphor")
    f.text(x1, 56, t["weeks"], anchor="end", size=9, fill="paper-dim")
    tx = X(35.7)
    f.arrow([(tx, 150), (tx, 106)], color="paper")
    f.text(tx, 160, t["today"], anchor="end", size=9.5, fill="paper")
    for m, label in ((0, "2023-11"), (12, "2024-11"), (24, "2025-11")):
        f.text(X(m), 122, label, mono=True, size=9, fill="paper-dim")
    sx = X(8)
    f.rect(sx - 4, 79, 8, 16, stroke="amber", fill="amber")
    f.arrow([(sx, 150), (sx, 107)], color="amber")
    f.text(sx - 12, 160, t["kept"], anchor="start", size=9.5, fill="amber")
    f.text(x1, 188, t["count"], anchor="end", size=9.5, fill="paper", italic=True)
    return {"l04-window": f.json(t["cap"])}
