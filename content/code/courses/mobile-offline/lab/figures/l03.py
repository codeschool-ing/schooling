"""Lesson 3: what a scan reads, and what a search reads."""
from fig import Fig

T = {
    "en": dict(
        aria="Two strips standing for the 20,000 rows of big.db. Without an index, SCAN reads the whole strip to return 8 rows. With the index on (course, date), the rows are sorted by course and then by date, and SEARCH jumps to the statistics block and reads only the 8 rows inside the week.",
        t1="no index: SCAN", t2="index on (course, date): SEARCH",
        read="every one of 20,000 rows is read", ret="8 returned",
        sorted="the index, sorted by course, then by date",
        jump="only the 8 rows of statistics in the week",
        cap="The same query, on the same rows. The index costs a second sorted copy of two columns, and buys the right to read 8 rows instead of 20,000.",
    ),
    "pt": dict(
        aria="Duas faixas representando as 20.000 linhas do big.db. Sem índice, o SCAN lê a faixa inteira para devolver 8 linhas. Com o índice em (course, date), as linhas ficam ordenadas por curso e depois por data, e o SEARCH salta para o bloco de statistics e lê só as 8 linhas dentro da semana.",
        t1="sem índice: SCAN", t2="índice em (course, date): SEARCH",
        read="cada uma das 20.000 linhas é lida", ret="8 devolvidas",
        sorted="o índice, ordenado por curso e depois por data",
        jump="só as 8 linhas de statistics na semana",
        cap="A mesma consulta, nas mesmas linhas. O índice custa uma segunda cópia ordenada de duas colunas, e compra o direito de ler 8 linhas em vez de 20.000.",
    ),
}
COURSES = ["chemistry", "guitar", "history", "piano", "spanish", "statistics"]


def figures(lang):
    t = T[lang]
    f = Fig("l03-scan", 720, 250, t["aria"])
    f.text(20, 24, t["t1"], anchor="start", bold=True, size=10.5, fill="amber")
    f.rect(20, 36, 680, 26, stroke="amber", fill="ink")
    for i in range(1, 68):
        x = 20 + i * 10
        f.out.append(f'<path d="M{x} 38 L{x} 60" stroke="var(--wire)" stroke-width="1"></path>')
    f.text(360, 76, t["read"] + " · " + t["ret"], size=9.5, fill="paper-dim", italic=True)
    f.text(20, 110, t["t2"], anchor="start", bold=True, size=10.5, fill="phosphor")
    w = 680 / 6
    for i, c in enumerate(COURSES):
        x = 20 + i * w
        hot = c == "statistics"
        f.rect(round(x, 1), 122, round(w, 1), 26, stroke="phosphor" if hot else "wire", fill="ink")
        f.text(round(x + w / 2, 1), 135, c, mono=True, size=9, fill="paper" if hot else "paper-dim")
    f.text(360, 162, t["sorted"], size=9.5, fill="paper-dim", italic=True)
    sx = 20 + 5 * w + 70
    f.rect(round(sx, 1), 180, 8, 26, stroke="phosphor", fill="phosphor")
    f.arrow([(round(sx + 4, 1), 150), (round(sx + 4, 1), 178)], color="phosphor")
    f.text(round(sx - 12, 1), 193, t["jump"], anchor="end", size=9.5, fill="phosphor")
    return {"l03-scan": f.json(t["cap"])}
