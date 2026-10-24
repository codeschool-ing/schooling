"""Lesson 6: the backend-for-frontend arrangement."""
from fig import Fig

T = {
    "en": dict(
        aria="Three boxes from left to right. The browser, running the planner's page, holds only an HttpOnly, Secure session cookie, and no script on the page can read it. It sends every request, with the cookie, to the BFF, a small server of the app's own. The BFF holds the access token and the refresh token, and attaches the access token to each request it passes on to the API. The identity provider sits above the BFF, which talks to it to exchange the code and to refresh tokens. A dashed line marks the boundary of what a script on the page can reach: only the browser box.",
        browser="the browser", page=["the planner's page", "holds: __Host-sid cookie"],
        bff="the BFF", bff_l=["the app's own server", "holds: access token,", "refresh token"],
        api="the API", api_l=["checks the", "access token"],
        idp="the identity provider",
        r1="request + cookie", r2="request + access token", r3="code, refresh",
        reach="what a script on the page can reach",
        cap="The tokens live on a server; the browser holds a cookie that means nothing to any script. A script on the page can still send requests while it runs, but it leaves with nothing.",
    ),
    "pt": dict(
        aria="Três caixas da esquerda para a direita. O navegador, rodando a página do planner, guarda só um cookie de sessão HttpOnly e Secure, e nenhum script da página consegue lê-lo. Ele manda cada requisição, com o cookie, para o BFF, um servidor pequeno do próprio app. O BFF guarda o access token e o refresh token, e anexa o access token a cada requisição que repassa à API. O provedor de identidade fica acima do BFF, que conversa com ele para trocar o código e renovar os tokens. Uma linha tracejada marca o limite do que um script da página alcança: só a caixa do navegador.",
        browser="o navegador", page=["a página do planner", "guarda: cookie __Host-sid"],
        bff="o BFF", bff_l=["o servidor do próprio app", "guarda: access token,", "refresh token"],
        api="a API", api_l=["confere o", "access token"],
        idp="o provedor de identidade",
        r1="requisição + cookie", r2="requisição + access token", r3="código, renovação",
        reach="o que um script da página alcança",
        cap="Os tokens moram num servidor; o navegador guarda um cookie que não quer dizer nada para script nenhum. Um script na página ainda manda requisições enquanto roda, mas vai embora sem nada.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l06-bff", 720, 250, t["aria"])
    f.rect(12, 92, 196, 126, stroke="amber", dashed=True, fill="ink", width=1)
    f.text(110, 236, t["reach"], size=9, italic=True, fill="amber")
    f.text(110, 108, t["browser"], bold=True, size=9.5)
    f.box(26, 122, 168, 70, t["page"], stroke="wire", size=9)
    f.text(390, 108, t["bff"], bold=True, size=9.5)
    f.box(300, 122, 180, 70, t["bff_l"], stroke="phosphor", size=9)
    f.text(630, 108, t["api"], bold=True, size=9.5)
    f.box(570, 122, 120, 70, t["api_l"], stroke="wire", size=9)
    f.box(300, 14, 180, 34, [t["idp"]], stroke="wire", size=9.5)
    f.arrow([(194, 157), (300, 157)])
    f.text(247, 175, t["r1"], size=8, fill="paper-dim")
    f.arrow([(480, 157), (570, 157)])
    f.text(525, 175, t["r2"], size=8, fill="paper-dim")
    f.arrow([(450, 122), (450, 48)], both=True)
    f.text(458, 84, t["r3"], anchor="start", size=8.5, fill="paper-dim")
    return {"l06-bff": f.json(t["cap"], same=["refresh token", "access token"] if lang == "pt" else None)}
