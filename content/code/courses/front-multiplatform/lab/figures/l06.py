"""Lesson 6: the decision, as three questions."""
from fig import Fig

T = {
 "en": dict(aria="Three questions in order. First: does the core of the app happen outside its screen, in widgets, a watch, background work? If yes, go native or to React Native. If no, second: is the core an interaction the web does badly on a phone, such as long lists all day or heavy gestures? If yes, measure first, and if the ceiling is the platform's, go native or React Native. If no, third: does the app do something its website cannot? If yes, wrap it. If no, the website, perhaps as a Progressive Web App, may be the right answer and no store at all.",
   q1=["does the core happen", "outside the screen?"], q2=["is the core what the web", "does badly on a phone?"], q3=["does it do what its", "website cannot?"],
   yes="yes", no="no", native=["native, or", "React Native"], measure=["measure first:", "whose ceiling is it?"], wrap=["wrap it"], site=["the website, perhaps", "as a PWA"],
   cap="Three questions, in this order. Most apps reach the third, and most of those are right to be wrapped."),
 "pt": dict(aria="Três perguntas em ordem. Primeira: o núcleo do app acontece fora da tela dele, em widgets, num relógio, em trabalho em segundo plano? Se sim, nativo ou React Native. Se não, segunda: o núcleo é uma interação que a web faz mal num celular, como listas compridas o dia todo ou gestos pesados? Se sim, meça primeiro, e se o teto for da plataforma, nativo ou React Native. Se não, terceira: o app faz algo que o site dele não faz? Se sim, embrulhe. Se não, o site, talvez como Progressive Web App, pode ser a resposta certa, sem loja nenhuma.",
   q1=["o núcleo acontece", "fora da tela?"], q2=["o núcleo é o que a web", "faz mal num celular?"], q3=["ele faz o que o", "site dele não faz?"],
   yes="sim", no="não", native=["nativo, ou", "React Native"], measure=["meça primeiro:", "de quem é o teto?"], wrap=["embrulhe"], site=["o site, talvez", "como PWA"],
   cap="Três perguntas, nesta ordem. A maioria dos apps chega à terceira, e a maioria desses está certa em ser embrulhada."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l06-decide", 720, 260, t["aria"])
    xs = [20, 260, 500]
    for x, q in zip(xs, [t["q1"], t["q2"], t["q3"]]):
        f.box(x, 30, 190, 50, q, stroke="phosphor", size=9.5)
    f.arrow([(210, 55), (260, 55)]); f.text(235, 46, t["no"], size=8.5, fill="paper-dim")
    f.arrow([(450, 55), (500, 55)]); f.text(475, 46, t["no"], size=8.5, fill="paper-dim")
    f.box(20, 170, 190, 50, t["native"], stroke="amber", size=9.5)
    f.box(260, 170, 190, 50, t["measure"], stroke="wire", size=9.5)
    f.box(500, 130, 150, 40, t["wrap"], stroke="phosphor", size=10, bold=True)
    f.box(500, 200, 190, 44, t["site"], stroke="wire", size=9.5, dashed=True)
    f.arrow([(115, 80), (115, 170)]); f.text(128, 125, t["yes"], size=8.5, fill="paper-dim", anchor="start")
    f.arrow([(355, 80), (355, 170)]); f.text(368, 125, t["yes"], size=8.5, fill="paper-dim", anchor="start")
    f.arrow([(260, 195), (210, 195)], dashed=True)
    f.arrow([(560, 80), (560, 130)]); f.text(573, 105, t["yes"], size=8.5, fill="paper-dim", anchor="start")
    f.arrow([(680, 80), (680, 200)]); f.text(668, 140, t["no"], size=8.5, fill="paper-dim", anchor="end")
    same = None if lang == "en" else ["React Native"]
    return {"l06-decide": f.json(t["cap"], same=same)}
