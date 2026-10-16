NAME = "l3-compaction"
W, H = 720, 240
LABEL = ("The stock topic before and after compaction. Before: eight messages at offsets 0 to 7, bk-01 = 4, bk-02 = 7, bk-03 = 2, bk-01 = 3, bk-02 = 6, bk-01 = 2, a tombstone for bk-03, and bk-04 = 9 in the active segment. After: only offsets 4, 5, 6 and 7 remain, the last value of each key and the tombstone, keeping their original offsets, so offsets 0 to 3 are a hole.",
         "O tópico stock antes e depois da compactação. Antes: oito mensagens nos offsets 0 a 7, bk-01 = 4, bk-02 = 7, bk-03 = 2, bk-01 = 3, bk-02 = 6, bk-01 = 2, um tombstone para bk-03, e bk-04 = 9 no segmento ativo. Depois: só restam os offsets 4, 5, 6 e 7, o último valor de cada chave e o tombstone, com os offsets originais, então os offsets 0 a 3 viram um buraco.")
CAPTION = ("Compaction keeps the last message for each key, at the offset it was written; the active segment is left alone.",
           "A compactação guarda a última mensagem de cada chave, no offset em que foi escrita; o segmento ativo fica intocado.")
MSGS = [("bk-01", "4"), ("bk-02", "7"), ("bk-03", "2"), ("bk-01", "3"), ("bk-02", "6"), ("bk-01", "2"), ("bk-03", "null"), ("bk-04", "9")]
KEEP = {4, 5, 6, 7}
PT = {"before": "antes", "after": "depois", "closed segment": "segmento fechado", "active segment": "segmento ativo",
      "tombstone": "tombstone", "offset": "offset"}
SAME = ["tombstone", "offset"]
def cell(s, x, y, i, k, v, dim=False):
    col = "var(--amber)" if v == "null" else "var(--phosphor)"
    s.rect(x, y, 70, 46, fill="var(--panel)" if not dim else "none", stroke=col if not dim else "var(--wire)", dash="3 3" if dim else None)
    s.text(x + 35, y + 14, str(i), size=9, fill="var(--paper-dim)", mono=True)
    if not dim:
        s.text(x + 35, y + 32, f"{k}={v}", size=9.5, fill=col, mono=True)
def draw(s, t):
    x0 = 90
    s.text(20, 63, t("before"), size=11, weight=600, anchor="start")
    s.text(20, 168, t("after"), size=11, weight=600, anchor="start")
    s.text(56, 26, t("offset"), size=9, fill="var(--paper-dim)")
    for i, (k, v) in enumerate(MSGS):
        cell(s, x0 + i * 78, 40, i, k, v)
        cell(s, x0 + i * 78, 145, i, k, v, dim=i not in KEEP)
    s.line(x0 + 7 * 78 - 4, 30, x0 + 7 * 78 - 4, 205, stroke="var(--wire)", dash="2 3")
    s.text(x0 + 3.5 * 78 - 4, 112, t("closed segment"), size=9, fill="var(--paper-dim)")
    s.text(x0 + 7 * 78 + 35, 112, t("active segment"), size=9, fill="var(--paper-dim)")
    s.text(x0 + 6 * 78 + 35, 210, t("tombstone"), size=9, fill="var(--amber)")
