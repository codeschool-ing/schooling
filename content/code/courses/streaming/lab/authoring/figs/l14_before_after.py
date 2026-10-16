NAME = "l14-before-after"
W, H = 720, 210
LABEL = ("Offsets 40 to 43 of the topic pf.public.stock, as captured in this lesson. Offset 40, an update with the default replica identity: before is null, after has Recife's bk-02 at qty 2. Offset 41, a delete of Natal's bk-08: before has the key and a qty of 0 that is a placeholder, after is null. Offset 42, a tombstone: the same key and a null value. Offset 43, an update after REPLICA IDENTITY FULL: before has qty 2 and after qty 1.",
         "Os offsets 40 a 43 do tópico pf.public.stock, como capturados nesta lição. Offset 40, um update com a replica identity padrão: before é null, after tem o bk-02 do Recife com qty 2. Offset 41, um delete do bk-08 de Natal: before tem a chave e um qty 0 que é preenchimento, after é null. Offset 42, um tombstone: a mesma chave e um valor null. Offset 43, um update depois de REPLICA IDENTITY FULL: before tem qty 2 e after qty 1.")
CAPTION = ("What each event says about the row before the change depends on the table's replica identity, not on Debezium.",
           "O que cada evento diz sobre a linha antes da mudança depende da replica identity da tabela, não do Debezium.")
PT = {"offset": "offset", "update, DEFAULT": "update, DEFAULT", "delete, DEFAULT": "delete, DEFAULT",
      "tombstone": "tombstone", "update, FULL": "update, FULL", "placeholder, not the real 3": "preenchimento, não o 3 real",
      "the old row is unknown": "a linha antiga é desconhecida", "the whole old row": "a linha antiga inteira",
      "key only: for compaction": "só a chave: para a compactação"}
SAME = ["offset 40", "offset 41", "offset 42", "offset 43", "update, DEFAULT", "delete, DEFAULT", "tombstone", "update, FULL"]


def draw(s, t):
    cols = [
        ("40", "update, DEFAULT", "before: null", "after: qty 2", "the old row is unknown", "var(--paper-dim)"),
        ("41", "delete, DEFAULT", "before: qty 0", "after: null", "placeholder, not the real 3", "var(--amber)"),
        ("42", "tombstone", "key: natal, bk-08", "value: null", "key only: for compaction", "var(--paper-dim)"),
        ("43", "update, FULL", "before: qty 2", "after: qty 1", "the whole old row", "var(--phosphor)"),
    ]
    for i, (off, kind, l1, l2, note, c) in enumerate(cols):
        x = 20 + i * 172
        s.text(x + 78, 30, t("offset") + " " + off, size=10, weight=600)
        s.rect(x, 45, 156, 120, stroke=c)
        s.text(x + 78, 66, t(kind), size=10, weight=600)
        s.text(x + 78, 100, l1, size=9.5, mono=True)
        s.text(x + 78, 125, l2, size=9.5, mono=True)
        s.text(x + 78, 190, t(note), size=9.5, fill=c)
