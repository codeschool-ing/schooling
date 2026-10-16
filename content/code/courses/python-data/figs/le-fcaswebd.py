"""Lesson 16: rolling, shifting and windows."""
from draw import Fig

window = Fig(
    "window", 720, 250,
    ("Ten days in a row, 1 to 10 January. A trailing window of seven days covers 1 to 7 January and its "
     "mean is written on 7 January. A centred window covers the same seven days and its mean is "
     "written on 4 January, the middle, so three of its days lie after the day it is written on.",
     "Dez dias seguidos, de 1 a 10 de janeiro. Uma janela à direita de sete dias cobre de 1 a 7 de "
     "janeiro e a média dela é escrita em 7 de janeiro. Uma janela centrada cobre os mesmos sete dias e "
     "a média é escrita em 4 de janeiro, o meio, então três dos seus dias ficam depois do dia em que ela "
     "é escrita."),
    ("The same seven days, written on the last of them or on the middle one.",
     "Os mesmos sete dias, escritos no último deles ou no do meio."))
f = window
x0, w = 40, 64
for d in range(10):
    x = x0 + d * w
    f.box(x + 4, 100, w - 8, 40, f"{d + 1} Jan", f"{d + 1} jan", mono=True, size=11, weight=None,
          stroke="amber" if d < 7 else "wire")
# trailing
f.path(f"M{x0 + 4} 94 L{x0 + 4} 84 L{x0 + 7 * w - 4} 84 L{x0 + 7 * w - 4} 94", stroke="amber")
f.text(x0 + 3.5 * w, 72, "rolling(7)", mono=True, size=11)
f.line(x0 + 6.5 * w, 46, x0 + 6.5 * w, 96, arrow=True)
f.text(x0 + 6.5 * w, 34, "written on the 7th", "escrita no dia 7", size=10)
# centred
f.path(f"M{x0 + 4} 146 L{x0 + 4} 156 L{x0 + 7 * w - 4} 156 L{x0 + 7 * w - 4} 146", stroke="amber")
f.text(x0 + 5.3 * w, 172, "rolling(7, center=True)", mono=True, size=11, anchor="start")
f.line(x0 + 3.5 * w, 200, x0 + 3.5 * w, 144, arrow=True)
f.text(x0 + 3.5 * w, 214, "written on the 4th: the 5th, 6th and 7th are its future",
       "escrita no dia 4: os dias 5, 6 e 7 são o futuro dela", size=10)

FIGURES = [window]
