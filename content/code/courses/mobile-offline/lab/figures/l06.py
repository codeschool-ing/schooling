"""Lesson 6: frames, and the thread that waits for the query."""
from fig import Fig

T = {
    "en": dict(
        aria="Two timelines of frames due every 16 milliseconds. Above, the query runs on the main thread: while it runs, every frame that falls due is dropped, and drawing resumes only when it returns. Below, the query runs on a worker thread: the main thread draws every frame while the worker answers, and the answer arrives as a message.",
        a="the query on the main thread", b="the query on a worker",
        main="main thread", worker="worker", q="slow query",
        dropped="frames dropped", drawn="every frame drawn", msg="the answer, as a message",
        cap="The query takes as long in both. What changes is which thread waits for it, and so whether the frames due in the meantime are drawn.",
    ),
    "pt": dict(
        aria="Duas linhas do tempo de quadros que vencem a cada 16 milissegundos. Em cima, a consulta roda na thread principal: enquanto ela roda, todo quadro que vence é descartado, e o desenho só volta quando ela retorna. Embaixo, a consulta roda numa thread worker: a thread principal desenha todos os quadros enquanto o worker responde, e a resposta chega como mensagem.",
        a="a consulta na thread principal", b="a consulta num worker",
        main="thread principal", worker="worker", q="consulta lenta",
        dropped="quadros descartados", drawn="todo quadro desenhado", msg="a resposta, como mensagem",
        cap="A consulta demora o mesmo nos dois. O que muda é qual thread espera por ela, e portanto se os quadros que vencem nesse meio-tempo são desenhados.",
    ),
}


def frames(f, y, skip=None):
    for i in range(24):
        x = 140 + i * 24
        lost = skip and skip[0] <= i < skip[1]
        f.rect(x, y, 16, 22, stroke="amber" if lost else "phosphor", fill="ink" if lost else "panel",
               dashed=bool(lost), rx=2)


def figures(lang):
    t = T[lang]
    f = Fig("l06-frames", 720, 290, t["aria"])
    f.text(20, 20, t["a"], anchor="start", bold=True, size=10.5, fill="amber")
    f.text(20, 54, t["main"], anchor="start", size=9.5, fill="paper-dim")
    frames(f, 43, skip=(5, 16))
    f.box(260, 74, 264, 24, [t["q"]], stroke="amber", size=9.5)
    f.text(392, 112, t["dropped"], size=9.5, fill="amber", italic=True)
    f.text(20, 150, t["b"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.text(20, 184, t["main"], anchor="start", size=9.5, fill="paper-dim")
    frames(f, 173)
    f.text(20, 228, t["worker"], anchor="start", size=9.5, fill="paper-dim")
    f.box(260, 216, 264, 24, [t["q"]], stroke="wire", size=9.5)
    f.arrow([(524, 216), (536, 198)], color="phosphor")
    f.text(540, 258, t["msg"], anchor="start", size=9.5, fill="phosphor", italic=True)
    f.text(392, 272, t["drawn"], size=9.5, fill="phosphor", italic=True)
    same = None if lang == "en" else ["worker"]
    return {"l06-frames": f.json(t["cap"], same=same)}
