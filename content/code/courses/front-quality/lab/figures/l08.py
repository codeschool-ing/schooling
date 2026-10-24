"""Lesson 8: the policy as the browser applies it."""
from fig import Fig

T = {
    "en": dict(
        aria="Five things the planner's page might try to run or load, each checked against its Content Security Policy. Its own script from /assets is allowed by script-src 'self'. An inline script added to the page is refused by the same directive. A script from another origin is refused by script-src 'self'. A fetch to another origin is refused by connect-src 'self'. Another site putting the page in a frame is refused by frame-ancestors 'none'.",
        attempt="what the page tries", rule="the directive that decides", verdict="",
        rows=[("its own /assets/index-….js", "script-src 'self'", "runs"),
              ("a <script> added to the page", "script-src 'self'", "refused"),
              ("a script from another origin", "script-src 'self'", "refused"),
              ("fetch() to another origin", "connect-src 'self'", "refused"),
              ("another site framing the page", "frame-ancestors 'none'", "refused")],
        cap="Every load passes one directive. The page's own files pass; everything that is not the page's own, including text that became a script, is refused before it runs.",
    ),
    "pt": dict(
        aria="Cinco coisas que a página do planner pode tentar rodar ou carregar, cada uma conferida contra a sua Content Security Policy. O próprio script de /assets é permitido pelo script-src 'self'. Um script inline acrescentado à página é recusado pela mesma diretiva. Um script de outra origem é recusado pelo script-src 'self'. Um fetch para outra origem é recusado pelo connect-src 'self'. Outro site pondo a página num frame é recusado pelo frame-ancestors 'none'.",
        attempt="o que a página tenta", rule="a diretiva que decide", verdict="",
        rows=[("o próprio /assets/index-….js", "script-src 'self'", "roda"),
              ("um <script> acrescentado à página", "script-src 'self'", "recusado"),
              ("um script de outra origem", "script-src 'self'", "recusado"),
              ("fetch() para outra origem", "connect-src 'self'", "recusado"),
              ("outro site pondo a página num frame", "frame-ancestors 'none'", "recusado")],
        cap="Cada carregamento passa por uma diretiva. Os arquivos da própria página passam; tudo o que não é da página, inclusive um texto que virou script, é recusado antes de rodar.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l08-policy", 720, 250, t["aria"])
    f.text(130, 18, t["attempt"], bold=True, size=9.5)
    f.text(420, 18, t["rule"], bold=True, size=9.5)
    for i, (what, rule, verdict) in enumerate(t["rows"]):
        y = 34 + i * 42
        ok = i == 0
        f.box(14, y, 236, 32, [what], size=9)
        f.arrow([(250, y + 16), (330, y + 16)])
        f.box(330, y, 180, 32, [rule], mono=True, size=9, stroke="wire")
        f.arrow([(510, y + 16), (580, y + 16)], color="phosphor" if ok else "amber")
        f.box(580, y, 120, 32, [verdict], size=9.5, bold=True, stroke="phosphor" if ok else "amber")
    return {"l08-policy": f.json(t["cap"])}
