"""Lesson 10 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-b06p99mb"

f = Fig("l10-day", 720, 250,
        "Two timelines, one above the other, covering the evening of 21 October to the morning of 22 October. The upper one is the São Paulo calendar, whose midnight falls three hours later than the lower one, the UTC calendar. A vertical line marks one instant, 23:30 in São Paulo, which is 02:30 in UTC: on the upper line it falls in the day 2026-10-21, on the lower line in 2026-10-22.",
        "Duas linhas do tempo, uma sobre a outra, da noite de 21 de outubro à manhã de 22 de outubro. A de cima é o calendário de São Paulo, cuja meia-noite cai três horas depois da de baixo, o calendário UTC. Uma linha vertical marca um instante, 23:30 em São Paulo, que é 02:30 em UTC: na linha de cima ele cai no dia 2026-10-21, na de baixo em 2026-10-22.")
# scale: x = 40 + hours*40, hours from 18:00 UTC-ish; use UTC hours 18..34 (= 18:00 21st .. 10:00 22nd)
def X(h): return 40 + (h - 18) * 40
# São Paulo row: midnight SP = 03:00 UTC on 22nd = 27
f.text(40, 30, "São Paulo calendar", "calendário de São Paulo", size=11, fill="paper-dim", anchor="start")
f.box(X(18), 42, X(27) - X(18), 40, stroke="phosphor")
f.text((X(18) + X(27)) / 2, 62, "2026-10-21", mono=True, size=12, fill="phosphor")
f.box(X(27), 42, X(34) - X(27), 40, stroke="wire")
f.text((X(27) + X(34)) / 2, 62, "2026-10-22", mono=True, size=12, fill="paper-dim")
f.text(X(27) + 6, 96, "midnight", "meia-noite", size=10, fill="paper-dim", anchor="start")
# UTC row: midnight UTC = 24
f.text(40, 132, "UTC calendar", "calendário UTC", size=11, fill="paper-dim", anchor="start")
f.box(X(18), 144, X(24) - X(18), 40, stroke="wire")
f.text((X(18) + X(24)) / 2, 164, "2026-10-21", mono=True, size=12, fill="paper-dim")
f.box(X(24), 144, X(34) - X(24), 40, stroke="amber")
f.text((X(24) + X(34)) / 2, 164, "2026-10-22", mono=True, size=12, fill="amber")
f.text(X(24), 198, "midnight", "meia-noite", size=10, fill="paper-dim")
# the instant: 23:30 SP = 26.5 UTC
x = X(26.5)
for y1, y2 in ((30, 40), (86, 140), (188, 206)):
    f.line(x, y1, x, y2, color="amber", arrow=False, sw=2)
f.text(x, 222, "the picked instant: 23:30 here, 02:30 UTC", "o instante escolhido: 23:30 aqui, 02:30 UTC", size=11, fill="amber")
f.write(lesson(L, "numbers-and-dates"),
        "One instant, two calendars. Read in the calendar the person was looking at, it is the day they picked; read in UTC, it is the next one.",
        "Um instante, dois calendários. Lido no calendário que a pessoa via, é o dia que ela escolheu; lido em UTC, é o seguinte.")
