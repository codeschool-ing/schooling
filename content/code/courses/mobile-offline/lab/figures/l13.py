"""Lesson 13: two offline edits, and the program that keeps the last one."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent / "l13-lww.ts").read_text().rstrip("\n").split("\n")


def chunk(a, b):  # lines a..b of the file, 1-based and inclusive
    return "\n".join(SRC[a - 1:b])


T = {
    "en": dict(
        aria="A timeline of one Wednesday morning in three lanes: phone, server, tablet. At 10:05 the phone, offline on a train, changes session s3 to 30 minutes. At 10:20 the tablet, offline at home, ticks s3 done. At 10:40 the tablet reconnects and sends its copy to the server. At 11:00 the phone reconnects and sends its copy. Neither device saw the other's edit before sending its own.",
        phone="phone", server="server", tablet="tablet",
        e1=["minutes", "20 → 30"], e2=["done", "false → true"],
        s1="sends its copy", s2="sends its copy",
        off1="offline: on the train", off2="offline: Wi-Fi down",
        cap="Two edits fifteen minutes apart, and still concurrent: neither device had seen the other's change when it made its own.",
    ),
    "pt": dict(
        aria="Uma linha do tempo de uma manhã de quarta-feira em três faixas: celular, servidor, tablet. Às 10:05 o celular, offline num trem, muda a sessão s3 para 30 minutos. Às 10:20 o tablet, offline em casa, marca s3 como feita. Às 10:40 o tablet volta à rede e manda a cópia dele ao servidor. Às 11:00 o celular volta à rede e manda a sua. Nenhum aparelho viu a edição do outro antes de mandar a própria.",
        phone="celular", server="servidor", tablet="tablet",
        e1=["minutes", "20 → 30"], e2=["done", "false → true"],
        s1="manda a cópia", s2="manda a cópia",
        off1="offline: no trem", off2="offline: Wi-Fi caído",
        cap="Duas edições com quinze minutos de distância, e ainda assim concorrentes: nenhum aparelho tinha visto a mudança do outro quando fez a sua.",
    ),
}


def x(hhmm):
    h, m = map(int, hhmm.split(":"))
    return round(150 + (h * 60 + m - 600) * 7.5, 1)


def figures(lang):
    t = T[lang]
    f = Fig("l13-timeline", 720, 290, t["aria"])
    lanes = {"phone": 70, "server": 160, "tablet": 250}
    for k, y in lanes.items():
        f.text(20, y, t[k], anchor="start", bold=True, size=10.5, fill="phosphor" if k == "server" else "paper")
    # the server is always online; each device is offline until it syncs
    f.arrow([(110, 160), (700, 160)], color="wire", head=False, width=1.4)
    f.arrow([(110, 70), (x("11:00"), 70)], color="wire", head=False, dashed=True)
    f.arrow([(x("11:00"), 70), (700, 70)], color="wire", head=False, width=1.4)
    f.arrow([(110, 250), (x("10:40"), 250)], color="wire", head=False, dashed=True)
    f.arrow([(x("10:40"), 250), (700, 250)], color="wire", head=False, width=1.4)
    f.text(120, 52, t["off1"], anchor="start", size=9, italic=True, fill="paper-dim")
    f.text(120, 268, t["off2"], anchor="start", size=9, italic=True, fill="paper-dim")
    for tm in ("10:05", "10:20", "10:40", "11:00"):
        f.text(x(tm), 286, tm, mono=True, size=9, fill="paper-dim")
    # the two edits
    f.box(x("10:05") - 40, 82, 80, 32, t["e1"], stroke="amber", mono=True, size=9)
    f.arrow([(x("10:05"), 70), (x("10:05"), 82)], color="amber", head=False)
    f.box(x("10:20") - 48, 206, 96, 32, t["e2"], stroke="amber", mono=True, size=9)
    f.arrow([(x("10:20"), 238), (x("10:20"), 250)], color="amber", head=False)
    # the two syncs
    f.arrow([(x("10:40"), 250), (x("10:40"), 164)], color="phosphor")
    f.text(x("10:40") + 8, 200, t["s2"], anchor="start", size=9, fill="phosphor")
    f.arrow([(x("11:00"), 70), (x("11:00"), 156)], color="phosphor")
    f.text(x("11:00") + 8, 115, t["s1"], anchor="start", size=9, fill="phosphor")
    same = None if lang == "en" else ["tablet"]
    return {"l13-timeline": f.json(t["cap"], same=same)}


EXAMPLES = {"last-write-wins": [{
    "language": "typescript", "file": "lww.ts",
    "parts": [
        (chunk(1, 11),
         "A session, the fields an edit may change, and the arguments: which clock stamps a write, and how many minutes ahead a device's clock runs.",
         "Uma sessão, os campos que uma edição pode mudar e os argumentos: qual relógio carimba uma escrita, e quantos minutos o relógio de um aparelho está adiantado."),
        (chunk(12, 17),
         "A time of day as HH:MM, moved on by some minutes. Strings of this shape sort in time order, so `>` compares them.",
         "Uma hora do dia como HH:MM, adiantada alguns minutos. Strings nesse formato se ordenam no tempo, então o `>` as compara."),
        (chunk(18, 23),
         "The server's row, stamped 09:00, and a copy of it on each device, which is what both had before the morning began.",
         "A linha do servidor, carimbada 09:00, e uma cópia dela em cada aparelho, que é o que os dois tinham antes de a manhã começar."),
        (chunk(24, 31),
         "The morning, in the order it happened: two edits made offline, then each device's sync when it found a network.",
         "A manhã, na ordem em que aconteceu: duas edições feitas offline, depois a sincronização de cada aparelho quando achou rede."),
        (chunk(32, 43),
         "An edit changes the local copy and stamps it with the device's clock, skew included. The change is folded into a whole session here, and from this line on nothing records which field was touched.",
         "Uma edição muda a cópia local e a carimba com o relógio do aparelho, com o adiantamento. A mudança é dobrada numa sessão inteira aqui, e daqui em diante nada registra qual campo foi mexido."),
        (chunk(44, 52),
         "The rule itself. A sync keeps the copy if its stamp is newer than the server's, and drops it otherwise. With `server-clock`, the stamp is the time the write arrived.",
         "A regra em si. Uma sincronização mantém a cópia se o carimbo for mais novo que o do servidor, e a descarta se não for. Com `server-clock`, o carimbo é a hora em que a escrita chegou."),
        (chunk(53, 53), "What the server holds at the end.", "O que o servidor guarda no fim."),
    ],
}]}
