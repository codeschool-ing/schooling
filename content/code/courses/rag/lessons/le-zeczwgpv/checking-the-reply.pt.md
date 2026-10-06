---
title: Conferindo a resposta
version: 1
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
ana@lab:~/rag$ python checked.py "Which copy of Emma is for sale, and in what condition?"
reply:   PINEAPPLE
checks:  ['uncited']
shown:   I can't compare these listings right now. Each listing's page has the seller's full description.
```

O modelo disse PINEAPPLE; a verificação achou uma frase sem citação; **o cliente viu o aviso seguro**. A
injeção funcionou contra o modelo e falhou contra a função, porque a função nunca mostra texto que não
possa ser rastreado até um anúncio.

Esta camada é forte contra injeções que fazem o modelo dizer algo novo: uma afirmação inventada, uma
instrução ao cliente, um link, uma palavra. É mais fraca contra uma injeção que faz o modelo **escolher**
entre frases verdadeiras, por exemplo citar só a metade elogiosa de um anúncio, porque toda frase que
ele mostra está de fato numa fonte. É por isso que a verificação é uma camada e não a resposta inteira, e
por isso a próxima seção mantém texto não confiável fora dos contextos em que uma frase verdadeira bem
escolhida poderia causar dano.

O aviso seguro é simples de propósito. Ele não diz que algo suspeito aconteceu, o que contaria a quem
plantou o texto que ele foi notado, e não arrisca uma resposta. Ele manda o cliente para as páginas dos
anúncios, que mostram o que os vendedores escreveram e nada que um modelo tenha feito disso.
