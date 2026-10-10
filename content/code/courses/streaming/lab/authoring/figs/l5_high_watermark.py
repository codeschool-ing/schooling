NAME = "l5-high-watermark"
W, H = 720, 270
LABEL = ("One partition with three replicas. The leader on node 1 holds offsets 0 to 9; the follower on node 2 has copied up to offset 8 and the follower on node 3 up to offset 6. The high watermark sits at 7, the first offset not yet on every in-sync replica, so a consumer reads offsets 0 to 6 and the leader's offsets 7 to 9 are written but not yet committed.",
         "Uma partição com três réplicas. O líder no nó 1 tem os offsets 0 a 9; o seguidor no nó 2 copiou até o offset 8 e o seguidor no nó 3 até o offset 6. O high watermark fica em 7, o primeiro offset que ainda não está em toda réplica em sincronia, então um consumidor lê os offsets 0 a 6 e os offsets 7 a 9 do líder estão gravados mas ainda não confirmados.")
CAPTION = ("The leader has written ten records, but a consumer is given seven: only what every in-sync replica already holds.",
           "O líder gravou dez registros, mas um consumidor recebe sete: só o que toda réplica em sincronia já tem.")
PT = {"node 1 · leader": "nó 1 · líder", "node 2 · follower": "nó 2 · seguidor", "node 3 · follower": "nó 3 · seguidor",
      "log end 10": "fim do log 10", "log end 9": "fim do log 9", "log end 7": "fim do log 7",
      "high watermark = 7": "high watermark = 7",
      "a consumer reads 0 to 6": "um consumidor lê de 0 a 6",
      "written, not yet committed": "gravado, ainda não confirmado",
      "producer": "produtor", "fetch": "fetch"}
SAME = ["high watermark = 7", "fetch"]
def draw(s, t):
    x0, cw, y0, rh = 150, 38, 50, 52
    rows = [("node 1 · leader", 10), ("node 2 · follower", 9), ("node 3 · follower", 7)]
    hw = 7
    for r, (name, n) in enumerate(rows):
        y = y0 + r * rh
        s.text(18, y + 15, t(name), size=10.5, weight=600 if r == 0 else None, anchor="start")
        for i in range(n):
            x = x0 + i * cw
            committed = i < hw
            s.rect(x, y, cw - 4, 30, fill="var(--panel)", stroke="var(--phosphor)" if committed else "var(--amber)", dash=None if committed else "3 2")
            s.text(x + (cw - 4) / 2, y + 15, str(i), size=10, mono=True, fill="var(--paper)" if committed else "var(--amber)")
        s.text(x0 + 10 * cw + 12, y + 15, t(f"log end {n}"), size=9.5, fill="var(--paper-dim)", anchor="start")
    xh = x0 + hw * cw - 2
    s.line(xh, y0 - 22, xh, y0 + 3 * rh - 8, stroke="var(--phosphor)", sw=1.5, dash="5 3")
    s.text(xh, y0 - 30, t("high watermark = 7"), size=10, fill="var(--phosphor)", weight=600)
    s.text((x0 + xh) / 2, y0 + 3 * rh + 8, t("a consumer reads 0 to 6"), size=10, fill="var(--phosphor)")
    s.text(xh + 3 * cw / 2, y0 + 3 * rh + 8, t("written, not yet committed"), size=9.5, fill="var(--amber)")
    s.line(xh + 2, y0 + 3 * rh + 22, xh + 3 * cw, y0 + 3 * rh + 22, stroke="var(--amber)", sw=1)
    s.line(x0, y0 + 3 * rh + 22, xh - 4, y0 + 3 * rh + 22, stroke="var(--phosphor)", sw=1)
