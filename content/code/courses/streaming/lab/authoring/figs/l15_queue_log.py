NAME = "l15-queue-log"
W, H = 720, 270
LABEL = ("The same six messages in a queue and in a log. Above, a queue: two workers take turns, each message goes to one of them, and a message is deleted the moment its worker acknowledges it, so only the two not yet handled remain. Below, a log: all six stay where they were written, and two readers each keep their own position, one at offset 2 and one at offset 5, and either can go back to offset 0.",
         "As mesmas seis mensagens numa fila e num log. Em cima, uma fila: dois workers se revezam, cada mensagem vai para um deles, e uma mensagem é apagada no momento em que o worker dela confirma, então só restam as duas ainda não tratadas. Embaixo, um log: as seis continuam onde foram gravadas, e dois leitores mantêm cada um a sua posição, um no offset 2 e outro no offset 5, e qualquer um pode voltar ao offset 0.")
CAPTION = ("A queue hands each message to one worker and forgets it once acknowledged; a log keeps every message and lets each reader keep its own place.",
           "Uma fila entrega cada mensagem a um worker e a esquece depois da confirmação; um log guarda toda mensagem e deixa cada leitor guardar o próprio lugar.")
PT = {
    "queue": "fila",
    "log": "log",
    "acknowledged, deleted": "confirmadas, apagadas",
    "waiting": "esperando",
    "worker A": "worker A",
    "worker B": "worker B",
    "reader: stock": "leitor: estoque",
    "reader: warehouse": "leitor: warehouse",
    "replay from 0": "reler do 0",
}
SAME = ["log", "worker A", "worker B"]


def draw(s, t):
    # queue
    y = 70
    s.text(20, y, t("queue"), size=11, weight=600, anchor="start")
    for i in range(6):
        x = 110 + i * 46
        gone = i < 4
        s.rect(x, y - 15, 38, 30, stroke="var(--wire)" if gone else "var(--phosphor)",
               fill="none" if gone else "var(--panel)", dash="3 3" if gone else None)
        s.text(x + 19, y, str(i), size=10, fill="var(--paper-dim)" if gone else "var(--paper)", mono=True)
    s.text(110 + 2 * 46 - 4, y + 30, t("acknowledged, deleted"), size=9, fill="var(--paper-dim)")
    s.text(110 + 4 * 46 + 42, y + 30, t("waiting"), size=9, fill="var(--phosphor)")
    s.rect(540, 30, 100, 26, stroke="var(--amber)")
    s.text(590, 43, t("worker A"), size=10)
    s.rect(540, 84, 100, 26, stroke="var(--amber)")
    s.text(590, 97, t("worker B"), size=10)
    s.path("M 386 64 L 536 45", arrow=True)
    s.path("M 386 76 L 536 95", arrow=True)
    # log
    y = 190
    s.text(20, y, t("log"), size=11, weight=600, anchor="start")
    for i in range(6):
        x = 110 + i * 46
        s.rect(x, y - 15, 38, 30, stroke="var(--phosphor)")
        s.text(x + 19, y, str(i), size=10, mono=True)
    # readers
    s.line(110 + 2 * 46 + 19, y - 22, 110 + 2 * 46 + 19, y - 42, stroke="var(--amber)", sw=1.6)
    s.text(110 + 2 * 46 + 19, y - 52, t("reader: stock"), size=9.5, fill="var(--amber)")
    s.line(110 + 5 * 46 + 19, y - 22, 110 + 5 * 46 + 19, y - 42, stroke="var(--amber)", sw=1.6)
    s.text(110 + 5 * 46 + 19, y - 52, t("reader: warehouse"), size=9.5, fill="var(--amber)")
    s.path(f"M {110 + 5 * 46 + 10} {y + 20} Q 300 {y + 62} {129} {y + 20}", stroke="var(--paper-dim)", arrow=True, dash="4 3")
    s.text(300, y + 56, t("replay from 0"), size=9.5, fill="var(--paper-dim)")
