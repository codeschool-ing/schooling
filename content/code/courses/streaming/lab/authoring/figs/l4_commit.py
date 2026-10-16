NAME = "l4-commit"
W, H = 720, 210
LABEL = ("One partition's messages at offsets 0 to 9, read by a consumer that has processed offsets 0 to 6. The last commit says offset 4. A crash now means a restart reads from 4, so offsets 4, 5 and 6 are processed twice. With a commit after every message, the commit would say 7, the next offset to read, and nothing would be repeated.",
         "As mensagens de uma partição nos offsets 0 a 9, lidas por um consumidor que processou os offsets 0 a 6. O último commit diz offset 4. Uma queda agora significa que o reinício lê a partir do 4, então os offsets 4, 5 e 6 são processados duas vezes. Com um commit depois de cada mensagem, o commit diria 7, o próximo offset a ler, e nada se repetiria.")
CAPTION = ("Whatever lies between the last commit and the crash is read again.",
           "O que fica entre o último commit e a queda é lido de novo.")
PT = {"last commit": "último commit", "processed so far": "processado até aqui", "crash": "queda",
      "read again after a restart": "lido de novo depois de reiniciar"}
SAME = []
def draw(s, t):
    x0, w = 60, 60
    for i in range(10):
        done = i < 7
        s.rect(x0 + i * w, 80, w - 6, 34, fill="var(--panel)", stroke="var(--phosphor)" if done else "var(--wire)")
        s.text(x0 + i * w + (w - 6) / 2, 97, str(i), size=11, mono=True, fill="var(--phosphor)" if done else "var(--paper-dim)")
    s.line(x0 + 4 * w - 3, 40, x0 + 4 * w - 3, 76, stroke="var(--paper)", arrow=True)
    s.text(x0 + 4 * w - 3, 32, t("last commit"), size=9.5)
    s.line(x0 + 7 * w - 3, 40, x0 + 7 * w - 3, 76, stroke="var(--amber)", arrow=True)
    s.text(x0 + 7 * w - 3, 32, t("crash"), size=9.5, fill="var(--amber)")
    s.path(f"M {x0} 128 L {x0} 136 L {x0 + 7 * w - 6} 136 L {x0 + 7 * w - 6} 128", stroke="var(--phosphor-dim)")
    s.text(x0 + 3.5 * w, 150, t("processed so far"), size=9.5, fill="var(--phosphor)")
    s.path(f"M {x0 + 4 * w} 165 L {x0 + 4 * w} 173 L {x0 + 7 * w - 6} 173 L {x0 + 7 * w - 6} 165", stroke="var(--amber)")
    s.text(x0 + 5.5 * w, 188, t("read again after a restart"), size=9.5, fill="var(--amber)")
