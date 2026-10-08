---
title: O que a divisão custou
version: 2
---

O `tally.py` lê o `requests.jsonl` do gravador e soma pedidos e tokens por agente, distinguindo os agentes por uma frase do prompt de sistema de cada um. O arquivo foi apagado antes de cada execução.

```python
"""Requests and tokens since requests.jsonl was emptied, per agent, told apart by their system prompts."""
import json
from collections import defaultdict

WHO = {"orchestrator": "orchestrator", "orders specialist": "orders", "catalogue specialist": "catalogue",
       "triage agent": "triage", "working alone": "agent"}
rows = defaultdict(lambda: [0, 0, 0])
for line in open("requests.jsonl"):
    r = json.loads(line)
    who = next(name for key, name in WHO.items() if key in (r["request"].get("system") or ""))
    rows[who][0] += 1
    rows[who][1] += r["usage"]["input_tokens"]
    rows[who][2] += r["usage"]["output_tokens"]
for who, (n, i, o) in rows.items():
    print(f"{who:13} requests {n}   input {i:5}   output {o:4}")
print(f"{'total':13} requests {sum(v[0] for v in rows.values())}   input {sum(v[1] for v in rows.values()):5}   "
      f"output {sum(v[2] for v in rows.values()):4}")
```

Para a execução orquestrada da seção 04:

```
ana@lab:~/agents$ python tally.py
orchestrator  requests 2   input   499   output   88
orders        requests 2   input   523   output   45
catalogue     requests 2   input   413   output   59
total         requests 6   input  1435   output  192
```

E para a mesma pergunta respondida por um agente com as três ferramentas:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?" --single
agent -> get_order({"order_id": "M-1043"})
agent -> find_books({"genre": "science fiction"})
agent: Your order M-1043 has shipped. The tracking number is BR5512340003. As for a science fiction book recommendation, I suggest "The Time Machine" by H. G. Wells, which is currently in stock.
ana@lab:~/agents$ python tally.py
agent         requests 2   input   714   output   79
total         requests 2   input   714   output   79
```

O agente único pediu as duas ferramentas numa resposta e respondeu no segundo pedido: **2 pedidos e 714 tokens de entrada, contra 6 pedidos e 1435**. E respondeu às duas perguntas, enquanto a execução orquestrada perdeu o livro. Nesta pergunta a divisão não comprou nada e custou o triplo de pedidos; para justificar esse custo, as respostas dela teriam de ser melhores, e aqui foram piores.

De onde vem o custo extra aparece na tabela. Cada especialista pagou pelo próprio prompt de sistema e pelas próprias definições de ferramenta duas vezes, uma por pedido. O orquestrador pagou para mandar as duas perguntas e para ler as duas respostas. **Nenhum desse trabalho respondeu ao cliente**; é o preço da fronteira.

## Quando a conta vira

Para esta pergunta a divisão é custo puro: duas ferramentas, duas consultas, uma conversa curta. O equilíbrio muda conforme o trabalho cresce:

- Quando cada parte leva muitos passos, a conversa de um especialista continua curta enquanto a de um agente único cresce com os resultados de todas as partes, e a aula 1 mostrou que cada pedido reenvia a conversa inteira. Dez passos de pesquisa de livros dentro do agente único seriam pagos de novo a cada consulta de pedido seguinte; dentro de um especialista, só ali.
- Quando as partes podem rodar ao mesmo tempo e cada uma demora, o orquestrador espera o especialista mais lento em vez da soma.
- Quando as ferramentas precisam de permissões diferentes, a divisão não tem nada a ver com custo (aula 17).

Meça a tarefa que você tem. Uma divisão escolhida porque parece um organograma sensato é um custo sem evidência por trás.
