"""Lesson 15: what rounding to two decimal places keeps."""
from fig import Fig

T = {
 "en": dict(aria="A grid of squares about 1.1 kilometres on each side, the cells of two decimal places of latitude and longitude. The phone reports a position to six decimal places, a point inside one cell. The journal keeps only the rounded coordinates, the nearest grid point, so every position inside the shaded area around it is stored as the same place.",
   phone="the phone reports", phone2="-23.561414, -46.655881", kept="the journal keeps", kept2="-23.56, -46.66", same="every position in the shaded", same2="square is stored the same", km="about 1.1 km",
   cap="Rounding is done before anything is kept, so the journal never holds more than a district."),
 "pt": dict(aria="Uma grade de quadrados de cerca de 1,1 quilômetro de lado, as células de duas casas decimais de latitude e longitude. O celular informa uma posição com seis casas decimais, um ponto dentro de uma célula. O diário guarda só as coordenadas arredondadas, o ponto da grade mais próximo, então toda posição dentro da área sombreada em volta dele é guardada como o mesmo lugar.",
   phone="o celular informa", phone2="-23.561414, -46.655881", kept="o diário guarda", kept2="-23.56, -46.66", same="toda posição no quadrado", same2="sombreado vira o mesmo lugar", km="cerca de 1,1 km",
   cap="O arredondamento acontece antes de qualquer coisa ser guardada, então o diário nunca tem mais que um bairro."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l15-round", 720, 260, t["aria"])
    x0, y0, s = 60, 30, 70
    for i in range(4):
        for j in range(3):
            f.rect(x0 + i * s, y0 + j * s, s, s, stroke="wire", fill="panel", rx=0, width=1)
    # the cell that rounds to the grid point at (x0+2s, y0+s)
    f.rect(x0 + 1.5 * s, y0 + 0.5 * s, s, s, stroke="amber", fill="panel", dashed=True, rx=0)
    f.rect(x0 + 2 * s - 4, y0 + s - 4, 8, 8, stroke="phosphor", fill="phosphor", rx=4)
    f.rect(x0 + 2.3 * s - 3, y0 + 1.15 * s - 3, 6, 6, stroke="amber", fill="amber", rx=3)
    f.text(x0 + 2 * s, y0 + 3 * s + 16, t["km"], size=9, fill="paper-dim")
    f.text(420, 60, t["phone"], anchor="start", size=10, fill="amber")
    f.text(420, 76, t["phone2"], anchor="start", mono=True, size=9.5, fill="paper")
    f.text(420, 118, t["kept"], anchor="start", size=10, fill="phosphor")
    f.text(420, 134, t["kept2"], anchor="start", mono=True, size=9.5, fill="paper")
    f.text(420, 176, t["same"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.text(420, 191, t["same2"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    return {"l15-round": f.json(caption=t["cap"])}
