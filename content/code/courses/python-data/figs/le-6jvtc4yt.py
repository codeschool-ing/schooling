"""Lesson 8: random numbers and seeds."""
from draw import Fig

shared = Fig(
    "shared", 720, 230,
    ("Top: one global sequence from seed 42. Without the helper, your line takes the first five values. "
     "With the helper, the helper's shuffle takes the first values and your line gets the next five, "
     "different ones. Bottom: your own generator from seed 42 is a separate sequence the helper never "
     "touches, so your line always takes its first five.",
     "Em cima: uma sequência global da semente 42. Sem o auxiliar, a sua linha pega os cinco primeiros "
     "valores. Com o auxiliar, o embaralhamento dele pega os primeiros e a sua linha recebe os cinco "
     "seguintes, outros. Embaixo: o seu próprio gerador da semente 42 é uma sequência separada que o "
     "auxiliar nunca toca, então a sua linha sempre pega os cinco primeiros."),
    ("Whoever draws first from a shared generator moves everybody's numbers.",
     "Quem sorteia primeiro de um gerador compartilhado muda os números de todo mundo."))
f = shared
f.text(20, 24, "np.random.seed(42): one sequence for the whole program",
       "np.random.seed(42): uma sequência para o programa todo", anchor="start", weight="600")
for i in range(16):
    f.rect(20 + i * 42, 40, 38, 28, fill="panel", stroke="wire", rx=2, width=1)
    f.text(39 + i * 42, 54, f"v{i + 1}", mono=True, size=10, fill="paper-dim")
f.rect(20, 76, 3 * 42 - 4, 22, fill="scan", stroke="amber", rx=2, width=1)
f.text(20 + (3 * 42 - 4) / 2, 87, "tidy()", mono=True, size=10)
f.rect(20 + 3 * 42, 76, 5 * 42 - 4, 22, fill="scan", stroke="amber", rx=2, width=1)
f.text(20 + 3 * 42 + (5 * 42 - 4) / 2, 87, "your five", "os seus cinco", size=10)
f.text(20 + 8 * 42 + 6, 87, "shifted by whatever drew first", "deslocados por quem sorteou antes",
       anchor="start", size=10, fill="amber")
f.text(20, 136, "rng = np.random.default_rng(42): yours alone",
       "rng = np.random.default_rng(42): só seu", anchor="start", weight="600")
for i in range(16):
    f.rect(20 + i * 42, 152, 38, 28, fill="panel", stroke="wire", rx=2, width=1)
    f.text(39 + i * 42, 166, f"w{i + 1}", mono=True, size=10, fill="paper-dim")
f.rect(20, 188, 5 * 42 - 4, 22, fill="scan", stroke="phosphor", rx=2, width=1)
f.text(20 + (5 * 42 - 4) / 2, 199, "your five", "os seus cinco", size=10)
f.text(20 + 5 * 42 + 6, 199, "the same with or without tidy()", "iguais com ou sem tidy()",
       anchor="start", size=10, fill="paper-dim")

FIGURES = [shared]
