from fig import Fig

ch = Fig("custom-hook", 720, 270,
         {"en": "On the left, App's code calls useWeek, usePlanner and useState. On the right, the hooks React actually "
                "records for App, in order: useWeek's useState and two useEffects, then usePlanner's three useStates, "
                "its fetch useEffect and its useCallback, then App's own useState for openId. A custom hook's hooks are "
                "App's hooks, in the place it is called.",
          "pt": "À esquerda, o código do App chama useWeek, usePlanner e useState. À direita, os hooks que o React de "
                "fato registra para o App, em ordem: o useState e os dois useEffect do useWeek, depois os três useState "
                "do usePlanner, o useEffect da busca e o useCallback, depois o useState do próprio App para openId. Os "
                "hooks de um hook próprio são hooks do App, no lugar onde ele é chamado."},
         {"en": "A custom hook adds its hooks to the caller's list, where it is called.",
          "pt": "Um hook próprio acrescenta os hooks dele à lista de quem o chama, onde é chamado."})
ch.text(140, 20, {"en": "what App's code says", "pt": "o que o código do App diz"}, anchor="middle", tone="dim", size=10.5)
ch.text(520, 20, {"en": "what React records for App", "pt": "o que o React registra para o App"}, anchor="middle", tone="dim", size=10.5)
calls = [("useWeek()", 3, "phosphor"), ("usePlanner()", 5, "amber"), ("useState(null)", 1, "wire")]
slots = [("useState  monday", 0), ("useEffect title", 0), ("useEffect keyboard", 0),
         ("useState  courses", 1), ("useState  sessions", 1), ("useState  status", 1), ("useEffect fetch", 1),
         ("useCallback toggleDone", 1), ("useState  openId", 2)]
y = 34
for i, (name, n, tone) in enumerate(calls):
    h = n * 24 - 4
    ch.box(30, y, 220, h, name, mono=True, tone=tone, text_tone="paper" if tone == "wire" else tone)
    ch.arrow(252, y + h / 2, 368, y + h / 2, tone=tone if tone != "wire" else "wire")
    for j in range(n):
        idx = sum(c[1] for c in calls[:i]) + j
        sy = 34 + idx * 24
        ch.text(386, sy + 10, str(idx + 1), mono=True, tone="dim", anchor="end")
        ch.box(392, sy, 260, 20, slots[idx][0], mono=True, tone=tone, text_tone="paper", size=10)
    y += n * 24
ch.text(520, 34 + 9 * 24 + 12, {"en": "nine slots, in the order of the calls", "pt": "nove espaços, na ordem das chamadas"},
        anchor="middle", tone="dim", size=10.5)

FIGS = [ch]
