---
title: Lendo uma execução de volta
version: 1
---

Um agente decide o caminho enquanto roda, então o único jeito de saber o que ele fez é ter anotado. O `react_native.py` acrescenta uma linha JSON por passo ao `trace.jsonl`, e o `show_trace.py` a imprime:

```python
"""Print trace.jsonl as one block per step: what the model said, what it called, what came back."""
import json

for line in open("trace.jsonl"):
    r = json.loads(line)
    print(f"step {r['step']}  stop_reason={r['stop_reason']}  input_tokens={r['input_tokens']}")
    print(f"  said:     {r['text'][:96]}")
    for c in r["calls"]:
        print(f"  called:   {c['tool']}({json.dumps(c['input'])})")
        print(f"  returned: {c.get('output', 'refused: ' + c.get('refused', ''))[:72]}")
```

Para a execução do M-1047 da seção 05:

```
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=184
  said:     I need the order's delivery date and total before I can answer.
  called:   get_order({"order_id": "M-1047"})
  returned: {"id": "M-1047", "customer_id": "c-106", "placed_on": "2026-09-15", "sta
step 2  stop_reason=tool_use  input_tokens=321
  said:     Delivered on 18 September, so the window runs to 18 October; now the refund rules.
  called:   search_help({"query": "refund after a return"})
  returned: [{"title": "When your refund arrives", "body": "We refund within three w
step 3  stop_reason=end_turn  input_tokens=544
  said:     Yes. Order M-1047 was delivered on 18 September 2026, so both copies can be returned until 18 Oc
```

Leia como você leria o raciocínio de qualquer pessoa. **Cada linha de `said` deve decorrer do `returned` acima dela.** A frase do passo 2 cita 18 de setembro, que está no resultado do passo 1; o prazo de reembolso do passo 3 está no resultado do passo 2. Um passo cujo pensamento menciona algo que nenhum resultado anterior contém é o primeiro lugar a olhar quando uma resposta está errada: é ali que o modelo forneceu um fato em vez de buscá-lo.

O `input_tokens` mostra como o custo cresceu: 184, 321, 544, cada pedido carregando todos os anteriores. O `stop_reason` diz por que cada passo terminou, e o último tem de dizer `end_turn` numa execução que terminou direito. Qualquer outra coisa na última linha, `max_tokens` ou uma mensagem do hospedeiro, é uma execução que foi cortada.

## O que um rastro deve guardar

Os campos são uma escolha, e estes são os que respondem às perguntas que as pessoas fazem depois:

- **o número do passo e por que ele terminou**, para que uma execução cortada apareça;
- **o que o modelo disse e o que chamou, com os argumentos exatos**, para que uma chamada errada seja ligada ao passo que a escolheu;
- **o que voltou**, truncado: os primeiros 80 caracteres aqui, o bastante para reconhecer o resultado sem copiar o pedido inteiro de um cliente para um log;
- **o tamanho do pedido**, para ler o custo por passo.

Um rastro também é dado sobre pessoas. Este guarda um id de pedido e o começo de um pedido, e um real guardaria mensagens de clientes. A aula 11 do `ai-security` é sobre o que guardar, redigir e apagar, e a regra que já vale aqui é registrar o necessário para explicar uma execução e nada mais. A aula 7 monta um rastro mais completo, com tempos, e a aula 18 transforma rastros nos números que uma equipe acompanha.
