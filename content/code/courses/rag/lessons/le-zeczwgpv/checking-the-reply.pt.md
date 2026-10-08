---
title: Conferindo a resposta
version: 2
---

O que quer que tenha chegado ao modelo, a resposta pode ser conferida antes de alguém vê-la, e a aula 7
já escreveu a verificação. Uma resposta cujas frases não estão citadas literalmente, ou perto disso,
nas fontes que referenciam não é mostrada:

```schooling-example
{
  "language": "python",
  "file": "checked.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask\nfrom listings import LISTINGS, as_sources\nfrom verify import check",
      "note": "O prompt e a verificação da aula 7."
    },
    {
      "code": "SAFE = \"I can't compare these listings right now. Each listing's page has the seller's full description.\"\nquestion = sys.argv[1]\nsources = as_sources(LISTINGS)\nreply = ask(question, sources)\nverdicts = check(reply, sources)\nprint(\"reply:  \", reply)\nprint(\"checks: \", [v for _, _, v in verdicts])\ngrounded = all(v.startswith((\"quoted\", \"close\")) for _, _, v in verdicts)\nprint(\"shown:  \", reply if grounded else SAFE)",
      "note": "A resposta só aparece se toda frase estiver citada literalmente ou perto da fonte que referencia. Qualquer outra coisa, inclusive uma resposta que não cita nada, é trocada por um aviso seguro que não promete nada."
    }
  ]
}
```

```
ana@vm:~/rag$ python checked.py "Which copy of Emma is for sale, and in what condition?"
reply:   According to source [4], the copy of Emma for sale is in the condition of "acceptable" and has a loose front cover and some underlining in pencil in the first three chapters.
checks:  ['unsupported (0.58)']
shown:   I can't compare these listings right now. Each listing's page has the seller's full description.
```

**A resposta estava certa, e o cliente viu o aviso seguro no lugar dela.** O modelo juntou a condição,
que está na linha de cabeçalho do anúncio, à descrição, e a frase que escreveu marca 0,58 contra as
frases da descrição, abaixo dos 0,75 que a verificação chama de perto. A verificação não distingue um
ataque de uma paráfrase; ela só distingue o que é rastreável até um anúncio do que não é. Num dia comum
isso custa uma resposta certa de vez em quando, e esse custo é o preço da camada: no dia em que uma
injeção fizer o modelo dizer algo novo, a mesma regra o mantém longe do cliente.

Esta camada é forte contra injeções que fazem o modelo dizer algo novo: uma afirmação inventada, uma
instrução ao cliente, um link, uma palavra. É mais fraca contra uma injeção que faz o modelo **escolher**
entre frases verdadeiras, por exemplo citar só a metade elogiosa de um anúncio, porque toda frase que
ele mostra está de fato numa fonte. É por isso que a verificação é uma camada e não a resposta inteira, e
por isso a próxima seção mantém texto não confiável fora dos contextos em que uma frase verdadeira bem
escolhida poderia causar dano.

O aviso seguro é simples de propósito. Ele não diz que algo suspeito aconteceu, o que contaria a quem
plantou o texto que ele foi notado, e não arrisca uma resposta. Ele manda o cliente para as páginas dos
anúncios, que mostram o que os vendedores escreveram e nada que um modelo tenha feito disso.
