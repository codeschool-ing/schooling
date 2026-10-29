from fig import Canvas


def lifecycle(T):
    c = Canvas(720, 250, T(
        "The life of a readable store with two subscribers, along a time line. When the first subscriber, a component, "
        "subscribes, the store calls its start function, which starts the interval. A second subscriber joins and shares the "
        "same interval. The first leaves and the interval keeps running for the second. When the last subscriber leaves, "
        "the store calls the function start returned, which clears the interval.",
        "A vida de um store readable com dois assinantes, numa linha do tempo. Quando o primeiro assinante, um componente, "
        "se inscreve, o store chama a sua função de início, que inicia o intervalo. Um segundo assinante entra e compartilha "
        "o mesmo intervalo. O primeiro sai e o intervalo continua para o segundo. Quando o último assinante sai, o store "
        "chama a função que o início devolveu, que limpa o intervalo."))
    c.line(40, 200, 690, 200, stroke="var(--paper-dim)", arrow=True)
    c.text(690, 216, T("time", "tempo"), size=10, anchor="end", fill="var(--paper-dim)")
    c.rect(120, 30, 300, 32, fill="var(--panel)", stroke="var(--wire)")
    c.text(270, 46, T("subscriber A", "assinante A"), size=10.5)
    c.rect(260, 76, 340, 32, fill="var(--panel)", stroke="var(--wire)")
    c.text(430, 92, T("subscriber B", "assinante B"), size=10.5)
    c.rect(120, 130, 480, 36, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 148, T("one setInterval, shared by both", "um setInterval, compartilhado pelos dois"), size=10.5, fill="var(--phosphor)")
    c.line(120, 200, 120, 168, stroke="var(--amber)", arrow=True)
    c.text(120, 230, T("first in: start()", "primeiro entra: start()"), size=10, fill="var(--amber)")
    c.line(600, 200, 600, 168, stroke="var(--amber)", arrow=True)
    c.text(600, 230, T("last out: what start() returned", "último sai: o que start() devolveu"), size=10, fill="var(--amber)")
    c.line(260, 196, 260, 204, stroke="var(--paper-dim)")
    c.line(420, 196, 420, 204, stroke="var(--paper-dim)")
    c.caption = T("A readable store runs its source only while somebody is subscribed, and only once however many are.",
                  "Um store readable roda a sua fonte só enquanto alguém está inscrito, e uma vez só, seja quantos forem.")
    return c


FIGURES = [("writable-readable-derived", lifecycle)]
