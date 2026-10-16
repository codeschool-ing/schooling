NAME = "l16-lag"
W, H = 720, 230
LABEL = ("One partition drawn as a row of numbered messages. The producer appends on the right; the log-end offset is the next free slot. The consumer group's committed offset sits further left, at the first message not yet handled. The messages between the two are the lag.",
         "Uma partição desenhada como uma fileira de mensagens numeradas. O produtor acrescenta à direita; o log-end offset é a próxima posição livre. O offset confirmado do grupo de consumidores fica mais à esquerda, na primeira mensagem ainda não tratada. As mensagens entre os dois são o lag.")
CAPTION = ("Lag is counted between two positions in the same partition: where the group will read next, and where the producer will write next.",
           "O lag é contado entre duas posições na mesma partição: onde o grupo vai ler em seguida e onde o produtor vai escrever em seguida.")
PT = {"handled": "tratadas", "waiting: the lag": "esperando: o lag",
      "CURRENT-OFFSET": "CURRENT-OFFSET", "LOG-END-OFFSET": "LOG-END-OFFSET",
      "next to read": "próxima a ler", "next to write": "próxima a escrever",
      "producer appends": "o produtor acrescenta",
      "lag = 15 − 7 = 8": "lag = 15 − 7 = 8"}
SAME = []
def draw(s, t):
    x0, y, w, h = 40, 90, 38, 34
    for i in range(15):
        x = x0 + i * w
        handled = i < 7
        s.rect(x, y, w - 4, h, fill="var(--panel)" if handled else "var(--ink)",
               stroke="var(--wire)" if handled else "var(--amber)")
        s.text(x + (w - 4) / 2, y + h / 2, str(i), size=10, mono=True,
               fill="var(--paper-dim)" if handled else "var(--paper)")
    xe = x0 + 15 * w
    s.rect(xe, y, w - 4, h, fill="none", stroke="var(--phosphor)", dash="3 3")
    s.text(xe + (w - 4) / 2, y + h / 2, "15", size=10, mono=True, fill="var(--phosphor)")
    # brackets
    s.path(f"M {x0} {y-12} L {x0} {y-18} L {x0+7*w-4} {y-18} L {x0+7*w-4} {y-12}", stroke="var(--wire)")
    s.text(x0 + (7 * w - 4) / 2, y - 30, t("handled"), size=10, fill="var(--paper-dim)")
    s.path(f"M {x0+7*w} {y-12} L {x0+7*w} {y-18} L {x0+15*w-4} {y-18} L {x0+15*w-4} {y-12}", stroke="var(--amber)")
    s.text(x0 + 7 * w + (8 * w - 4) / 2, y - 30, t("waiting: the lag"), size=10, weight=600, fill="var(--amber)")
    # pointers below
    xc = x0 + 7 * w + (w - 4) / 2
    s.line(xc, y + h + 30, xc, y + h + 4, stroke="var(--paper)", arrow=True)
    s.text(xc, y + h + 42, t("CURRENT-OFFSET"), size=10, mono=True)
    s.text(xc, y + h + 57, t("next to read"), size=9.5, fill="var(--paper-dim)")
    xl = xe + (w - 4) / 2
    s.line(xl, y + h + 30, xl, y + h + 4, stroke="var(--phosphor)", arrow=True)
    s.text(xl - 20, y + h + 42, t("LOG-END-OFFSET"), size=10, mono=True, fill="var(--phosphor)")
    s.text(xl - 20, y + h + 57, t("next to write"), size=9.5, fill="var(--paper-dim)")
    s.text(360, 210, t("lag = 15 − 7 = 8"), size=11, weight=600, mono=True, fill="var(--amber)")
    s.path(f"M {xe+w+20} {y+h/2} L {xe+w} {y+h/2}", stroke="var(--phosphor)", arrow=True)
    s.text(xe + w + 8, y + h / 2 - 26, t("producer appends"), size=9.5, fill="var(--paper-dim)", anchor="end")
