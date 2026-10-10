---
title: O que escrever o teste primeiro faz com o projeto
version: 1
---

**Um teste escrito primeiro é o primeiro a chamar o código, e código moldado por quem o chama
primeiro sai mais fácil de chamar.** É por isso que há quem leia o segundo D como *design*. Os
testes são uma rede de segurança, e também uma pressão constante sobre o projeto: na direção de
unidades pequenas, de entradas passadas em vez de buscadas, de decisões separadas de efeitos. A
pressão vem de algo prosaico. Código difícil de testar é difícil de testar primeiro, e você percebe
enquanto o projeto ainda é barato de mudar.

## O código que se escreve quando ninguém pergunta antes

A biblioteca quer uma rotina matinal que mande e-mail a todo membro com empréstimo atrasado. Escrita
de primeira, ela costuma ficar assim:

```python
def send_overdue_reminders(loans):
    for loan in loans:
        if loan.due < date.today():
            smtp = smtplib.SMTP("mail.example.org")
            smtp.sendmail("desk@example.org", loan.email, f"{loan.title} is overdue")
```

Agora tente escrever um teste para isso. Quais empréstimos estão atrasados depende do dia em que o
teste roda, então um teste que passa em 20 de março falha em 1º de abril. Rodá-lo manda e-mail de
verdade, ou falha por falta de servidor de correio. E a única coisa que vale conferir, *quais*
empréstimos contam como atrasados, está enrolada num laço que também abre conexões de rede. Testar
depois significa remendar `date.today` e `smtplib` por fora, o que funciona e deixa o projeto como
estava.

## O código que os testes pediram

Escrevendo o teste primeiro, você começaria pela chamada que quer fazer no teste, e dois fatos caem
na hora. O teste precisa escolher o dia, então `today` é um argumento. E o teste quer ver o que seria
enviado sem enviar, então o envio é algo passado de fora. Quatro ciclos depois, o arquivo fica assim:

```schooling-example
{"language": "python", "file": "reminders.py", "parts": [
 {"code": "# reminders.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Callable", "note": "Só biblioteca padrão, como em todo este curso."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    email: str\n    due: date", "note": "Só os campos de que esta rotina precisa. Um teste monta um em uma linha, e isso é uma propriedade do projeto, não sorte."},
 {"code": "\n\ndef overdue(loans: list[Loan], today: date) -> list[Loan]:\n    return [loan for loan in loans if loan.due < today]", "note": "A decisão sozinha: sem relógio, sem rede, nada para preparar. O primeiro teste trouxe esta função à existência."},
 {"code": "\n\ndef remind(loans: list[Loan], today: date, send: Callable[[str, str], None]) -> int:\n    late = overdue(loans, today)\n    for loan in late:\n        send(loan.email, f\"'{loan.title}' was due on {loan.due}\")\n    return len(late)", "note": "O efeito, mantido fino. `send` é qualquer função que receba um endereço e um texto; em produção ela fala com o servidor de correio, no teste ela acrescenta numa lista."}
]}
```

E os testes que o guiaram:

```schooling-example
{"language": "python", "file": "test_reminders.py", "parts": [
 {"code": "# test_reminders.py\nimport unittest\nfrom datetime import date\n\nfrom reminders import Loan, overdue, remind\n\nLOANS = [Loan(\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 16)),\n         Loan(\"Iracema\", \"caio@example.org\", date(2026, 3, 30))]", "note": "Dois empréstimos, um que vence antes de 20 de março e um depois. Datas fixas, para o teste querer dizer a mesma coisa em qualquer dia que rode."},
 {"code": "\n\nclass OverdueTest(unittest.TestCase):\n    def test_only_loans_past_their_due_date(self):\n        late = overdue(LOANS, today=date(2026, 3, 20))\n        self.assertEqual([loan.title for loan in late], [\"Dom Casmurro\"])\n\n    def test_due_today_is_not_overdue(self):\n        self.assertEqual(overdue(LOANS, today=date(2026, 3, 16)), [])", "note": "O segundo teste fixa a fronteira: um empréstimo que vence hoje ainda não está atrasado. Troque o `<` de `overdue` por `<=` e é este o teste que fica vermelho."},
 {"code": "\n\nclass RemindTest(unittest.TestCase):\n    def test_sends_one_message_per_overdue_loan(self):\n        sent = []\n        count = remind(LOANS, date(2026, 3, 20), lambda to, text: sent.append((to, text)))\n        self.assertEqual(count, 1)\n        self.assertEqual(sent, [(\"bia@example.org\", \"'Dom Casmurro' was due on 2026-03-16\")])", "note": "Quem envia é uma lambda que registra o que recebeu. Sem servidor de correio, e a asserção lê a mensagem exata."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()"}
]}
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_reminders.py
test_due_today_is_not_overdue (test_reminders.OverdueTest.test_due_today_is_not_overdue) ... ok
test_only_loans_past_their_due_date (test_reminders.OverdueTest.test_only_loans_past_their_due_date) ... ok
test_sends_one_message_per_overdue_loan (test_reminders.RemindTest.test_sends_one_message_per_overdue_loan) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

## Três pressões, com nome

Veja o que o teste fez com a forma, porque ele faz a mesma coisa em qualquer base de código:

| do que o teste precisava | o que o projeto ganhou |
|---|---|
| escolher o dia | o relógio virou argumento, `today` |
| conferir a decisão sozinha | `overdue` separado de `remind`, uma função pura ao lado de um efeito fino |
| ver a mensagem sem enviá-la | quem envia passado de fora, `send` |

A terceira linha é injeção de dependência, alcançada pelo lado do teste. A lição 5 trata do mesmo
movimento pelo lado do projeto, e do único lugar, a raiz de composição, onde o `date.today()` real e
o remetente de e-mail real são plugados. A segunda linha é o núcleo funcional com casca imperativa
que a lição 15 constrói de propósito.

## Quando a pressão aponta para o lado errado

**Um teste doloroso de escrever é informação sobre o projeto**, em geral de que a unidade tem
colaboradores demais ou faz coisas demais. Dez linhas de preparação antes de uma asserção são o
teste dizendo isso. A correção está no código, não num auxiliar de teste mais esperto.

A queixa oposta também é real. David Heinemeier Hansson a chamou de *test-induced design damage* em
2014: indireção acrescentada só para um teste conseguir entrar, camadas e interfaces com uma
implementação cada, que deixam o código de produção mais difícil de ler por causa dos testes. O
contrapeso é injetar o que é de fato incômodo, o relógio, a rede, a aleatoriedade, e deixar todo o
resto ser chamado direto. `overdue` recebe uma lista e uma data e não chama nada; não precisou de
injeção nenhuma.
