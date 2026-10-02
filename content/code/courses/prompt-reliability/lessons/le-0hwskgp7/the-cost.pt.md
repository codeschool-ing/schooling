---
title: Quanto custa uma votação
version: 1
---

Um ensemble de n membros faz n chamadas para cada mensagem. **A conta é a soma das contas dos
membros**, e o ganho é o que a votação mediu. Ponha os dois lado a lado antes de ficar com um.

```
ana@lab:~/triage$ pl cost runs/v6.jsonl
tokens          count   per call
input            8443      120.6
cache_read          0        0.0
cache_write         0        0.0
output           2635       37.6

cost of these 70 calls: 6.4854 cents
cost of a million calls like them: 92,649 cents
ana@lab:~/triage$ pl cost runs/s5.jsonl
tokens          count   per call
input           42215      120.6
cache_read          0        0.0
cache_write         0        0.0
output          13175       37.6

cost of these 350 calls: 32.4270 cents
cost of a million calls like them: 92,649 cents
```

O `pl cost` soma os tokens que uma execução usou e os precifica com o `prices.json`, que guarda os
preços do curso e de nenhum fornecedor. O `v6-escaped` custa 6,4854 centavos por setenta chamadas.
A execução com cinco amostras usou os mesmos 120,6 tokens de entrada por chamada, fez cinco vezes
mais chamadas e custou 32,4270 centavos, exatamente cinco vezes mais. Em troca, acertou quatro
mensagens a menos.

O ensemble de três prompts custa a soma de três prompts diferentes:

```
ana@lab:~/triage$ pl cost runs/v3.jsonl
tokens          count   per call
input           16703      238.6
cache_read          0        0.0
cache_write         0        0.0
output           2621       37.4

cost of these 70 calls: 8.9424 cents
cost of a million calls like them: 127,749 cents
ana@lab:~/triage$ pl cost runs/v4.jsonl
tokens          count   per call
input            6553       93.6
cache_read          0        0.0
cache_write         0        0.0
output           2660       38.0

cost of these 70 calls: 5.9559 cents
cost of a million calls like them: 85,084 cents
```

Por milhão de mensagens, 127.749 + 85.084 + 92.649 = 305.482 centavos, contra 92.649 do
`v6-escaped` sozinho: **3,3 vezes o custo por duas respostas certas a mais em setenta**. O
`v3-examples` é o membro mais caro, porque os três exemplos dele vão junto em toda chamada.

Latência é a única coisa que um ensemble não precisa multiplicar. As chamadas são independentes,
então podem rodar ao mesmo tempo, e a espera é a do membro mais lento. O dinheiro continua sendo a
soma.

## Quando compensa

Três coisas decidem, e cada uma é algo que você consegue medir:

- **Quanto custa um erro.** Duas respostas certas a mais em setenta valem 3,3 vezes a conta quando
  um rótulo errado deixa uma conta invadida na fila errada. Não valem quando um rótulo errado
  significa uma pessoa reclassificando uma pergunta sobre a newsletter.
- **Quanto custa uma chamada.** Um ensemble de três chamadas a um modelo pequeno e barato pode
  custar menos que uma chamada a um grande. É uma comparação que vale rodar com o `pl cost` nos
  dois.
- **Quão diferentes são os membros.** A conta só rende quando os membros erram coisas diferentes.
  Conte do jeito da seção dos três prompts, caso a caso, antes de contar dinheiro.

A ordem dessas verificações importa. **Meça o ganho da votação contra a melhor chamada única
primeiro**; se for zero ou negativo, como foi o das cinco amostras, o custo nem precisa ser
calculado.
