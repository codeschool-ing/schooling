---
title: Recomendação, e como saber se ela funciona
version: 1
---

**Um recomendador ordena coisas para alguém.** A entrada é um membro e a saída é uma lista curta de
títulos, o melhor primeiro. Há famílias inteiras de algoritmos para isso; esta seção usa o mais
antigo, que um engenheiro de dados constrói em SQL e uma página de Python: **quem comprou isto também
comprou aquilo.** Conte, para cada par de títulos, quantos membros têm os dois. Um membro que tem o
título A recebe então os títulos que mais aparecem ao lado de A.

Contados crus, os títulos mais populares aparecem ao lado de tudo, então todo membro receberia os
mesmos best-sellers. O programa divide cada contagem pela popularidade do título recomendado, o que
faz uma pergunta melhor: **B é comprado junto com A mais do que B é comprado de qualquer jeito?**
Salve-o como `recommend.py`:

```python
"""recommend.py: members who bought this also bought, tested on the months that followed."""
import sqlite3
from collections import Counter
from itertools import combinations

CUT = "2025-11-30"
BOUGHT = """
SELECT DISTINCT p.member_id, l.title_id, p.day > :cut AS later
FROM purchases p JOIN lines l USING (purchase_id)
"""

with sqlite3.connect("shop.db") as db:
    rows = db.execute(BOUGHT, {"cut": CUT}).fetchall()
    names = dict(db.execute("SELECT title_id, title FROM titles"))
before, after = {}, {}
for member, title, later in rows:
    (after if later else before).setdefault(member, set()).add(title)

popular = Counter(t for titles in before.values() for t in titles)
together = Counter()
for titles in before.values():
    for a, b in combinations(sorted(titles), 2):
        together[a, b] += 1
        together[b, a] += 1


def recommend(member, n=5):
    owned = before.get(member, set())
    score = Counter()
    for a in owned:
        for b in names:
            if b not in owned:
                score[b] += together[a, b] / popular[b]   # lift over plain popularity
    return [t for t, _ in score.most_common(n)]


def most_popular(member, n=5):
    owned = before.get(member, set())
    return [t for t, _ in popular.most_common() if t not in owned][:n]


member = 2
print("member 2 owned:", ", ".join(names[t] for t in sorted(before[member])))
print("recommended:   ", ", ".join(names[t] for t in recommend(member)))

tested = [m for m in after if m in before and after[m] - before[m]]
for name, fn in (("co-purchase", recommend), ("most popular", most_popular)):
    hits = sum(bool(set(fn(m)) & after[m]) for m in tested)
    print(f"{name:13} a new title bought after {CUT} was in the top 5 for "
          f"{hits} of {len(tested)} members ({hits / len(tested):.1%})")
```

A contagem usa só as compras até 30 de novembro. O que os membros compraram **depois** dessa data
fica separado, e é como o recomendador é julgado.

```
ana@dev:~/ml$ python recommend.py
member 2 owned: The Garden of Crime, The Winter of Crime, The Letter of Crime, The Island of Crime, The Lantern of Crime, The Orchard of Crime, The River of Literary, The Garden of Literary, The Lantern of Literary, The Orchard of Literary, The Harbour of Cooking, The Harbour of Science
recommended:    The Harbour of Crime, The Mirror of Crime, The Station of Crime, The River of Crime, The Mirror of Literary
co-purchase   a new title bought after 2025-11-30 was in the top 5 for 1573 of 2343 members (67.1%)
most popular  a new title bought after 2025-11-30 was in the top 5 for 492 of 2343 members (21.0%)
```

O membro 2 tinha seis títulos policiais e quatro de literatura, e recebeu mais quatro policiais e um
de literatura. Isso parece bom, o que não prova nada; um recomendador é julgado pelo que os membros
de fato fizeram a seguir.

## O teste

**Para cada membro que comprou depois de 30 de novembro um título que ainda não tinha, algum desses
títulos estava entre os cinco recomendados em 30 de novembro?** Isso se chama **taxa de acerto em
5** (*hit rate at 5*), e é a mesma pergunta feita à linha de base, os cinco títulos mais populares
que o membro não tem.

| | taxa de acerto em 5 |
| --- | --- |
| mais populares | 21,0% |
| compra conjunta | 67,1% |

Três vezes mais membros acharam algo que foram comprar. Duas ressalvas mantêm esse número honesto.
**Os membros da loja têm um gosto muito regular**, porque o gerador dá a cada membro duas categorias
favoritas e tira delas pelo menos 80% dos livros, e leitores reais variam mais. E **um acerto não é
uma venda que a recomendação causou**: esses membros compraram esses livros sem nunca ter visto a
lista. Se mostrá-la muda alguma coisa é uma pergunta que só um experimento responde, que é o assunto
da lição 8 quando um modelo novo é testado numa parte do tráfego.
