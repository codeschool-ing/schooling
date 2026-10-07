---
title: Amostrar várias cadeias e votar
version: 2
---

A lição 26 terminou numa cadeia que soava bem e estava errada. O conserto tentador é deixar essa
cadeia mais cuidadosa: uma instrução melhor, um exemplo mais longo. **A autoconsistência
(*self-consistency*) segue outro caminho: pede várias cadeias de pensamento para a mesma pergunta e
fica com a resposta final a que a maioria chega.** Ela não tenta acertar nenhuma cadeia sozinha.
Ela conta com que as cadeias erradas errem de jeitos diferentes, enquanto as certas, com a redação
que tiverem, chegam ao mesmo número.

## Por que as amostras precisam variar

Uma votação entre cópias não é votação. À temperatura 0 um modelo pega o token de nota mais alta a
cada passo (lição 13), então o mesmo prompt dá o mesmo texto toda vez. O `toylm` mostra isso com
cinco sementes:

```
ana@lab:~/pe$ toylm generate "the café closes at" --temperature 0 --samples 5
[seed 1] six.
[seed 2] six.
[seed 3] six.
[seed 4] six.
[seed 5] six.
```

Cinco respostas idênticas não dizem nada que uma não dissesse. **As amostras precisam ser
sorteadas a uma temperatura acima de 0**, para que cada uma possa seguir um caminho diferente. O
`--samples` da lição 1 faz exatamente isso na temperatura padrão do `toylm`:

```
ana@lab:~/pe$ toylm generate "the café closes at" --samples 7
[seed 1] six.
[seed 2] noon on sunday.
[seed 3] six.
[seed 4] six.
[seed 5] six.
[seed 6] noon on sunday.
[seed 7] six.
```

Isso já é uma pequena votação, contada de olho: `six` cinco vezes, `noon on sunday` duas. As duas
são verdadeiras no corpus do café, e a próxima seção de leitura volta ao que isso quer dizer numa
votação. Um modelo grande
amostrado do mesmo jeito dá cadeias que variam na redação, na ordem dos passos e, às vezes, num
passo que dá errado.

## Sete cadeias para o pedido do café

A pergunta é a da lição 26: três flat whites a R$ 12, duas fatias de bolo a R$ 15 e um cartão
fidelidade já com 9 carimbos. O prompt é o que acertou a resposta lá, terminando numa linha
`Answer:`, salvo como `~/pe/prompts/order-chain.txt`. Um laço tira sete amostras na temperatura 0.7,
cada uma com a sua semente, um arquivo para cada. Duas delas, inteiras:

```
ana@lab:~/pe$ mkdir -p chains; for i in 1 2 3 4 5 6 7; do ask - --temperature 0.7 --seed $i --plain < prompts/order-chain.txt > chains/s$i.txt; done
ana@lab:~/pe$ cat chains/s2.txt
To find out how much the customer pays, we need to calculate the total cost of the items first.

The customer orders 3 flat whites at R$ 12 each, so the total cost of the flat whites is:
3 x R$ 12 = R$ 36

The customer also orders 2 slices of cake at R$ 15 each, so the total cost of the cake is:
2 x R$ 15 = R$ 30

Now, let's add the cost of the flat whites and the cake together:
R$ 36 + R$ 30 = R$ 66

Since the customer has 9 stamps on their loyalty card, they can get one free item with the tenth purchase. This means they get the 10th coffee for free.

The customer has already made 9 purchases, so the 10th purchase is the 10th coffee, which is free.

Now, let's subtract the cost of the 10th coffee (which is free) from the total cost:
R$ 66 - R$ 0 = R$ 66

However, considering that with the loyalty card, the tenth coffee is free, the customer won't have to pay for it.

So, the final amount the customer needs to pay is:
R$ 66 - R$ 12 (cost of 10th coffee) = R$ 54

Answer: R$ 54
ana@lab:~/pe$ cat chains/s3.txt
To calculate the total cost, we need to calculate the cost of the flat whites and the cake separately, then add them together.

Cost of flat whites:
3 flat whites at R$ 12 each = 3 x R$ 12 = R$ 36

Cost of cake:
2 slices of cake at R$ 15 each = 2 x R$ 15 = R$ 30

Total cost:
R$ 36 (flat whites) + R$ 30 (cake) = R$ 66

Since the customer already has 9 stamps on their loyalty card, they are eligible for the free coffee on their 10th purchase, not on this purchase. So, the customer will pay for all items, but they won't pay for the 10th coffee.

Answer: R$ 66
```

