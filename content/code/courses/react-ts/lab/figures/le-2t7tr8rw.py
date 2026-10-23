from fig import Fig

sl = Fig("slots", 720, 260,
         {"en": "Two columns of numbered slots. On the left, App's first render while loading: slots 1 to 5 hold useState "
                "for monday, courses, sessions, status and openId, and slot 6 the fetch effect, then return. On the right, "
                "the next render once ready: the same six, then slot 7 the title effect and slot 8 the keyboard effect, "
                "which have no slot from before. React matches the calls to the slots by number only.",
          "pt": "Duas colunas de espaços numerados. À esquerda, a primeira renderização do App, carregando: os espaços 1 "
                "a 5 guardam o useState de monday, courses, sessions, status e openId, e o espaço 6 o efeito da busca, "
                "depois o return. À direita, a renderização seguinte, pronta: os mesmos seis, depois o espaço 7 o efeito "
                "do título e o 8 o do teclado, que não têm espaço anterior. O React casa as chamadas com os espaços só "
                "pelo número."},
         {"en": "React knows hooks by their position in the call order, and nothing else.",
          "pt": "O React conhece os hooks pela posição na ordem de chamada, e por nada mais."})
sl.text(170, 20, {"en": "render while loading", "pt": "renderização carregando"}, anchor="middle", tone="dim", size=10.5)
sl.text(550, 20, {"en": "render when ready", "pt": "renderização pronta"}, anchor="middle", tone="dim", size=10.5)
names = ["useState  monday", "useState  courses", "useState  sessions", "useState  status", "useState  openId",
         "useEffect fetch", "useEffect title", "useEffect keyboard"]
for i, n in enumerate(names):
    y = 32 + i * 26
    if i < 6:
        sl.text(30, y + 11, str(i + 1), mono=True, tone="dim", anchor="end")
        sl.box(40, y, 260, 22, n, mono=True, tone="wire", text_tone="paper", size=10)
        sl.line(300, y + 11, 394, y + 11, tone="wire", dashed=True)
    tone = "amber" if i >= 6 else "wire"
    sl.text(410, y + 11, str(i + 1), mono=True, tone=tone, anchor="end")
    sl.box(420, y, 260, 22, n, mono=True, tone=tone, text_tone="amber" if i >= 6 else "paper", size=10)
sl.box(40, 32 + 6 * 26, 260, 22, "return <p>Loading…</p>", mono=True, tone="phosphor", size=10)
sl.text(170, 32 + 8 * 26 + 14, {"en": "six slots kept", "pt": "seis espaços guardados"}, anchor="middle", tone="dim", size=10.5)
sl.text(550, 32 + 8 * 26 + 14, {"en": "eight asked for: an error", "pt": "oito pedidos: um erro"}, anchor="middle", tone="amber", size=10.5)

cl = Fig("closure", 720, 200,
         {"en": "Render 1 has monday 19 Oct and creates an interval that closes over it. Render 2 has monday 26 Oct. With "
                "an empty array the interval from render 1 keeps running and keeps printing 19 Oct. With monday in the "
                "array, render 2's effect clears the old interval and starts one that prints 26 Oct.",
          "pt": "A renderização 1 tem monday 19 Oct e cria um intervalo que a captura. A renderização 2 tem monday 26 Oct. "
                "Com array vazio, o intervalo da renderização 1 continua rodando e imprimindo 19 Oct. Com monday no "
                "array, o efeito da renderização 2 limpa o intervalo antigo e começa um que imprime 26 Oct."},
         {"en": "A callback sees the render that made it. Re-run the effect, and a new callback sees the new render.",
          "pt": "Um callback vê a renderização que o criou. Rode o efeito de novo, e um callback novo vê a renderização nova."})
cl.box(20, 30, 200, 44, ["render 1", "monday = 19 Oct"], mono=True, tone="wire", text_tone="paper", size=10)
cl.box(20, 120, 200, 44, ["render 2", "monday = 26 Oct"], mono=True, tone="wire", text_tone="paper", size=10)
cl.box(300, 30, 180, 44, ["interval A", "logs 19 Oct"], mono=True, tone="amber", size=10)
cl.arrow(222, 52, 298, 52, tone="amber")
cl.text(590, 52, {"en": "with []: A runs forever", "pt": "com []: A roda para sempre"}, anchor="middle", tone="amber", size=11)
cl.arrow(480, 52, 510, 52, tone="amber", dashed=True)
cl.box(300, 120, 180, 44, ["interval B", "logs 26 Oct"], mono=True, tone="phosphor", size=10)
cl.arrow(222, 142, 298, 142, tone="phosphor")
cl.text(590, 142, {"en": "with [monday]: A cleared, B runs", "pt": "com [monday]: A limpo, B roda"}, anchor="middle", tone="phosphor", size=11)

FIGS = [sl, cl]
