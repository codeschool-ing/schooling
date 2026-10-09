---
title: O que um prompt mais longo compra
version: 2
---

Um prompt cresce do jeito que um documento de políticas cresce. Alguém vê uma resposta ruim e
acrescenta uma linha, outra pessoa acrescenta a mesma linha em maiúsculas, e ninguém apaga nada,
porque apagar parece mais arriscado do que acrescentar. **A ideia por baixo disso é que um prompt
mais longo é um prompt mais cuidadoso.** Ele é só mais longo, e o comprimento tem um preço que se
paga em toda chamada.

Aqui está o prompt de triagem depois de algumas semanas desse tipo de cuidado. Salve-o como
`prompts/v2-long.txt`:

```
You are a helpful, friendly and professional assistant for Folio, an online bookshop.
Your job is to read customer messages and sort them so the support team can answer them.

Keep the summary brief so the team can scan the queue quickly.

Answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": what the customer needs

IMPORTANT: Do not make up information that is not in the message.
Do not add fields that are not listed above.
Never include the customer's name or email in the summary.
IMPORTANT: Do not make up information that is not in the message.

The team reads the summary instead of the message, so describe the problem in full detail.

Message: {{message}}
```

Ele pede os mesmos três campos com as mesmas duas listas do `v2-json.txt`, o prompt que a aula 1
rodou quando pediu JSON pela primeira vez. Todo o resto é uma persona, três regras sobre o que não
fazer, com uma delas escrita duas vezes, e duas instruções sobre o resumo que discordam entre si. A
próxima seção trata dessas duas.

## Pago em toda chamada

O prompt vai inteiro com cada mensagem. **Seja lá quanto as instruções custem, você paga isso
quarenta vezes por quarenta mensagens e um milhão de vezes por um milhão.** O `pl` registra os
tokens e os segundos de cada chamada no arquivo da execução, e um programa curto os soma. Salve-o
como `stats.py`:

```python
"""stats: what each run cost, in tokens and in seconds."""
import statistics
import sys

from pl import read_jsonl


def pct(values, p):
    values = sorted(values)
    return values[min(len(values) - 1, int(p * len(values)))]


for path in sys.argv[1:]:
    rows = read_jsonl(path)
    tin = [r["tokens_in"] for r in rows]
    tout = [r["tokens_out"] for r in rows]
    secs = [r["seconds"] for r in rows]
    print("%s, %d calls" % (path, len(rows)))
    print("  tokens in    mean %6.1f   total %6d" % (statistics.mean(tin), sum(tin)))
    print("  tokens out   mean %6.1f   total %6d   max %d" % (statistics.mean(tout), sum(tout), max(tout)))
    print("  seconds      p50 %5.1f   p95 %5.1f   total %6.1f" % (pct(secs, .5), pct(secs, .95), sum(secs)))
```

Ele importa `read_jsonl` do `pl.py`, o que funciona porque os dois arquivos ficam no mesmo
diretório. Rode os dois prompts e compare:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl
40 calls, prompt 2b255df5, llama3.2:3b, written to runs/long.jsonl
ana@lab:~/triage$ python3 stats.py runs/v2.jsonl runs/long.jsonl
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.6   total   1225   max 38
  seconds      p50   3.3   p95   4.1   total  287.4
runs/long.jsonl, 40 calls
  tokens in    mean  203.2   total   8126
  tokens out   mean   33.6   total   1343   max 46
  seconds      p50   3.8   p95   5.2   total  157.0
```

A entrada foi de 106,2 tokens por chamada para 203,2. **Essa diferença, 97 tokens, são as
instruções a mais**, as mesmas em toda mensagem, diga a mensagem o que disser. A saída se mexeu bem
menos, de 30,6 para 33,6.

Os segundos pedem um aviso. A chamada mediana levou 3,3 segundos com o prompt curto e 3,8 com o
longo, e essa é a comparação a ler. Os totais apontam para o outro lado, 287,4 contra 157,0,
porque a primeira execução pagou para carregar o modelo na memória na primeira chamada e a segunda
não. **Um total que inclui um custo de uma vez só compara a ordem em que você rodou as coisas**, não
os prompts.

Na sua própria máquina, o preço de um token é tempo: um modelo lê cada token do prompt antes de
escrever uma palavra, e os 97 a mais custaram uns meio segundo por chamada aqui. Numa API paga é
dinheiro também. Os provedores cobram tokens de entrada e de saída separadamente, então multiplique
os totais pelos dois preços do seu provedor para ter o custo de uma execução. A forma é a mesma
seja quem for que venda: **uma instrução que não muda nada é paga em toda chamada, enquanto o prompt
estiver rodando.** A aula 16 faz essa conta para um pipeline inteiro, e a aula 17 mostra como um
cache barateia a parte fixa de um prompt.

## O que um leitor faz com o comprimento

O modelo não é o único leitor. Aqui está o prompt de novo, numerado:

```
ana@lab:~/triage$ cat -n prompts/v2-long.txt
     1	You are a helpful, friendly and professional assistant for Folio, an online bookshop.
     2	Your job is to read customer messages and sort them so the support team can answer them.
     3	
     4	Keep the summary brief so the team can scan the queue quickly.
     5	
     6	Answer in JSON with three fields:
     7	- "category": one of billing, delivery, returns, account, other
     8	- "urgency": one of low, normal, high
     9	- "summary": what the customer needs
    10	
    11	IMPORTANT: Do not make up information that is not in the message.
    12	Do not add fields that are not listed above.
    13	Never include the customer's name or email in the summary.
    14	IMPORTANT: Do not make up information that is not in the message.
    15	
    16	The team reads the summary instead of the message, so describe the problem in full detail.
    17	
    18	Message: {{message}}
```

A pessoa que abrir o `v2-long.txt` no mês que vem para resolver uma reclamação tem dezoito linhas
para segurar na cabeça, e precisa descobrir quais delas ainda importam. A linha 14 repete a linha
11 palavra por palavra. As linhas 11 e 14 estão em maiúsculas, o que diz a essa pessoa que elas
importam mais que a linha 13, e ninguém decidiu isso. **Toda linha de um prompt é uma afirmação de
que ela muda uma resposta**, e um leitor não tem como saber quais afirmações são verdadeiras a não
ser testando.
