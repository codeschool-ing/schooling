---
title: Medir o juiz
version: 2
---

Um juiz é um classificador. Ele lê duas respostas e devolve um rótulo, `a` ou `b`, então **ele é
medido do jeito que o prompt de triagem foi: contra rótulos que uma pessoa escreveu antes.** Este
programa pergunta ao juiz sobre cada par, lê a primeira letra da resposta e compara os vereditos com
os da pessoa. Com `--swap` ele pergunta uma segunda vez com as respostas na ordem inversa, de que a
próxima seção precisa. Salve-o como `judge.py`:

```python
"""judge: ask the model which of two replies is better, and measure it
against the verdicts a person wrote down."""
import argparse

from pl import DEFAULTS, call, read_jsonl, read_prompt, render


def ask(template, params, pair, first, second):
    """The judge's verdict, as "first", "second" or "?" if it said neither."""
    prompt = render(template, {"message": pair["message"],
                               "reply_a": pair[first], "reply_b": pair[second]})
    said = call(prompt, params)["text"].strip().upper()[:1]
    return {"A": first, "B": second}.get(said, "?")


def kappa(human, judge):
    """Cohen's kappa: agreement beyond what the two raters' rates give by chance."""
    n = len(human)
    observed = sum(h == j for h, j in zip(human, judge)) / n
    chance = sum(human.count(x) / n * judge.count(x) / n for x in ("a", "b"))
    return observed, (observed - chance) / (1 - chance) if chance < 1 else 1.0


p = argparse.ArgumentParser(prog="judge")
p.add_argument("pairs")
p.add_argument("--swap", action="store_true")
a = p.parse_args()

params, template = read_prompt("prompts/judge.txt")
params = {**DEFAULTS, **params}
pairs = read_jsonl(a.pairs)
human, judge, flips, stable = [], [], 0, 0
for pair in pairs:
    v = ask(template, params, pair, "a", "b")
    human.append(pair["human"])
    judge.append(v)
    line = "%s  human %s  judge %s" % (pair["id"], pair["human"], v)
    if a.swap:
        w = ask(template, params, pair, "b", "a")
        line += "  swapped %s%s" % (w, "  FLIP" if w != v else "")
        flips += w != v
        stable += w == v == pair["human"]
    print(line)
observed, k = kappa(human, judge)
print("\nagrees with the human on %d of %d" % (round(observed * len(pairs)), len(pairs)))
print("Cohen's kappa %.2f" % k)
if a.swap:
    print("changes its mind when the order is swapped: %d of %d" % (flips, len(pairs)))
    print("agrees AND keeps its verdict: %d of %d" % (stable, len(pairs)))
```

O `ask()` transforma a resposta na letra de uma das respostas. Uma resposta que não começa com `A`
nem com `B` é um `?`: nenhum veredito, que conta como discordância, do jeito que o `pl check` conta
uma resposta que não é JSON válido.

```
ana@lab:~/triage$ python3 judge.py cases/pairs.jsonl
j01  human b  judge b
j02  human b  judge b
j03  human a  judge b
j04  human a  judge a
j05  human b  judge ?
j06  human a  judge b
j07  human b  judge b
j08  human a  judge b
j09  human b  judge b
j10  human a  judge b
j11  human b  judge b
j12  human a  judge ?
j13  human b  judge b
j14  human b  judge b
j15  human a  judge b
j16  human a  judge b

agrees with the human on 8 of 16
Cohen's kappa 0.11
```

Oito de dezesseis concordam com a pessoa, 50%, e duas respostas não começaram com nenhuma das
letras. Isso parece uma moeda. É um pouco melhor que uma, e o motivo está em quais letras ele usou.

## Concordância além do acaso

Com duas respostas possíveis, um juiz que jogasse uma moeda concordaria com a pessoa mais ou menos
metade das vezes. A concordância bruta não diz quanto dos 50% é essa metade. **O kappa de Cohen mede
a concordância além do acaso**, uma estatística que Jacob Cohen publicou em 1960 exatamente para
isso: dois avaliadores separando os mesmos itens em categorias.

Ele precisa de dois números. A concordância observada é 8 de 16, 0,5. A concordância esperada por
acaso vem de quantas vezes cada avaliador usa cada resposta:

```
ana@lab:~/triage$ grep -c '"human": "a"' cases/pairs.jsonl
8
```

A pessoa escolheu `a` em 8 pares de 16. O juiz escolheu `a` uma vez, `b` treze vezes, e nada duas
vezes. Se os dois respondessem de forma independente com essas taxas, os dois diriam `a` com
probabilidade 8/16 × 1/16 = 0,03125, e os dois diriam `b` com probabilidade 8/16 × 13/16 = 0,40625.
Então concordariam 0,4375 das vezes por acaso.

O kappa é o quanto a concordância observada se afastou do acaso, como fatia do quanto ela poderia
ter se afastado: (0,5 − 0,4375) / (1 − 0,4375) = 0,11. **Um kappa de 0 é um juiz que concorda com
pessoas exatamente tanto quanto o acaso concordaria, e 1 é concordância perfeita.** A escala mais
citada, de Landis e Koch em 1977, chama tudo de 0 a 0,20 de leve. Um juiz que diz `b` treze vezes em
dezesseis acerta sete dos oito pares `b` por hábito, e o kappa tira esse hábito da conta.

## Calibre antes de confiar

Esse número é o que um juiz tem de mostrar antes de alguém se apoiar nele: uma amostra da tarefa
real, rotulada por pessoas que não viram a resposta do juiz, e a concordância do juiz com elas
corrigida pelo acaso. Dezesseis pares é o menor conjunto que deixa a aritmética visível, e o aviso da
aula 11 vale inteiro: um par mexe a concordância em seis pontos. Um juiz que você pretende usar em
milhares de respostas merece algumas centenas de pares rotulados antes.
