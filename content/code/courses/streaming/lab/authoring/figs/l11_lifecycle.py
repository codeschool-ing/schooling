# Lesson 11, allowed lateness: what happens to the 09:05 window as the watermark moves.
NAME = "l11-lifecycle"
W, H = 720, 200
LABEL = ("A timeline of the watermark, from 09:05 to 09:16. The 09:05 to 09:10 window is open until the watermark reaches 09:10, when its result is emitted. With five minutes of allowed lateness it is kept until the watermark reaches 09:15, and a late sale arriving in that stretch updates it. After 09:15 the window is forgotten and a sale for it is too late.",
         "Uma linha do tempo do watermark, de 09:05 a 09:16. A janela de 09:05 a 09:10 fica aberta até o watermark chegar a 09:10, quando o resultado é emitido. Com cinco minutos de atraso permitido, ela é mantida até o watermark chegar a 09:15, e uma venda atrasada que chegue nesse trecho a atualiza. Depois de 09:15 a janela é esquecida e uma venda para ela está atrasada demais.")
CAPTION = ("The bound decides when a window is first emitted; the lateness decides when it is forgotten. In between, a late event is an update.",
           "O limite decide quando uma janela é emitida pela primeira vez; o atraso permitido decide quando ela é esquecida. No meio, um evento atrasado é uma atualização.")
PT = {"watermark": "watermark", "open: sales are counted": "aberta: vendas são contadas",
      "emitted, still kept: a late sale updates it": "emitida, ainda mantida: uma venda atrasada a atualiza",
      "forgotten: too late": "esquecida: atrasada demais", "emit": "emitir", "forget": "esquecer",
      "window 09:05 to 09:10, lateness 5 minutes": "janela 09:05 a 09:10, atraso permitido de 5 minutos"}
SAME = ["watermark"]
def draw(s, t):
    def X(m): return 40 + (m - 5) * 50
    y = 110
    s.text(20, 30, t("window 09:05 to 09:10, lateness 5 minutes"), size=10.5, weight=600, anchor="start")
    s.rect(X(5), y - 18, X(10) - X(5), 36, fill="var(--panel)", stroke="var(--phosphor)")
    s.text((X(5) + X(10)) / 2, y, t("open: sales are counted"), size=10)
    s.rect(X(10), y - 18, X(15) - X(10), 36, fill="var(--panel)", stroke="var(--amber)")
    s.text((X(10) + X(15)) / 2, y, t("emitted, still kept: a late sale updates it"), size=9.5)
    s.rect(X(15), y - 18, X(17.6) - X(15), 36, fill="none", stroke="var(--wire)", dash="3 3")
    s.text((X(15) + X(17.6)) / 2, y, t("forgotten: too late"), size=9, fill="var(--paper-dim)")
    s.line(X(5), y + 40, X(17.6), y + 40, stroke="var(--wire)", arrow=True)
    for m in range(5, 17):
        s.line(X(m), y + 37, X(m), y + 43, stroke="var(--wire)")
        s.text(X(m), y + 56, f"09:{m:02d}", size=9, mono=True, fill="var(--paper-dim)")
    s.text(X(17.6), y + 56, t("watermark"), size=9.5, fill="var(--amber)", anchor="end")
    for m, word in ((10, "emit"), (15, "forget")):
        s.line(X(m), y - 28, X(m), y - 18, stroke="var(--amber)", sw=1)
        s.text(X(m), y - 34, t(word), size=9.5, fill="var(--amber)")
