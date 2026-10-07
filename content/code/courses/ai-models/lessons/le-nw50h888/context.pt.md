---
title: A janela que você não ajustou
version: 1
---

A seção 07 da aula 4 comparou modelos pela janela de contexto que os autores publicam. Um servidor
local acrescenta um segundo número, a janela que **ele** dá ao modelo, e essa é um ajuste:

```
# ollama/ollama@42e911bc docs/faq.mdx
  25: By default, Ollama uses a context window size of 4096 tokens.
```

Quatro mil tokens, seja qual for o tamanho para o qual o modelo foi treinado. Uma conversa maior que
isso não falha. O `lab/context.py` manda o prompt de triagem, trinta e nove casos da ana como
exemplos resolvidos (cada e-mail e o rótulo que uma pessoa deu a ele) e o quadragésimo como
pergunta, três vezes, com três valores de `num_ctx`:

```python
import json

import ollama

prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# every other case as a worked example, then the last one as the question
messages = [{"role": "system", "content": prompt}]
for c in cases[:39]:
    messages += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
messages.append({"role": "user", "content": cases[39]["text"]})

for num_ctx in (None, 1024, 512):
    options = {"temperature": 0} | ({"num_ctx": num_ctx} if num_ctx else {})
    r = ollama.chat(model="standin-local", messages=messages, options=options)
    print(f"num_ctx {num_ctx or 'unset':>5}: sent {len(messages)} messages, "
          f"the model read {r.prompt_eval_count:>4} tokens -> {r.message.content}")
```

```
ana@desk:~/desk$ python lab/context.py
num_ctx unset: sent 80 messages, the model read 1124 tokens -> order-status
num_ctx  1024: sent 80 messages, the model read 1016 tokens -> order-status
num_ctx   512: sent 80 messages, the model read  511 tokens -> order-status
```

Sem ajuste, os 1.124 tokens cabem no padrão e o modelo leu todos. Com 1.024 e 512 ele leu menos, e
**a resposta voltou como se nada tivesse acontecido**: um rótulo, um 200, nenhum aviso. O que o
substituto faz para caber é descartar as mensagens mais antigas e manter o prompt de sistema e a
pergunta; um servidor de verdade tem a própria regra. De um jeito ou de outro, os exemplos que
deviam ensinar os rótulos ao modelo em parte não estavam lá, e nada na resposta disse isso.

A defesa é o número que a resposta já traz. **`prompt_eval_count` é o que o modelo leu**, contado
pelo servidor com o tokenizador do próprio modelo. Compare com a mesma requisição numa janela
sabidamente grande o bastante, como a primeira linha faz: se ficar abaixo, algo foi cortado. O
substituto conta os tokens de todo modelo com um tokenizador só, o `o200k_base` da OpenAI, então os
números dele não são os que uma Llama ou uma Qwen contariam, mas a comparação funciona igual com qualquer um.

E lembre do preço: a seção 03 da aula 3 mostrou que o cache cresce a cada token de contexto, então
um `num_ctx` maior é mais memória, e a documentação do Ollama acrescenta que requisições paralelas
o multiplicam.
