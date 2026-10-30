"""Lesson 20: two tokens over time, from sign-in to sign-out."""
from fig import Fig

T = {
    "en": dict(
        aria="A timeline from sign-in to sign-out. The password is typed once, at sign-in, and exchanged for an access token and a refresh token. Each access token lives a short time; when one expires the next request is answered 401, and the client spends the refresh token for a new pair, so each refresh token is used once. At sign-out the server revokes the last refresh token and the device wipes the tokens, the database and the cache.",
        pw="password, typed once", a="access token", r="refresh token",
        exp="401: expired", rot="spent, rotated",
        signin="sign-in", signout="sign-out: revoke, then wipe",
        t="time",
        cap="Neither token is the password. The one that lives long is used once at a time, and sign-out ends both, on the server and on the phone.",
    ),
    "pt": dict(
        aria="Uma linha do tempo da entrada à saída. A senha é digitada uma vez, na entrada, e trocada por um token de acesso e um token de renovação. Cada token de acesso vive pouco; quando um expira, a próxima requisição recebe um 401, e o cliente gasta o token de renovação por um par novo, então cada token de renovação é usado uma vez. Na saída, o servidor revoga o último token de renovação e o aparelho apaga os tokens, o banco e o cache.",
        pw="senha, digitada uma vez", a="token de acesso", r="token de renovação",
        exp="401: expirou", rot="gasto, renovado",
        signin="entrada", signout="saída: revogar, depois apagar",
        t="tempo",
        cap="Nenhum dos dois tokens é a senha. O que vive muito é usado uma vez por vez, e a saída acaba com os dois, no servidor e no celular.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l20-tokens", 720, 250, t["aria"])
    f.arrow([(60, 40), (60, 218)], color="amber", head=False, dashed=True)
    f.text(66, 40, t["signin"], anchor="start", size=9.5, fill="amber")
    f.text(66, 56, t["pw"], anchor="start", size=9, fill="paper-dim", italic=True)
    f.text(66, 100, t["a"], anchor="start", size=9.5, fill="phosphor", bold=True)
    f.text(66, 166, t["r"], anchor="start", size=9.5, fill="amber", bold=True)
    xs = [66, 266, 466]
    for i, x in enumerate(xs):
        f.rect(x, 110, 140, 26, stroke="phosphor", fill="panel")
        f.rect(x, 176, 200, 26, stroke="amber", fill="panel", dashed=i < 2)
        if i < 2:
            f.text(x + 170, 100, t["exp"], size=9, fill="paper-dim", italic=True)
            f.text(x + 100, 189, t["rot"], size=9, fill="paper-dim", italic=True)
            f.arrow([(x + 170, 140), (x + 198, 172)], color="paper-dim")
    f.arrow([(40, 228), (690, 228)])
    f.text(690, 242, t["t"], anchor="end", size=9, fill="paper-dim")
    f.arrow([(670, 60), (670, 218)], color="amber", head=False, dashed=True)
    f.text(664, 60, t["signout"], anchor="end", size=9.5, fill="amber")
    return {"l20-tokens": f.json(t["cap"])}
