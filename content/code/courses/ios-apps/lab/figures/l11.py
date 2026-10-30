"""Lesson 11 figures: the four timing curves and the spring, plotted from the same arithmetic as
Sources/Motion/Curve.swift (same control points, same bisection), so the drawing and the capture agree."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-stgrvqfy"


def bez(s, p1, p2):
    return 3 * (1 - s) ** 2 * s * p1 + 3 * (1 - s) * s * s * p2 + s ** 3


def progress(c, t):
    lo, hi = 0.0, 1.0
    for _ in range(50):
        mid = (lo + hi) / 2
        if bez(mid, c[0], c[2]) < t: lo = mid
        else: hi = mid
    return bez((lo + hi) / 2, c[1], c[3])


def spring(sec, response=0.55):
    w = 2 * math.pi / response
    return 1 - (1 + w * sec) * math.exp(-w * sec)


f = Fig("l11-curves", 720, 340,
        "A chart of progress against time, both from 0 to 1 over 0.6 seconds. Four timing curves end at 0.35 seconds, the default duration: linear is a straight line, ease-in starts flat and ends steep, ease-out starts steep and ends flat, ease-in-out is flat at both ends and crosses the middle at 0.175 seconds. A fifth line, the critically damped spring with a response of 0.55 seconds, rises fast and is still short of 1 at 0.35 seconds, reaching about 0.99 at 0.55.",
        "Um gráfico do progresso contra o tempo, ambos de 0 a 1 ao longo de 0,6 segundo. Quatro curvas de tempo terminam em 0,35 segundo, a duração padrão: linear é uma reta, ease-in começa plana e termina íngreme, ease-out começa íngreme e termina plana, ease-in-out é plana nas duas pontas e cruza o meio em 0,175 segundo. Uma quinta linha, a mola criticamente amortecida com resposta de 0,55 segundo, sobe rápido e ainda não chegou a 1 em 0,35 segundo, alcançando cerca de 0,99 em 0,55.")
x0, y0, W, H = 70, 290, 520, 250      # plot origin (bottom left), width for 0.6 s, height for progress 1
X = lambda sec: x0 + sec / 0.6 * W
Y = lambda p: y0 - p * H
f.line(x0, y0, x0 + W + 10, y0, color="paper-dim", arrow=False, sw=1)
f.line(x0, y0, x0, y0 - H - 10, color="paper-dim", arrow=False, sw=1)
for sec in (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6):
    f.text(X(sec), y0 + 16, f"{sec:.1f}", mono=True, size=10, fill="paper-dim")
f.text(X(0.3), y0 + 36, "seconds", "segundos", size=11, fill="paper-dim")
for p in (0, 0.5, 1):
    f.text(x0 - 10, Y(p), f"{p:g}", mono=True, size=10, fill="paper-dim", anchor="end")
f.text(x0 - 40, Y(0.5) - 30, "progress", "progresso", size=11, fill="paper-dim")
f.line(X(0.35), y0, X(0.35), Y(1) - 6, color="wire", dashed=True, arrow=False, sw=1)
f.text(X(0.35), Y(1) - 14, "0.35 s", mono=True, size=10, fill="paper-dim")
curves = [("linear", (0, 0, 1, 1), "paper-dim"), ("ease-in", (0.42, 0, 1, 1), "paper"),
          ("ease-out", (0, 0, 0.58, 1), "phosphor"), ("ease-in-out", (0.42, 0, 0.58, 1), "amber")]
for name, cv, col in curves:
    pts = [(X(i / 100 * 0.35), Y(progress(cv, i / 100))) for i in range(101)]
    f.path("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts), color=col, arrow=False, sw=2)
pts = [(X(i / 100 * 0.6), Y(spring(i / 100 * 0.6))) for i in range(101)]
f.path("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts), color="phosphor-dim", dashed=True, arrow=False, sw=2)
# legend
ly = 70
for name, cv, col in curves + [("spring, 0.55", None, "phosphor-dim")]:
    f.line(612, ly, 636, ly, color=col, arrow=False, sw=2, dashed=(cv is None))
    f.text(642, ly, name, "mola, 0.55" if cv is None else name, mono=(cv is not None), size=10, fill="paper", anchor="start")
    ly += 22
f.write(lesson(L, "curves"),
        "The same 0.35 seconds, four shapes. The spring has no duration, so it is still rising when the timing curves have finished.",
        "Os mesmos 0,35 segundo, quatro formas. A mola não tem duração, então ainda está subindo quando as curvas de tempo já terminaram.")
