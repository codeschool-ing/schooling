---
title: Conferindo as citações
version: 1
---

Uma resposta com citações parece confiável, e isso é um risco próprio. Uma citação é uma afirmação
sobre de onde veio uma frase, e **um modelo pode produzir uma citação do mesmo jeito que produz
qualquer outro texto**: o id com cara de provável, depois da frase com cara de provável. A boa notícia
é que essa afirmação, ao contrário da maior parte do que um modelo diz, pode ser conferida por um
programa.

## Duas checagens que um programa consegue fazer

```python
def check_citations(answer, found):
    """Every cited id must be one that was retrieved, and every quoted phrase must be in it."""
    given = {c["id"]: c["text"] for c, _ in found}
    problems = []
    for cid in re.findall(r"\[([\w.-]+#\d+)\]", answer):
        if cid not in given:
            problems.append(f"cites {cid}, which was not among the passages")
    for sentence in re.split(r"(?<=\.)\s+", answer):
        cited = re.findall(r"\[([\w.-]+#\d+)\]", sentence)
        for quote in re.findall(r'"([^"]+)"', sentence):
            if cited and not any(quote.lower() in given.get(c, "").lower() for c in cited):
                problems.append(f'quotes "{quote}", which {", ".join(cited)} does not say')
    return problems
```

- **Todo id citado precisa ser um dos recuperados.** Se a resposta cita um trecho que não estava no
  prompt, a frase veio de outro lugar: do treino do modelo, ou de lugar nenhum.
- **Toda frase entre aspas precisa estar no trecho que ela cita.** Uma citação literal é a afirmação
  mais conferível que existe, e a que os leitores mais levam a sério.

## Três respostas, conferidas

Uma resposta cuja única citação está em ordem:

```
ana@dev:~/shop$ python lab/ask.py "My lamp stopped working after two months. What can I do?"
retrieved: warranty.md#1, shipping.md#1, returns.md#4
Two months is within the 90-day warranty, and "a lamp that does not light" is one of the faults it covers [warranty.md#1].
citations: every citation checks out
```

Uma resposta que cita um trecho que nunca recebeu:

```
ana@dev:~/shop$ python lab/ask.py "Can I return a mug I bought 40 days ago?"
retrieved: returns.md#1, account.md#1, returns.md#2
No. A customer may return an item "within 30 days of delivery" [returns.md#1], so a mug delivered 40 days ago is past the limit. If the mug is faulty, the 90-day warranty still covers it [warranty.md#1].
citations: cites warranty.md#1, which was not among the passages
```

A primeira frase está sustentada e confere. A segunda cita `warranty.md#1`, e os trechos recuperados
eram dois sobre devolução e um sobre contas. **A afirmação por acaso é verdadeira**, já que o manual dá
mesmo 90 dias de garantia, mas não veio dos trechos, então nada nesta requisição a sustenta. Em outra
pergunta, o mesmo movimento produz uma garantia confiante que a loja não oferece. O verificador não
distingue as duas, e não precisa: marca as duas.

Uma resposta cuja citação literal não está na fonte:

```
ana@dev:~/shop$ python lab/ask.py "Is the WELCOME10 coupon still valid in December?"
retrieved: coupons.md#1, shipping.md#2, coupons.md#2
Yes. WELCOME10 "takes 10% off and never expires" [coupons.md#1], so it is still valid in December.
citations: quotes "takes 10% off and never expires", which coupons.md#1 does not say
```

O manual diz que o WELCOME10 *has no end date*. A resposta cita *never expires*, que quer dizer a mesma
coisa, e põe entre aspas com uma citação, como se o manual dissesse aquilo. **A resposta está certa e a
citação literal foi inventada.** Um leitor que confiasse nas aspas repetiria uma frase que a loja nunca
escreveu.

## O que fazer com uma resposta marcada

- **Não mostre como conferida.** A resposta mais barata é mostrar a resposta sem as aspas ou sem a
  frase sem sustentação, ou recorrer a mostrar os próprios trechos.
- **Pergunte de novo, dizendo o problema**, o laço da aula 5 seção 07: "a frase que cita
  warranty.md#1 não é sustentada pelos trechos dados".
- **Conte-as.** A fração de respostas com problema de citação é um número a acompanhar, por prompt e
  por modelo, na avaliação da próxima seção.

A checagem prova que uma citação literal está no trecho e que um trecho citado foi dado. Não prova que
o trecho diz o que a frase afirma; uma frase pode citar o trecho certo e lê-lo errado. Essa parte ainda
precisa de uma pessoa, numa amostra.
