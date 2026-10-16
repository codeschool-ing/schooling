---
title: Aprendizado por reforço, agindo e ouvindo como foi
version: 1
---

O terceiro tipo não tem tabela de exemplos nenhuma. **Um aprendiz por reforço age, recebe uma
recompensa e ajusta o que faz em seguida.** Ninguém lhe entrega a resposta certa; ele descobre quais
ações compensam tomando-as, e cada ação que toma muda o que ele consegue aprender.

Quatro palavras o sustentam:

- o **agente** escolhe;
- as **ações** são entre o que ele pode escolher;
- a **recompensa** é o número que lhe dizem depois;
- o **ambiente** é tudo o que decide a recompensa e que o agente não enxerga.

E uma tensão sustenta as quatro. A cada rodada, o agente pode **explorar o conhecido** (*exploit*),
escolhendo a ação que mais rendeu até agora, ou **experimentar** (*explore*), tentando outra caso ela
renda mais. Só aproveitar o conhecido o impede de aprender; só experimentar o impede de ganhar.

## Um voucher, escolhido na tentativa

O menor caso com essa tensão se chama **bandit**, por causa de uma fileira de caça-níqueis com
prêmios diferentes e desconhecidos. A Ponto Final tem três vouchers que poderia mandar a um membro
que está sumindo, e não sabe qual traz as pessoas de volta. O programa abaixo **inventa uma loja para
testá-los**: cada voucher tem uma taxa real com que os membros voltam, escrita no código onde o
aprendiz não pode lê-la, e o aprendiz precisa achar o melhor mandando-os. Salve-o como `bandit.py`:

```python
"""bandit.py: learn which voucher to send by sending them, in a simulated shop.

The shop is made up: each voucher brings a member back with a probability the
program is never told, and it has to find the best one by trying.
"""
import numpy as np

VOUCHERS = ["10% off", "free coffee", "double points"]
TRUE_RATE = [0.04, 0.07, 0.05]             # the world's, hidden from the learner
rng = np.random.default_rng(7)

sent = np.zeros(3)
returned = np.zeros(3)
for member in range(5000):
    if rng.random() < 0.1 or sent.min() == 0:
        choice = int(rng.integers(3))      # explore: try any voucher
    else:
        choice = int(np.argmax(returned / sent))   # exploit: the best so far
    came_back = rng.random() < TRUE_RATE[choice]   # the reward
    sent[choice] += 1
    returned[choice] += came_back

for name, s, r in zip(VOUCHERS, sent, returned):
    print(f"{name:14} sent {int(s):5}  came back {int(r):4}  rate {r / s:.3f}")
print(f"members brought back: {int(returned.sum())} of 5000")
```

Essa estratégia se chama **epsilon-greedy**: uma vez em dez ela experimenta ao acaso, e no resto do
tempo manda o voucher com a melhor taxa até ali.

```
ana@dev:~/ml$ python bandit.py
10% off        sent  1799  came back   73  rate 0.041
free coffee    sent  2373  came back  159  rate 0.067
double points  sent   828  came back   39  rate 0.047
members brought back: 271 of 5000
```

Ele achou o café grátis, e o mandou mais do que qualquer outro. As estimativas dele, 0,041, 0,067 e
0,047, estão perto dos verdadeiros 0,04, 0,07 e 0,05 que ele nunca viu. **E ele pagou para
descobrir**: 1.799 membros receberam o pior voucher, mais do que receberam o segundo melhor, porque
no começo uma sequência de sorte fez os 10% de desconto parecerem o vencedor e o aprendiz continuou
aproveitando-o até os números se corrigirem sozinhos. Mandar café grátis para todos os 5.000 teria
trazido de volta uns 350; o aprendiz trouxe 271, e a diferença é o preço de não saber.

## Por que um engenheiro de dados o encontra menos

Aprendizado por reforço é o que joga jogos, guia robôs e ajusta recomendações ao vivo, e é o tipo
que uma plataforma de dados sustenta com menos frequência, por um motivo que o programa mostra: **ele
aprende com as consequências das próprias ações**, então não pode ser treinado com a tabela do ano
passado. Ele precisa agir sobre membros reais, ou sobre um simulador bom o bastante para ficar no
lugar deles, e o simulador acima só é bom porque foi escrito para ser. O que a plataforma de fato
fornece é o registro: cada ação tomada, quando, para quem, e o que resultou dela, guardado para que a
próxima política possa ser julgada contra a anterior.

As lições 2 a 10 são supervisionadas e não supervisionadas. Quando esse tipo de aprendizado aparece
de novo é na lição 8, onde mandar um modelo novo para uma fração das requisições é a mesma escolha
entre experimentar e aproveitar, feita por uma pessoa.
