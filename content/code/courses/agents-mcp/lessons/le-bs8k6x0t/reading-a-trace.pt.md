---
title: Lendo uma execução de volta
version: 2
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
step 1  stop_reason=tool_use  input_tokens=274
  said:     
  called:   search_help({"query": "returning books order M-1047 refund"})
  returned: [{"title": "How to return a book", "body": "You have 30 days from delive
step 2  stop_reason=end_turn  input_tokens=322
  said:     To return the books in order M-1047, you have 30 days from delivery to return the printed books 
```

Leia como você leria o raciocínio de qualquer pessoa. **Cada linha de `said` deve decorrer do `returned` acima dela.** O passo 1 não disse nada e buscou com o id do pedido dentro da consulta, `returning books order M-1047 refund`, como se a central de ajuda soubesse de pedidos. O passo 2 respondeu a partir do artigo de devoluções que recebeu. Nada no rastro menciona 18 de setembro, porque nenhum passo foi buscar essa data, e essa é a resposta para "por que ele não disse se estes livros podem voltar". Um passo cuja resposta menciona algo que nenhum resultado anterior contém é o primeiro lugar a olhar quando uma resposta está errada: é ali que o modelo forneceu um fato em vez de buscá-lo.

O `input_tokens` mostra como o custo cresceu: 274, depois 322, o segundo pedido carregando o primeiro mais a chamada e o resultado dela. É o prompt inteiro: o Ollama informa à parte o trecho que tinha em cache, e o `react_native.py` soma os dois de volta. O `stop_reason` diz por que cada passo terminou, e o último tem de dizer `end_turn` numa execução que terminou direito. Qualquer outra coisa na última linha, `max_tokens` ou uma mensagem do hospedeiro, é uma execução que foi cortada.

## O que um rastro deve guardar

Os campos são uma escolha, e estes são os que respondem às perguntas que as pessoas fazem depois:

- **o número do passo e por que ele terminou**, para que uma execução cortada apareça;
- **o que o modelo disse e o que chamou, com os argumentos exatos**, para que uma chamada errada seja ligada ao passo que a escolheu;
- **o que voltou**, truncado: os primeiros 80 caracteres aqui, o bastante para reconhecer o resultado sem copiar o pedido inteiro de um cliente para um log;
- **o tamanho do pedido**, para ler o custo por passo.

Um rastro também é dado sobre pessoas. Este guarda um id de pedido e o começo de um pedido, e um real guardaria mensagens de clientes. A aula 11 do `ai-security` é sobre o que guardar, redigir e apagar, e a regra que já vale aqui é registrar o necessário para explicar uma execução e nada mais. A aula 7 monta um rastro mais completo, com tempos, e a aula 18 transforma rastros nos números que uma equipe acompanha.