As duas começam igual, 36 e 30 e 66, e as duas depois raciocinam sobre o cartão. A `s2` se convence
de que não há café de graça, não subtrai nada, e depois subtrai mesmo assim: 54. A `s3` decide que o
café de graça é de outra visita e para em 66. Os passos são o mesmo tipo de texto irregular que a
lição 26 mostrou, e a votação não vai olhar para eles.

O `vote` pega a última linha de resposta de cada arquivo e as conta. Salve-o como `~/pe/bin/vote` e
torne-o executável:

```python
#!/usr/bin/env python3
"""vote FILE...: self-consistency. Each FILE is one sampled answer to the same
question, reasoning and all. The final answer is taken from its last
"answer is ..." or "Answer: ...", with a leading R$ dropped; a file with
neither casts no vote. The most common final answer wins."""
import re
import sys
from collections import Counter

finals = []
for f in sys.argv[1:]:
    text = open(f, encoding="utf-8").read()
    found = re.findall(r"answer(?: is|:)\s*:?\s*(?:R\$\s*)?([^\s.,]+)", text, re.I)
    if found:
        finals.append(found[-1].lower())
    print("%-16s %s" % (f, found[-1].lower() if found else "(no answer line: no vote)"))
if not finals:
    print("no votes")
    sys.exit(1)
tally = Counter(finals).most_common()
print("votes: " + ", ".join("%s x%d" % kv for kv in tally))
best, n = tally[0]
if len(tally) > 1 and tally[1][1] == n:
    print("no majority: a tie between %s" % " and ".join(k for k, v in tally if v == n))
else:
    print("majority: %s (%d of %d answers, %d files)" % (best, n, len(finals), len(sys.argv) - 1))
```

```
ana@lab:~/pe$ vote chains/*.txt
chains/s1.txt    72
chains/s2.txt    54
chains/s3.txt    66
chains/s4.txt    66
chains/s5.txt    66
chains/s6.txt    78
chains/s7.txt    54
votes: 66 x3, 54 x2, 72 x1, 78 x1
majority: 66 (3 of 7 answers, 7 files)
```

**A maioria é 66, e está errada.** A resposta certa, 54, veio duas vezes; a conta que esquece o
cartão veio três, e mais duas cadeias inventaram 72 e 78. As cadeias erradas não se espalharam: três
delas cometeram o mesmo erro, a leitura óbvia do pedido, que é também o texto mais provável para
este modelo escrever. Uma votação premia a resposta mais provável, e aqui a mais provável é o erro.
A próxima seção de leitura trata exatamente disso.

**Só as respostas finais são comparadas; o raciocínio é jogado fora.** É isso que torna a votação
possível: sete parágrafos com palavras diferentes não se contam, sete números se contam. É também
por isso que cada cadeia precisa de uma linha de resposta fixa, o mesmo hábito da linha `Answer:` da
lição 26, para que um programa ache o que contar. O `vote` tira um `R$` do começo antes de contar,
então `R$ 54` e `54` são uma resposta só.

## O procedimento

1. Escreva um prompt de cadeia de pensamento que termine numa linha de resposta fixa.
2. Mande-o N vezes a uma temperatura acima de 0, ou uma vez com um parâmetro que peça N amostras,
   se a API tiver um.
3. Extraia a resposta final de cada retorno, e trate um retorno sem resposta como voto nenhum; o
   `vote` diz quais arquivos não votaram.
4. Fique com a resposta mais comum.

A fração que a vencedora teve também é útil. **3 de 7 é um resultado fraco**, e um programa pode
agir sobre isso: aceitar uma votação unânime ou quase, e mandar uma dividida, como esta, para uma
pessoa ou para uma segunda rodada de amostras. Aqui essa regra teria pegado a resposta errada antes
de ela ser usada.
