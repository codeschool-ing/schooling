from fig import Fig

snap = Fig("snapshot", 720, 250,
           {"en": "Two rows, one click each. Top row, with values: the render has monday 19 Oct, the click handler "
                  "calls set 26 Oct twice, both computed from the snapshot, and the next render has 26 Oct. Bottom "
                  "row, with updater functions: the queue runs 19 to 26, then 26 to 2 Nov, and the next render has 2 Nov. "
                  "In both rows the handler's own monday stays 19 Oct.",
            "pt": "Duas linhas, um clique cada. Linha de cima, com valores: a renderização tem monday 19 Oct, o handler "
                  "chama set 26 Oct duas vezes, ambas calculadas do retrato, e a renderização seguinte tem 26 Oct. "
                  "Linha de baixo, com funções de atualização: a fila roda de 19 para 26, depois de 26 para 2 Nov, e a "
                  "renderização seguinte tem 2 Nov. Nas duas linhas o monday do próprio handler continua 19 Oct."},
           {"en": "A value asks twice for the same thing; a function is handed what the last one returned.",
            "pt": "Um valor pede duas vezes a mesma coisa; uma função recebe o que a anterior devolveu."})
for row, (label, calls, result, tone) in enumerate([
        ({"en": "setMonday(value)", "pt": "setMonday(valor)"},
         ["set 26 Oct", "set 26 Oct"], "26 Oct", "amber"),
        ({"en": "setMonday(function)", "pt": "setMonday(função)"},
         ["19 → 26 Oct", "26 Oct → 2 Nov"], "2 Nov", "phosphor")]):
    y = 40 + row * 110
    snap.text(20, y - 14, label, tone=tone, size=11)
    snap.box(20, y, 130, 56, ["render", "monday = 19 Oct"], mono=True, tone="wire", text_tone="paper", size=10)
    snap.arrow(152, y + 28, 188, y + 28)
    snap.box(190, y, 330, 56, (), tone=tone)
    snap.text(202, y + 16, {"en": "click handler, one event", "pt": "handler do clique, um evento"}, tone="dim", size=10)
    for i, c in enumerate(calls):
        snap.box(202 + i * 158, y + 26, 146, 22, c, mono=True, tone=tone, size=10)
    snap.arrow(522, y + 28, 558, y + 28)
    snap.box(560, y, 140, 56, ["next render", f"monday = {result}"], mono=True, tone=tone, size=10)
snap.text(360, 236, {"en": "the handler's own monday is 19 Oct in both rows", "pt": "o monday do próprio handler é 19 Oct nas duas linhas"},
          anchor="middle", tone="dim", size=10.5)

lift = Fig("lifted", 720, 260,
           {"en": "App holds three pieces of state: monday, sessions and openId. Values go down as props to WeekNav, "
                  "WeekSummary, CourseList and CourseScreen. Requests for change come back up as function calls: "
                  "onChange from WeekNav, onOpen from the course cards, onToggle and onBack from CourseScreen. The "
                  "totals in WeekSummary are computed from the props, not stored.",
            "pt": "O App guarda três pedaços de estado: monday, sessions e openId. Os valores descem como props para "
                  "WeekNav, WeekSummary, CourseList e CourseScreen. Os pedidos de mudança voltam como chamadas de "
                  "função: onChange do WeekNav, onOpen dos cartões, onToggle e onBack do CourseScreen. Os totais do "
                  "WeekSummary são calculados a partir das props, não guardados."},
           {"en": "Values go down as props; requests for change come up as calls.",
            "pt": "Valores descem como props; pedidos de mudança sobem como chamadas."})
