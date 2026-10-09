---
title: Amostrar e votar
version: 2
---

O outro jeito de ter vários votantes é perguntar a um prompt várias vezes com temperatura acima de
0, para que cada resposta seja uma amostra nova. É a forma que a autoconsistência assume. Aqui está o
`v6-escaped`, cinco amostras por mensagem a 0,8, votadas:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/s5.jsonl
ana@lab:~/triage$ python3 vote.py runs/s5.jsonl
sample 0                  46/70 right
sample 1                  47/70 right
sample 2                  45/70 right
sample 3                  43/70 right
sample 4                  46/70 right
majority of 5             46/70 right
unanimous on 61 cases, a tie on 0
```

Cinco amostras de cada uma das setenta mensagens, 350 chamadas. Cada amostra sozinha acertou entre 43
e 47 vezes, e a votação das cinco acertou 46. O mesmo prompt com temperatura 0, na execução da seção
anterior, acertou 45. **Uma resposta certa a mais, por cinco vezes as chamadas.** As cinco amostras
concordaram em 61 das setenta mensagens, então na maioria das mensagens a amostragem não mudou nada.

## Onde as amostras discordaram

O primeiro `awk` fica com os três primeiros caracteres de cada falha, o caso sem o número da
amostra. O `uniq -c` conta quantas amostras de cada caso reprovaram, e o último `awk` fica com os
casos que reprovaram em algumas amostras e não nas cinco:

```
ana@lab:~/triage$ pl check runs/s5.jsonl --failures | awk '$2 == "json" || $2 == "category" {print substr($1, 1, 3)}' | sort | uniq -c | awk '$1 < 5'
      3 h17
      2 h19
      1 h26
      1 t12
      1 t16
```

Cinco mensagens se dividiram. No `h17`, três amostras de cinco erraram, e a votação também, e a
temperatura 0 também. Nas outras quatro a maioria acertou, e a temperatura 0 também tinha acertado.
São os casos apertados que a aula 8 encontrou, e a votação deu a cada um a resposta que a temperatura
0 já dava.

A única mensagem que mudou não é um caso apertado de rótulo. É o `t38`:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 145, out 22, 2.6 s
ana@lab:~/triage$ pl check runs/s5.jsonl --failures | grep '^t38'
t38    urgency   high, expected normal
t38#1  urgency   high, expected normal
t38#2  urgency   high, expected normal
t38#3  urgency   high, expected normal
t38#4  urgency   high, expected normal
```

Com temperatura 0, o `v6-escaped` corta o resumo do `t38` no apóstrofo de *won't* e acrescenta uma
segunda chave de fechamento, a falha que a aula 15 registrou como F-0001. A 0,8 as cinco amostras
escreveram o resumo de outro jeito, as cinco eram analisáveis e as cinco tinham a categoria certa; a
urgência está errada em todas, e a votação não a conta. **A amostragem não achou um rótulo melhor
aqui. Ela contornou um defeito de formatação**, que um prompt corrigido contornaria com uma chamada
em vez de cinco.

## Compare com a melhor chamada única

Há uma armadilha em como isso é relatado. Comparada com uma amostra única a 0,8, entre 43 e 47, a
votação parece uma pequena vitória. Comparada com a resposta que você tem sem amostrar, é uma
mensagem melhor. Comparada com o melhor prompt único que você tem, o `v3-examples` com 54, é oito
pior. **Compare sempre um ensemble com a melhor chamada única**, não com um dos seus próprios
membros.

## De onde vem a autoconsistência

Os ganhos que tornaram a técnica conhecida eram reais, e vieram de outro tipo de tarefa.
*Self-Consistency Improves Chain of Thought Reasoning in Language Models* (Wang e outros, 2022)
amostrou várias cadeias de raciocínio para o mesmo problema, entre eles questões de aritmética e de
senso comum, e tomou a maioria das respostas finais. O argumento era que um problema tem muitos
caminhos de raciocínio até a resposta certa, e que cadeias erradas tendem a se espalhar por
respostas erradas diferentes, então a certa junta mais votos.

Uma classificação de uma palavra não tem cadeia. A amostra é a resposta, há um caminho só até ela, e
as amostras compartilham todo motivo que o prompt dá ao modelo para pender para um lado: aqui elas
concordaram em 61 mensagens de setenta. Antes de pagar por uma votação de amostras, pergunte se a sua
tarefa tem **muitos caminhos diferentes até uma resposta**. Se não tiver, meça-a primeiro contra a
temperatura 0, como acima.
