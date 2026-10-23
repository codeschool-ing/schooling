"""Lesson 19: the figures."""
from fig import Fig

T = {
    "en": dict(
        layers_aria="Three automated checks and what each one reads. pytest runs the tests, which state what the application must do and must refuse. bandit reads the source code without running it and reports calls known to be risky. pip-audit reads the list of dependencies and reports published advisories. All three run from one command, check.sh, before every commit. What none of them reads is whether a route checks whose data it serves, which stays with the review of lesson 18.",
        t1="pytest", r1="the tests: what must work,", r1b="and what must be refused",
        t2="bandit", r2="the source: calls known", r2b="to be risky",
        t3="pip-audit", r3="the dependencies:", r3b="published advisories",
        one="one command, before every commit",
        none="none of them asks whose data a route serves",
        layers_cap="Three tools, three things read. Each finds what the other two cannot see.",
    ),
    "pt": dict(
        layers_aria="Três verificações automáticas e o que cada uma lê. O pytest roda os testes, que dizem o que a aplicação deve fazer e deve recusar. O bandit lê o código-fonte sem executá-lo e aponta chamadas sabidamente arriscadas. O pip-audit lê a lista de dependências e aponta alertas publicados. As três rodam de um comando, check.sh, antes de todo commit. O que nenhuma delas lê é se uma rota verifica de quem é o dado que entrega, e isso fica com a revisão da aula 18.",
        t1="pytest", r1="os testes: o que deve funcionar,", r1b="e o que deve ser recusado",
        t2="bandit", r2="o código: chamadas", r2b="sabidamente arriscadas",
        t3="pip-audit", r3="as dependências:", r3b="alertas publicados",
        one="um comando, antes de todo commit",
        none="nenhuma pergunta de quem é o dado que uma rota entrega",
        layers_cap="Três ferramentas, três coisas lidas. Cada uma acha o que as outras duas não veem.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l19-layers", 720, 260, t["layers_aria"])
    f.box(260, 14, 200, 40, ["check.sh"], stroke="phosphor", mono=True, bold=True)
    f.text(475, 34, t["one"], anchor="start", fill="paper-dim", italic=True)
    for i, (tool, a, b) in enumerate(((t["t1"], t["r1"], t["r1b"]), (t["t2"], t["r2"], t["r2b"]), (t["t3"], t["r3"], t["r3b"]))):
        x = 20 + i * 235
        f.box(x, 100, 210, 36, [tool], mono=True, bold=True)
        f.box(x, 150, 210, 50, [a, b], stroke="wire", size=9.5)
        f.arrow([(360, 54), (360, 84), (x + 105, 84), (x + 105, 100)])
    f.text(360, 235, t["none"], fill="paper-dim", italic=True)
    out["l19-layers"] = f.json(t["layers_cap"])
    return out
