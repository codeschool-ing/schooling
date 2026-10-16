"""Lesson 20: memory and speed. The numbers are the two memory_usage outputs of the lesson."""
from draw import Fig

BEFORE = [("trip_id", 266696), ("started_at", 900099), ("ended_at", 901493),
          ("start_station", 366707), ("end_station", 370437), ("plan", 437021), ("bike", 511710)]
AFTER = dict([("trip_id", 133348), ("started_at", 266696), ("ended_at", 266696),
              ("start_station", 33560), ("end_station", 33560), ("plan", 33363), ("bike", 33369)])

memory = Fig(
    "memory", 720, 330,
    ("Memory per column, in kilobytes, before and after choosing types. The two time columns fall "
     "from about 900 to 266, the four text columns of codes and words from 366 to 512 down to about "
     "33 each as categories, and trip_id from 266 to 133 as int32.",
     "Memória por coluna, em kilobytes, antes e depois de escolher os tipos. As duas colunas de tempo "
     "caem de uns 900 para 266, as quatro colunas de texto de códigos e palavras de 366 a 512 para "
     "uns 33 cada como categorias, e trip_id de 266 para 133 como int32."),
    ("The same values in each row; only the types changed.",
     "Os mesmos valores em cada linha; só os tipos mudaram."))
f = memory
X, W, HI = 150, 520, 950000
f.text(X + W - 120, 22, "as read", "como lido", size=10, anchor="start")
f.rect(X + W - 140, 16, 12, 12, fill=None, stroke="paper-dim", rx=0, width=1)
f.text(X + W - 120, 42, "typed", "com tipos", size=10, anchor="start")
f.rect(X + W - 140, 36, 12, 12, fill="phosphor-dim", stroke="phosphor", rx=0, width=1)
for i, (col, before) in enumerate(BEFORE):
    y = 64 + i * 36
    f.text(X - 10, y + 12, col, mono=True, size=11, anchor="end")
    f.rect(X, y, before / HI * W, 12, fill=None, stroke="paper-dim", rx=0, width=1)
    f.text(X + before / HI * W + 6, y + 6, f"{before // 1000}", mono=True, size=9, fill="paper-dim",
           anchor="start")
    after = AFTER[col]
    f.rect(X, y + 14, after / HI * W, 12, fill="phosphor-dim", stroke="phosphor", rx=0, width=1)
    f.text(X + after / HI * W + 6, y + 20, f"{after // 1000}", mono=True, size=9, anchor="start")
f.line(X, 56, X, 318, stroke="paper-dim", width=1)
f.text(X + W / 2, 318, "kilobytes", "kilobytes", size=10, fill="paper-dim")

FIGURES = [memory]
