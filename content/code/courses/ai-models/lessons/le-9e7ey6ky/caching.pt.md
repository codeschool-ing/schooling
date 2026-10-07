---
title: Um cache que você precisa conferir
version: 1
---

A seção 05 da aula 6 leu quanto custa o cache de prompt: gravar um prefixo em cache custa um quarto
a mais que a entrada comum, ler de volta custa um décimo, e abaixo de um tamanho mínimo nada vai
para o cache. Aqui está como uma requisição pede o cache, e como saber se conseguiu. A documentação
é direta sobre a segunda parte:

```
# https://platform.claude.com/docs/en/build-with-claude/prompt-caching, read 2026-10-07
 792: Shorter prompts cannot be cached, even if marked with
 794: . Any requests to cache fewer than this number of tokens will be processed without
      caching, and no error is returned. To verify whether a prompt was cached, check the
```

Uma requisição marca o fim do prefixo que quer em cache com `cache_control` num bloco. O
`cache.py` manda o prompt de triagem da ana marcado assim, depois o mesmo prompt com trinta e
nove exemplos resolvidos acrescentados, duas vezes. O Ollama guarda na memória o que o modelo leu
por último, então a execução começa descarregando o modelo, o que a esvazia:

```python
import json

import anthropic

client = anthropic.Anthropic()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
examples = "".join(f"E-mail: {c['text']}\nLabel: {c['label']}\n\n" for c in cases[:39])


def sort(system, label):
    r = client.messages.create(
        model="llama3.2:3b", max_tokens=16,
        system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": cases[39]["text"]}])
    u = r.usage
    print(f"{label:22} written {u.cache_creation_input_tokens!s:>4}  read {u.cache_read_input_tokens!s:>4}  "
          f"uncached {u.input_tokens:3}  -> {r.content[0].text}")


sort(prompt, "prompt alone")
sort(prompt + "\nExamples:\n\n" + examples, "with 39 examples")
sort(prompt + "\nExamples:\n\n" + examples, "the same, again")
```

```
ana@desk:~/desk$ ollama stop llama3.2:3b
ana@desk:~/desk$ python cache.py
prompt alone           written None  read    0  uncached  82  -> order-status
with 39 examples       written None  read   50  uncached 1117  -> Label: order-status
the same, again        written None  read 1166  uncached   1  -> Label: order-status
```

Deixe de fora o `ollama stop` e a primeira linha muda, porque a execução começa com a memória do
modelo já cheia. Três linhas, e ao lado de cada uma, o que a Anthropic documenta para as mesmas
requisições ao Sonnet 4.5, cujo mínimo é de 1.024 tokens:

- **O prompt sozinho**, 82 tokens, não leu nada do cache. A Anthropic também não guardaria nada,
  porque 82 está abaixo do mínimo, e a requisição daria certo ao preço comum de entrada. Esse é o
  caso silencioso de que a documentação avisa.
- **Com os exemplos**, o Ollama leu 50 tokens do cache: o começo do prompt de triagem, que a
  primeira requisição tinha deixado na memória. O Ollama não tem mínimo. A Anthropic não leria nada
  aqui, porque esses 50 tokens nunca foram um prefixo em cache, e **gravaria** os 1.100 e poucos
  tokens novos ao preço de gravação. O Ollama também não tem preço de gravação: `written` é `None`
  em todas as linhas.
- **O mesmo de novo**, e 1.166 de 1.167 tokens vieram do cache. A Anthropic também leria o prefixo
  de volta, a um décimo do preço de entrada, por cinco minutos depois do último uso.

Então o mesmo programa, com a mesma marca, encontra dois caches diferentes. **O Ollama reaproveita
qualquer prefixo que ainda tenha**, com ou sem `cache_control`, e só informa leituras. **A
Anthropic guarda o que a requisição marca, acima de um mínimo, e cobra a gravação.** O número a
conferir é o mesmo nos dois: `cache_read_input_tokens`. Repare também no que `input_tokens` quer
dizer: só os tokens que **não** vieram do cache, e é por isso que a coluna `in` da seção 02 mudou
entre execuções. O total lido pelo modelo é a soma dos números, e um relatório de custo que usasse
só o `input_tokens` contaria a menos toda requisição com cache.

Quanto isso vale aos preços do Sonnet 4.5, na entrada:

```
ana@desk:~/desk$ python sheet.py show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "
cache_creation_input_token_cost            3.75e-06
cache_read_input_token_cost                3e-07
input_cost_per_token                       3e-06
prompt_cache_min_tokens                    1024
```

```
ana@desk:~/desk$ python -c "print(f\"uncached {1167 * 3e-6 * 1000:.2f}  cached {(1166 * 3e-7 + 1 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"
uncached 3.50  cached 0.35  dollars per 1,000 e-mails, input only
```

Essa é a divisão do Ollama aos preços do Sonnet 4.5; o Claude conta tokens com o próprio
tokenizador, então os números seriam outros e o que se mantém é a proporção. Dez vezes mais barato
na entrada, para o prompt longo. Sem cache, os exemplos fazem cada requisição custar catorze vezes
o prompt sozinho, US$ 3,50 por mil e-mails contra US$ 0,25; com cache, cerca de uma vez e meia,
US$ 0,35.

Se os exemplos melhoram a *classificação* é pergunta da aula 5, não do cache, e esta execução dá
uma pista: com eles, o modelo copiou o formato e respondeu `Label: order-status`, que a pontuação da
aula 5 contaria como erro. **Um cache deixa um prompt longo barato; não o deixa certo.** E na
Anthropic a vida de cinco minutos quer dizer que uma mesa que recebe um e-mail a cada poucos
minutos mantém o cache quente, enquanto uma noite tranquila o deixa expirar e paga a gravação de
novo de manhã.
