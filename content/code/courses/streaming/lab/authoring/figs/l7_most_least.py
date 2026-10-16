# Lesson 7: 50 sales in batches of ten, a crash after the 25th, and what each order does.
NAME = "l7-most-least"
W, H = 720, 250
LABEL = ("Two rows of fifty sales in five batches of ten. In both, the consumer crashes after writing sale 25. Above, at most once: the third batch was committed at offset 30 before it was processed, so the restart begins at 30 and sales 26 to 30 are never processed. Below, at least once: the last commit was at 20, after the second batch, so the restart begins at 20 and sales 21 to 25 are processed twice.",
         "Duas linhas de cinquenta vendas em cinco lotes de dez. Nas duas, o consumidor cai depois de escrever a venda 25. Em cima, no máximo uma vez: o terceiro lote foi confirmado no offset 30 antes de ser processado, então o reinício começa em 30 e as vendas 26 a 30 nunca são processadas. Embaixo, pelo menos uma vez: a última confirmação foi em 20, depois do segundo lote, então o reinício começa em 20 e as vendas 21 a 25 são processadas duas vezes.")
CAPTION = ("The same crash, after sale 25. Committing first loses the rest of the batch; committing after does part of it again.",
           "A mesma queda, depois da venda 25. Confirmar antes perde o resto do lote; confirmar depois refaz parte dele.")
PT = {"at most once": "no máximo uma vez", "at least once": "pelo menos uma vez", "crash": "queda",
      "committed 30, restart here": "confirmado 30, reinício aqui", "committed 20, restart here": "confirmado 20, reinício aqui",
      "26-30 never processed": "26-30 nunca processadas", "21-25 processed twice": "21-25 processadas duas vezes"}
def draw(s, t):
    x0, cell = 120, 11.6
    def X(i): return x0 + i * cell
    for row, (y, name) in enumerate(((60, "at most once"), (170, "at least once"))):
        s.text(10, y + 8, t(name), size=10.5, weight=600, anchor="start")
        for i in range(50):
            done = i < 25
            if row == 0: col = "var(--phosphor)" if (done or i >= 30) else "var(--panel)"
            else: col = "var(--phosphor)"
            stroke = "var(--amber)" if (row == 0 and 25 <= i < 30) or (row == 1 and 20 <= i < 25) else "var(--wire)"
            s.rect(round(X(i), 1), y, cell - 2, 16, fill=col, stroke=stroke, rx=1, sw=1)
            if row == 1 and 20 <= i < 25:
                s.rect(round(X(i), 1), y + 20, cell - 2, 16, fill="var(--phosphor)", stroke="var(--amber)", rx=1, sw=1)
        for b in range(1, 5):
            s.line(X(b * 10) - 1, y - 6, X(b * 10) - 1, y + 22, stroke="var(--wire)", sw=0.8)
        cx = X(25) - 1
        s.line(cx, y - 14, cx, y + 40, stroke="var(--amber)", sw=1.4, dash="3 2")
        s.text(cx, y - 20, t("crash"), size=9.5, fill="var(--amber)")
        if row == 0:
            s.text(X(30), y + 34, t("committed 30, restart here"), size=9.5, fill="var(--paper-dim)", anchor="start")
            s.text(X(19), y + 34, t("26-30 never processed"), size=9.5, fill="var(--amber)", anchor="start")
        else:
            s.text(X(30), y + 52, t("committed 20, restart here"), size=9.5, fill="var(--paper-dim)", anchor="start")
            s.text(X(0), y + 52, t("21-25 processed twice"), size=9.5, fill="var(--amber)", anchor="start")
