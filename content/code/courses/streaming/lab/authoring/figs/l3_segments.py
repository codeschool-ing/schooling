NAME = "l3-segments"
W, H = 720, 230
LABEL = ("The partition old-sales-0 as three segments in a row: the first holds offsets 0 to 7512 in about one mebibyte, the second 7513 to 14964 in about one mebibyte, and the active segment from 14965 on, still being written. With retention.bytes set to one mebibyte, the first segment is deleted whole, and the log start offset moves from 0 to 7513. The active segment is never deleted.",
         "A partição old-sales-0 como três segmentos em fila: o primeiro guarda os offsets 0 a 7512 em cerca de um mebibyte, o segundo 7513 a 14964 em cerca de um mebibyte, e o segmento ativo a partir de 14965, ainda sendo escrito. Com retention.bytes em um mebibyte, o primeiro segmento é apagado inteiro, e o log start offset vai de 0 para 7513. O segmento ativo nunca é apagado.")
CAPTION = ("Retention removes the oldest closed segment whole; the earliest offset jumps to the next segment's base offset.",
           "A retenção remove inteiro o segmento fechado mais antigo; o offset mais antigo salta para o offset base do segmento seguinte.")
PT = {"offsets 0 to 7512": "offsets 0 a 7512", "offsets 7513 to 14964": "offsets 7513 a 14964",
      "from 14965": "a partir de 14965", "deleted whole": "apagado inteiro", "active, being written": "ativo, sendo escrito",
      "log start offset: 0 before, 7513 after": "log start offset: 0 antes, 7513 depois", "1.0 MB": "1,0 MB", "0.7 MB": "0,7 MB"}
SAME = []
def draw(s, t):
    segs = [(30, "00000000000000000000.log", "offsets 0 to 7512", "1.0 MB"),
            (260, "00000000000000007513.log", "offsets 7513 to 14964", "1.0 MB"),
            (490, "00000000000000014965.log", "from 14965", "0.7 MB")]
    for i, (x, f, r, size) in enumerate(segs):
        st = "var(--amber)" if i == 0 else ("var(--phosphor)" if i == 2 else "var(--phosphor-dim)")
        s.rect(x, 70, 200, 70, fill="var(--panel)", stroke=st, dash="4 3" if i == 0 else None)
        s.text(x + 100, 88, f, size=9, mono=True, fill="var(--paper-dim)")
        s.text(x + 100, 108, t(r), size=10, weight=600)
        s.text(x + 100, 126, t(size), size=9, fill="var(--paper-dim)")
    s.text(130, 160, t("deleted whole"), size=9.5, fill="var(--amber)")
    s.text(590, 160, t("active, being written"), size=9.5, fill="var(--phosphor)")
    s.line(262, 40, 262, 66, stroke="var(--paper)", arrow=True)
    s.text(262, 30, t("log start offset: 0 before, 7513 after"), size=9.5)
