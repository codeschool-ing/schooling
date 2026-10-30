"""Lesson 7: online-first and offline-first."""
from fig import Fig

T = {
    "en": dict(
        aria="Two rows. Online-first: the screen asks the server through the network for every read and every write, and when the network is gone the screen has nothing to draw. Offline-first: the screen reads and writes the database on the device, and a separate sync step carries changes to the server later, when there is a network.",
        on="online-first", off="offline-first",
        screen="the screen", server="the server", net="every read and write", gone="no network: nothing to draw",
        db=["the database", "on the device"], rw="reads and writes, at once", sync="sync, later",
        cap="Online-first puts the server between the person and every screen. Offline-first puts the device's database there, and sends to the server as a separate step.",
    ),
    "pt": dict(
        aria="Duas linhas. Online-first: a tela pede ao servidor, pela rede, cada leitura e cada escrita, e quando a rede some a tela não tem o que desenhar. Offline-first: a tela lê e grava no banco do aparelho, e uma etapa separada de sincronização leva as mudanças ao servidor depois, quando houver rede.",
        on="online-first", off="offline-first",
        screen="a tela", server="o servidor", net="toda leitura e escrita", gone="sem rede: nada a desenhar",
        db=["o banco", "no aparelho"], rw="lê e grava, na hora", sync="sincroniza, depois",
        cap="O online-first põe o servidor entre a pessoa e cada tela. O offline-first põe ali o banco do aparelho, e envia ao servidor numa etapa separada.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l07-two-ways", 720, 250, t["aria"])
    f.text(20, 24, t["on"], anchor="start", bold=True, size=10.5, fill="amber")
    f.box(20, 40, 150, 44, [t["screen"]], stroke="wire")
    f.box(550, 40, 150, 44, [t["server"]], stroke="wire")
    f.arrow([(170, 62), (550, 62)], both=True, dashed=True)
    f.text(360, 52, t["net"], size=9.5, fill="paper-dim", italic=True)
    f.text(360, 76, t["gone"], size=9.5, fill="amber", italic=True)
    f.text(20, 128, t["off"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.box(20, 144, 150, 44, [t["screen"]], stroke="phosphor")
    f.box(270, 144, 150, 44, t["db"], stroke="phosphor")
    f.box(550, 144, 150, 44, [t["server"]], stroke="wire")
    f.arrow([(170, 166), (270, 166)], both=True)
    f.text(220, 206, t["rw"], size=9.5, fill="phosphor", italic=True)
    f.arrow([(420, 166), (550, 166)], dashed=True, both=True)
    f.text(485, 206, t["sync"], size=9.5, fill="paper-dim", italic=True)
    same = None if lang == "en" else ["online-first", "offline-first"]
    return {"l07-two-ways": f.json(t["cap"], same=same)}
