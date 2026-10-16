NAME = "l3-segments"
W, H = 720, 185
LABEL = ("The partition old-sales-0 as three segments in a row: the first, closed at one mebibyte, holds offsets 0 to 7080, the second, also closed at one mebibyte, 7081 to 14353, and the active segment from 14354 on, still being written. With retention.bytes set to one mebibyte, the first segment is deleted whole, and the log start offset moves from 0 to 7081. Size retention never deletes the active segment.",
         "A partição old-sales-0 como três segmentos em fila: o primeiro, fechado em um mebibyte, guarda os offsets 0 a 7080, o segundo, também fechado em um mebibyte, 7081 a 14353, e o segmento ativo a partir de 14354, ainda sendo escrito. Com retention.bytes em um mebibyte, o primeiro segmento é apagado inteiro, e o log start offset vai de 0 para 7081. A retenção por tamanho nunca apaga o segmento ativo.")
CAPTION = ("Retention removes the oldest closed segment whole; the earliest offset jumps to the next segment's base offset.",
           "A retenção remove inteiro o segmento fechado mais antigo; o offset mais antigo salta para o offset base do segmento seguinte.")
PT = {"offsets 0 to 7080": "offsets 0 a 7080", "offsets 7081 to 14353": "offsets 7081 a 14353",
      "from 14354": "a partir de 14354", "deleted whole": "apagado inteiro", "active, being written": "ativo, sendo escrito",
      "log start offset: 0 before, 7081 after": "log start offset: 0 antes, 7081 depois", "closed at 1 MiB": "fechado em 1 MiB", "still growing": "ainda crescendo"}
SAME = []
def draw(s, t):
    segs = [(30, "00000000000000000000.log", "offsets 0 to 7080", "closed at 1 MiB"),
            (260, "00000000000000007081.log", "offsets 7081 to 14353", "closed at 1 MiB"),
            (490, "00000000000000014354.log", "from 14354", "still growing")]
    for i, (x, f, r, size) in enumerate(segs):
        st = "var(--amber)" if i == 0 else ("var(--phosphor)" if i == 2 else "var(--phosphor-dim)")
        s.rect(x, 70, 200, 70, fill="var(--panel)", stroke=st, dash="4 3" if i == 0 else None)
        s.text(x + 100, 88, f, size=9, mono=True, fill="var(--paper-dim)")
        s.text(x + 100, 108, t(r), size=10, weight=600)
        s.text(x + 100, 126, t(size), size=9, fill="var(--paper-dim)")
    s.text(130, 160, t("deleted whole"), size=9.5, fill="var(--amber)")
    s.text(590, 160, t("active, being written"), size=9.5, fill="var(--phosphor)")
    s.line(262, 40, 262, 66, stroke="var(--paper)", arrow=True)
    s.text(262, 30, t("log start offset: 0 before, 7081 after"), size=9.5)
