"""Lesson 10: a retry with an idempotency key, in time."""
from fig import Fig

T = {
    "en": dict(
        aria="A sequence in time between the phone and the server. The phone makes key K when the person taps Buy and sends POST /purchases with key K. The server charges the card, saves p1 as the answer for K, and its 201 is lost on the way back. The phone sees no answer and retries with the same key K. The server finds K, sends the saved p1 again marked as replayed, and charges nothing.",
        phone="the phone", server="the server",
        tap="taps Buy: key K is made", s1="POST /purchases, key K", charge=["charges the card", "saves p1 under K"],
        lost="201 lost on the way", retry="no answer: same key K again", found=["finds K: sends p1 again", "charges nothing"],
        back="201, replayed: p1",
        cap="The key is made before the first try and sent with every retry, so the server can tell a retry from a second purchase.",
    ),
    "pt": dict(
        aria="Uma sequência no tempo entre o celular e o servidor. O celular cria a chave K quando a pessoa toca em Comprar e envia POST /purchases com a chave K. O servidor cobra o cartão, guarda p1 como a resposta de K, e o 201 dele se perde na volta. O celular não vê resposta e tenta de novo com a mesma chave K. O servidor encontra K, manda de novo o p1 guardado marcado como repetido, e não cobra nada.",
        phone="o celular", server="o servidor",
        tap="toca em Comprar: a chave K nasce", s1="POST /purchases, chave K", charge=["cobra o cartão", "guarda p1 sob K"],
        lost="201 perdido no caminho", retry="sem resposta: mesma chave K de novo", found=["acha K: manda p1 de novo", "não cobra nada"],
        back="201, repetido: p1",
        cap="A chave nasce antes da primeira tentativa e vai em toda nova tentativa, então o servidor distingue uma nova tentativa de uma segunda compra.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l10-key", 720, 300, t["aria"])
    px, sx = 140, 560
    f.box(px - 70, 14, 140, 30, [t["phone"]], stroke="phosphor")
    f.box(sx - 70, 14, 140, 30, [t["server"]], stroke="wire")
    f.arrow([(px, 44), (px, 290)], head=False, color="scan", dashed=True)
    f.arrow([(sx, 44), (sx, 290)], head=False, color="scan", dashed=True)
    f.text(px + 10, 62, t["tap"], anchor="start", size=9.5, fill="phosphor", italic=True)
    f.arrow([(px, 76), (sx, 96)], color="phosphor")
    f.text(350, 74, t["s1"], size=9.5, fill="paper")
    f.box(sx + 8, 92, 150, 34, t["charge"], stroke="amber", size=9.5)
    f.arrow([(sx, 132), (350, 142)], color="amber", dashed=True)
    f.text(330, 148, "✕", size=13, fill="amber")
    f.text(350, 166, t["lost"], size=9.5, fill="amber", italic=True)
    f.text(px + 10, 184, t["retry"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.arrow([(px, 196), (sx, 214)], color="phosphor")
    f.box(sx + 8, 210, 150, 34, t["found"], stroke="phosphor", size=9.5)
    f.arrow([(sx, 256), (px, 276)], color="phosphor")
    f.text(350, 258, t["back"], size=9.5, fill="phosphor")
    return {"l10-key": f.json(t["cap"])}
