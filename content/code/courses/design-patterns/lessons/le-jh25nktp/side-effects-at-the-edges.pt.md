---
title: "Efeitos colaterais nas bordas: um núcleo funcional numa casca imperativa"
version: 1
---

**Um programa sem efeitos colaterais não faz nada de útil.** Ele não consegue ler uma requisição,
salvar um empréstimo nem mandar um lembrete. Então a ideia funcional não é tirar os efeitos, o que é
impossível, e sim decidir onde eles moram. O nome que Gary Bernhardt deu ao arranjo, numa palestra
de 2012 chamada *Boundaries*, é **núcleo funcional, casca imperativa** (*functional core, imperative
shell*): as decisões são tomadas por funções puras no meio, e uma camada externa fina faz toda a
leitura, a escrita e as perguntas ao relógio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-shell\" aria-label=\"Um núcleo funcional dentro de uma casca imperativa. A caixa de fora, a casca, guarda os efeitos: à esquerda, carregar os empréstimos e ler a data da linha de comando ou do relógio; à direita, gravar outbox.txt e imprimir um resumo. Setas levam os empréstimos e a data para a caixa de dentro, o núcleo, que guarda as funções puras notices e days_late e devolve uma lista de valores Notice. Uma seta leva os avisos de volta para a casca, que os grava. Embaixo da casca: efeitos, poucas decisões. Embaixo do núcleo: decisões, nenhum efeito.\"><defs><marker id=\"l15-shell-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"262.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">casca imperativa: shell.py</text><rect x=\"250.0\" y=\"70.0\" width=\"220.0\" height=\"150.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">núcleo funcional: core.py</text><text x=\"360.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notices(loans, today)</text><text x=\"360.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">days_late(loan, today)</text><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ list[Notice]</text><text x=\"360.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">decisões, nenhum efeito</text><rect x=\"45.0\" y=\"87.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carregar os empréstimos</text><rect x=\"45.0\" y=\"157.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data: argv ou relógio</text><path d=\"M215.0 105.0 L250.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><path d=\"M215.0 175.0 L250.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><rect x=\"505.0\" y=\"87.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gravar outbox.txt</text><rect x=\"505.0\" y=\"157.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imprimir um resumo</text><path d=\"M470.0 140.0 L505.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><path d=\"M470.0 150.0 L505.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">efeitos, poucas decisões</text></svg>", "caption": "O núcleo é testado com valores simples; a casca é fina o bastante para ser conferida rodando uma vez."}
```

## O núcleo decide

Os avisos de atraso da biblioteca de novo, divididos nessa linha. O núcleo recebe empréstimos e uma
data e devolve os avisos que deveriam ser enviados. Ele não envia nada:

```schooling-example
{"language": "python", "file": "core.py", "parts": [
 {"code": "# core.py\nfrom dataclasses import dataclass\nfrom datetime import date\n\nDAILY_FINE = 50  # cents", "note": "Nada de `sys`, de `open`, de `date.today()`. Só os imports já dizem que este módulo não toca em nada fora dele."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: str\n    email: str\n    title: str\n    due: date\n\n\n@dataclass(frozen=True)\nclass Notice:\n    to: str\n    text: str", "note": "Um aviso é um valor: para quem é e o que diz. Decidir mandar um e mandá-lo agora são duas coisas diferentes."},
 {"code": "\n\ndef days_late(loan: Loan, today: date) -> int:\n    return max((today - loan.due).days, 0)", "note": "Hoje é um argumento. O núcleo nunca pergunta que dia é."},
 {"code": "\n\ndef notices(loans: list[Loan], today: date) -> list[Notice]:\n    out = []\n    for loan in loans:\n        late = days_late(loan, today)\n        if late > 0:\n            text = f\"{loan.member}, '{loan.title}' is {late} days late: {late * DAILY_FINE} cents so far\"\n            out.append(Notice(loan.email, text))\n    return out", "note": "Um laço que acrescenta numa lista local, e ainda assim puro: `out` nasce dentro da chamada e é devolvido. Ninguém de fora o viu mudar."}
]}
```

## A casca faz

A casca é tudo o que o núcleo se recusou a fazer: carrega os empréstimos, lê a data, grava a caixa
de saída e fala com o usuário. Ela não tem decisões próprias.

```schooling-example
{"language": "python", "file": "shell.py", "parts": [
 {"code": "# shell.py\nimport sys\nfrom datetime import date\n\nfrom core import Loan, notices", "note": "A casca importa o núcleo. O núcleo nunca importa a casca, e é essa direção que o mantém puro."},
 {"code": "\n\ndef load_loans() -> list[Loan]:\n    return [Loan(\"Bia\", \"bia@example.org\", \"Dom Casmurro\", date(2026, 3, 16)),\n            Loan(\"Caio\", \"caio@example.org\", \"Iracema\", date(2026, 3, 30)),\n            Loan(\"Duda\", \"duda@example.org\", \"Vidas Secas\", date(2026, 3, 18))]", "note": "No lugar de uma consulta ao banco, que também seria um efeito. Na lição 12 isto era um repositório."},
 {"code": "\n\ndef main() -> None:\n    today = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()\n    outbox = notices(load_loans(), today)\n    with open(\"outbox.txt\", \"w\") as f:\n        for n in outbox:\n            f.write(f\"To: {n.to}\\n{n.text}\\n\\n\")\n    print(f\"{len(outbox)} notices written to outbox.txt for {today}\")", "note": "Ler, decidir, gravar: três linhas com o núcleo no meio. O relógio é lido aqui e só aqui, e uma data na linha de comando o substitui, que é como a execução abaixo pode ser repetida."},
 {"code": "\n\nif __name__ == \"__main__\":\n    main()"}
]}
```

```
ana@laptop:~/patterns/functional$ python3 shell.py 2026-03-20
2 notices written to outbox.txt for 2026-03-20
ana@laptop:~/patterns/functional$ cat outbox.txt
To: bia@example.org
Bia, 'Dom Casmurro' is 4 days late: 200 cents so far

To: duda@example.org
Duda, 'Vidas Secas' is 2 days late: 100 cents so far
```

Em 20 de março, Bia está quatro dias depois de 16 de março e Duda dois dias depois do dia 18; o livro
do Caio só vence no dia 30 e não recebe nada.

## O que a divisão compra

O núcleo é onde está a lógica, então é lá que vão os testes, e eles não precisam de nada:

```python
# test_core.py
import unittest
from datetime import date

from core import Loan, Notice, notices

BIA = Loan("Bia", "bia@example.org", "Dom Casmurro", date(2026, 3, 16))


class NoticesTest(unittest.TestCase):
    def test_a_late_loan_gets_a_notice(self):
        self.assertEqual(notices([BIA], date(2026, 3, 20)),
                         [Notice("bia@example.org", "Bia, 'Dom Casmurro' is 4 days late: 200 cents so far")])

    def test_nothing_is_due_yet(self):
        self.assertEqual(notices([BIA], date(2026, 3, 16)), [])
```

```
ana@laptop:~/patterns/functional$ python3 -m unittest -v test_core.py
test_a_late_loan_gets_a_notice (test_core.NoticesTest.test_a_late_loan_gets_a_notice) ... ok
test_nothing_is_due_yet (test_core.NoticesTest.test_nothing_is_due_yet) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

Nenhum servidor de correio falso, nenhum arquivo temporário, nenhum relógio remendado. **A casca fica
com tão pouca lógica que pode ser conferida rodando uma vez**, que foi o que a transcrição acima fez.
Compare com o `remind` da lição 13, que recebia uma função `send` para um teste poder interceptar o
envio. Aquele projeto injeta o efeito; este devolve uma descrição do efeito e deixa quem chama
executá-lo. Os dois são honestos. Devolver valores é mais simples quando o trabalho do núcleo termina
numa decisão, e a injeção é necessária quando o núcleo precisa agir no meio do trabalho, digamos para
ler um registro dependendo de outro.

A mesma forma tem outros nomes que você pode encontrar. Portas e adaptadores, da lição 4, põe o
domínio no meio e a E/S na borda por um motivo estrutural; o núcleo funcional o põe lá por um motivo
de pureza, e os dois chegam a códigos muito parecidos.