lift.box(220, 14, 280, 64, ["App", "monday · sessions · openId"], mono=True, tone="phosphor")
kids = [(20, "WeekNav", "onChange"), (195, "WeekSummary", None), (370, "CourseList", "onOpen"), (545, "CourseScreen", "onToggle, onBack")]
for x, n, up in kids:
    lift.box(x, 170, 155, 30, n, mono=True, tone="wire", text_tone="paper")
    lift.arrow(x + 30, 80, x + 30, 168, tone="phosphor")
    if up:
        lift.arrow(x + 125, 168, x + 125, 80, tone="amber")
        lift.text(x + 119, 128, up, mono=True, tone="amber", size=9.5, anchor="end")
lift.text(272, 222, {"en": "computes the totals from its props", "pt": "calcula os totais a partir das props"},
          anchor="middle", tone="dim", size=10.5)
lift.text(20, 248, {"en": "down: values as props", "pt": "para baixo: valores como props"}, tone="phosphor", size=10.5)
lift.text(380, 248, {"en": "up: requests as calls", "pt": "para cima: pedidos como chamadas"}, tone="amber", size=10.5)

rep = Fig("replace", 720, 230,
          {"en": "On the left, changing in place: one array before and after, the same object, with s2's done flipped "
                 "inside it, and Object.is says unchanged. On the right, map: a new array, with a new object for s2 and "
                 "the same objects s1, s3, s4, s5 and s6 as before, and Object.is says changed.",
           "pt": "À esquerda, mudar no lugar: um array antes e depois, o mesmo objeto, com o done do s2 trocado lá "
                 "dentro, e o Object.is diz que não mudou. À direita, map: um array novo, com um objeto novo para o s2 "
                 "e os mesmos objetos s1, s3, s4, s5 e s6 de antes, e o Object.is diz que mudou."},
          {"en": "React compares identities. A new array with one new object is a change it can see.",
           "pt": "O React compara identidades. Um array novo com um objeto novo é uma mudança que ele enxerga."})
rep.text(170, 20, {"en": "in place", "pt": "no lugar"}, anchor="middle", tone="amber", size=11.5)
rep.box(40, 36, 260, 40, (), tone="amber")
for i in range(6):
    rep.box(48 + i * 42, 44, 36, 24, f"s{i + 1}", mono=True, tone="amber" if i == 1 else "wire", text_tone="paper", size=10)
rep.text(170, 100, {"en": "the same array, s2 changed inside", "pt": "o mesmo array, s2 mudado por dentro"}, anchor="middle", tone="dim", size=10.5)
rep.text(170, 130, "Object.is(old, new) → true", mono=True, tone="amber", anchor="middle")
rep.text(170, 156, {"en": "no render", "pt": "nenhuma renderização"}, anchor="middle", tone="amber", size=11)
rep.text(540, 20, {"en": "map: a new array", "pt": "map: um array novo"}, anchor="middle", tone="phosphor", size=11.5)
rep.box(400, 36, 280, 40, (), tone="wire")
rep.text(390, 56, {"en": "old", "pt": "antigo"}, anchor="end", tone="dim", size=10)
rep.box(400, 116, 280, 40, (), tone="phosphor")
rep.text(390, 136, {"en": "new", "pt": "novo"}, anchor="end", tone="dim", size=10)
for i in range(6):
    x = 408 + i * 45
    rep.box(x, 44, 38, 24, f"s{i + 1}", mono=True, tone="wire", text_tone="paper", size=10)
    if i == 1:
        rep.box(x, 124, 38, 24, "s2'", mono=True, tone="phosphor", size=10)
    else:
        rep.box(x, 124, 38, 24, f"s{i + 1}", mono=True, tone="wire", text_tone="paper", size=10)
        rep.line(x + 19, 68, x + 19, 124, tone="wire", dashed=True)
rep.text(540, 182, "Object.is(old, new) → false", mono=True, tone="phosphor", anchor="middle")
rep.text(540, 206, {"en": "dashed: the same object, reused", "pt": "tracejado: o mesmo objeto, reaproveitado"}, anchor="middle", tone="dim", size=10.5)

FIGS = [snap, lift, rep]
