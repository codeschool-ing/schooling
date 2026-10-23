"""Lesson 15: the figures."""
from fig import Fig

T = {
    "en": dict(
        aria="One failure, written for two readers. On the left, the error page, read by whoever sent the request, which may be anybody: it says that something went wrong on the portal's side and gives a short reference. On the right, the log, read only by the team: it carries the same reference, the time, the path that failed and the full traceback. The reference is the only thing both share, and it is what lets the team find the failure a patient reports.",
        page="the error page", pagewho="read by whoever sent the request",
        p1="something went wrong on our side", p2="reference: …",
        log="the log", logwho="read by the team only",
        l1="ref=…  path='/patients/…'", l2="Traceback (most recent call last):", l3="  … KeyError: 'marta'",
        joins="the reference joins the two",
        cap="The page tells the person what happened; the log tells the team why. Only the reference appears in both.",
    ),
    "pt": dict(
        aria="Uma falha, escrita para dois leitores. À esquerda, a página de erro, lida por quem enviou a requisição, que pode ser qualquer um: diz que algo deu errado do lado do portal e dá uma referência curta. À direita, o log, lido só pela equipe: traz a mesma referência, a hora, o caminho que falhou e o traceback completo. A referência é a única coisa que os dois compartilham, e é o que permite à equipe achar a falha que um paciente relata.",
        page="a página de erro", pagewho="lida por quem enviou a requisição",
        p1="something went wrong on our side", p2="reference: …",
        log="o log", logwho="lido só pela equipe",
        l1="ref=…  path='/patients/…'", l2="Traceback (most recent call last):", l3="  … KeyError: 'marta'",
        joins="a referência liga os dois",
        cap="A página diz à pessoa o que aconteceu; o log diz à equipe por quê. Só a referência aparece nos dois.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l15-two", 720, 250, t["aria"])
    f.text(170, 22, t["page"], bold=True)
    f.text(170, 40, t["pagewho"], fill="paper-dim", italic=True, size=9.5)
    f.rect(20, 56, 300, 110, stroke="amber")
    f.text(40, 92, t["p1"], anchor="start", mono=True, size=9.5)
    f.text(40, 124, t["p2"], anchor="start", mono=True, size=9.5)
    f.text(535, 22, t["log"], bold=True)
    f.text(535, 40, t["logwho"], fill="paper-dim", italic=True, size=9.5)
    f.rect(370, 56, 330, 110, stroke="phosphor")
    f.text(386, 86, t["l1"], anchor="start", mono=True, size=9.5)
    f.text(386, 110, t["l2"], anchor="start", mono=True, size=9.5, fill="paper-dim")
    f.text(386, 134, t["l3"], anchor="start", mono=True, size=9.5, fill="paper-dim")
    f.arrow([(170, 166), (170, 200), (535, 200), (535, 166)], both=True)
    f.text(352, 220, t["joins"], fill="paper-dim", italic=True)
    out["l15-two"] = f.json(t["cap"])
    return out
