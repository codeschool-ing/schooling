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
isso não falha. O `context.py` manda o prompt de triagem, trinta e nove casos da ana como
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
    r = ollama.chat(model="llama3.2:3b", messages=messages, options=options)
    print(f"num_ctx {num_ctx or 'unset':>5}: sent {len(messages)} messages, "
          f"the model read {r.prompt_eval_count:>4} tokens -> {r.message.content}")
```

```
ana@desk:~/desk$ python context.py
num_ctx unset: sent 80 messages, the model read 1319 tokens -> order-status
num_ctx  1024: sent 80 messages, the model read 1014 tokens -> order-status
num_ctx   512: sent 80 messages, the model read  505 tokens -> order-status
```

Sem ajuste, os 1.319 tokens cabem no padrão e o modelo leu todos. Com 1.024 e 512 ele leu menos, e
**a resposta voltou como se nada tivesse acontecido**: um rótulo, um 200, nenhum aviso. O Ollama
descartou parte das mensagens para caber, e a resposta não diz quais: os exemplos que deviam
ensinar os rótulos ao modelo em parte não estavam lá.

A defesa é o número que a resposta já traz. **`prompt_eval_count` é o que o modelo leu**, contado
pelo servidor com o tokenizador do próprio modelo. Compare com a mesma requisição numa janela
sabidamente grande o bastante, como a primeira linha faz: se ficar abaixo, algo foi cortado.

E lembre do preço: a seção 03 da aula 3 mostrou que o cache cresce a cada token de contexto, então
um `num_ctx` maior é mais memória, e a documentação do Ollama acrescenta que requisições paralelas
o multiplicam.
