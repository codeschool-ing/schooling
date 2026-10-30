"""Lesson 18: a download that resumes, byte by byte."""
from fig import Fig

T = {
    "en": dict(
        aria="A 3 MB file as a bar of bytes. Request 1, without a Range, is answered 200 and stalls after the first megabyte, which is kept in notes.pdf.part. Request 2 asks Range: bytes=1048576- with If-Range and the tag, is answered 206 Partial Content, and appends the remaining two megabytes. Only then is the part file renamed to notes.pdf, and only then is a row recorded.",
        r1="request 1: no Range", a1="200, stalls after 1 MB",
        r2="request 2: Range: bytes=1048576-", a2="206 Partial Content, the rest",
        kept="kept in", ren="then renamed", row="and then the row",
        cap="The first megabyte crosses the network once. The part file has its own name until the last byte is there.",
    ),
    "pt": dict(
        aria="Um arquivo de 3 MB como uma barra de bytes. A requisição 1, sem Range, recebe um 200 e trava depois do primeiro megabyte, que fica guardado em notes.pdf.part. A requisição 2 pede Range: bytes=1048576- com If-Range e a etiqueta, recebe um 206 Partial Content e acrescenta os dois megabytes restantes. Só então o arquivo parcial é renomeado para notes.pdf, e só então uma linha é gravada.",
        r1="requisição 1: sem Range", a1="200, trava depois de 1 MB",
        r2="requisição 2: Range: bytes=1048576-", a2="206 Partial Content, o resto",
        kept="guardado em", ren="depois renomeado", row="e só então a linha",
        cap="O primeiro megabyte atravessa a rede uma vez só. O arquivo parcial tem nome próprio até o último byte chegar.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l18-resume", 720, 230, t["aria"])
    x0, w = 40, 600
    third = w / 3
    f.rect(x0, 90, third, 40, stroke="phosphor", fill="panel")
    f.rect(x0 + third, 90, 2 * third, 40, stroke="amber", fill="panel")
    f.text(x0 + third / 2, 110, "0 – 1048575", mono=True, size=9.5)
    f.text(x0 + 2 * third, 110, "1048576 – 3145727", mono=True, size=9.5)
    f.text(x0, 36, t["r1"], anchor="start", size=10, bold=True, fill="phosphor")
    f.text(x0, 54, t["a1"], anchor="start", size=9.5, fill="paper-dim")
    f.arrow([(x0 + third / 2, 62), (x0 + third / 2, 88)], color="phosphor")
    f.text(x0 + third + 16, 36, t["r2"], anchor="start", size=10, bold=True, fill="amber")
    f.text(x0 + third + 16, 54, t["a2"], anchor="start", size=9.5, fill="paper-dim")
    f.arrow([(x0 + 2 * third, 62), (x0 + 2 * third, 88)], color="amber")
    f.text(x0, 150, t["kept"], anchor="start", size=9.5, fill="paper-dim")
    f.text(x0 + 74, 150, "notes.pdf.part", anchor="start", mono=True, size=9.5)
    f.arrow([(x0 + w + 6, 110), (x0 + w + 40, 110)])
    f.text(x0 + w - 4, 180, t["ren"], anchor="end", size=9.5, fill="paper-dim")
    f.text(x0 + w + 4, 180, "notes.pdf", anchor="start", mono=True, size=9.5, fill="phosphor")
    f.text(x0 + w - 4, 200, t["row"], anchor="end", size=9.5, fill="paper-dim", italic=True)
    same = None
    return {"l18-resume": f.json(t["cap"], same=same)}
