NAME = "l2-log-readers"
W, H = 720, 230
LABEL = ("A log of eight records, offsets 0 to 7, drawn left to right. New records are appended at the right-hand end. Three readers point at different places: the warehouse at offset 0, the loyalty scheme at offset 3 and the stock system at offset 8, the next record that does not exist yet. Reading moves only the reader's own pointer.",
         "Um log de oito registros, offsets 0 a 7, desenhado da esquerda para a direita. Registros novos são anexados na ponta direita. Três leitores apontam para lugares diferentes: o warehouse no offset 0, o programa de fidelidade no offset 3 e o sistema de estoque no offset 8, o próximo registro, que ainda não existe. Ler move só o ponteiro do próprio leitor.")
CAPTION = ("One log, three readers, three places. The log does not know where any of them is.",
           "Um log, três leitores, três lugares. O log não sabe onde nenhum deles está.")
PT = {"offset": "offset", "the next append goes here": "o próximo append entra aqui",
      "warehouse": "warehouse", "loyalty": "fidelidade", "stock": "estoque",
      "reads once a night": "lê uma vez por noite", "an hour behind": "uma hora atrás",
      "has read everything": "já leu tudo", "oldest": "mais antigo", "newest": "mais novo"}
SAME = ["offset", "warehouse"]
def draw(s, t):
    x0, w, y = 60, 62, 70
    for i in range(8):
        x = x0 + i * w
        s.rect(x, y, w - 6, 40, fill="var(--panel)", stroke="var(--phosphor-dim)")
        s.text(x + (w - 6) / 2, y + 20, str(i), size=13, weight=600, fill="var(--phosphor)", mono=True)
    xn = x0 + 8 * w
    s.rect(xn, y, w - 6, 40, fill="none", stroke="var(--amber)", dash="4 3")
    s.text(xn + (w - 6) / 2, y + 20, "8", size=13, fill="var(--amber)", mono=True)
    s.text(xn + (w - 6) / 2 + 2, y - 26, t("the next append goes here"), size=9.5, fill="var(--amber)")
    s.line(xn + 28, y - 18, xn + 28, y - 4, stroke="var(--amber)", arrow=True)
    s.text(30, y + 20, t("offset"), size=9.5, fill="var(--paper-dim)")
    s.text(x0 + 28, y - 12, t("oldest"), size=9, fill="var(--paper-dim)")
    s.text(x0 + 7 * w + 28, y - 12, t("newest"), size=9, fill="var(--paper-dim)")
    for off, name, note in ((0, "warehouse", "reads once a night"), (3, "loyalty", "an hour behind"), (8, "stock", "has read everything")):
        cx = x0 + off * w + 28
        s.line(cx, 175, cx, 116, stroke="var(--paper)", arrow=True)
        s.text(cx, 186, t(name), size=10.5, weight=600)
        s.text(cx, 202, t(note), size=9, fill="var(--paper-dim)")
