---
title: Tokens, não palavras
version: 2
---

Toda configuração de tamanho que um modelo oferece conta tokens, e **um token não é uma palavra**.
`prompt-engineering` apresentou tokens na aula 3 e o limite de saída na aula 15. Esta aula retoma o
limite de propósito, com uma pergunta mais estreita: o que um corte faz com uma resposta que um
programa precisa ler.

Para contar tokens você precisa do tokenizador do próprio modelo, a peça que transforma texto nos
pedaços numerados que o modelo lê. O Ollama não tem um comando que só conte, mas toda resposta
informa quantos tokens o modelo leu, então um programa curto consegue mandar um texto e ler a
contagem de volta. Salve-o como `tokens.py`:

```python
"""tokens: how many tokens the model's own tokeniser makes of a text."""
import json
import sys
import urllib.request

from pl import DEFAULTS, OLLAMA


def count(text):
    # Ollama has no endpoint that only counts, so this sends the text raw, with
    # no chat template around it, asks for one token back, and reads how many
    # tokens the model had to read. That count includes the one token the model
    # puts at the start of every text, so it is taken off.
    body = {"model": DEFAULTS["model"], "prompt": text, "raw": True, "stream": False,
            "options": {"num_predict": 1}}
    req = urllib.request.Request(OLLAMA + "/api/generate", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))["prompt_eval_count"] - 1


text = sys.stdin.read() if sys.argv[1:] == ["-"] else open(sys.argv[1], encoding="utf-8").read()
print("%d tokens, %d words, %d characters" % (count(text), len(text.split()), len(text)))
```

Ele recebe um arquivo, ou `-` para o que vier por um pipe:

```
ana@lab:~/triage$ python3 tokens.py prompts/v4-only-json.txt
85 tokens, 59 words, 362 characters
ana@lab:~/triage$ echo 'They were charged twice for order 4471.' | python3 tokens.py -
10 tokens, 7 words, 40 characters
ana@lab:~/triage$ echo '{"summary": "They were charged twice for order 4471."}' | python3 tokens.py -
15 tokens, 8 words, 55 characters
```

A frase tem sete palavras e dez tokens: o `echo` acrescenta uma quebra de linha, que é um token, e o
tokenizador do `llama3.2:3b` parte o número do pedido em pedaços. Ponha a mesma frase dentro de um
campo JSON e ela chega a quinze: as chaves, os dois-pontos, as aspas e o nome do campo também são
tokens, embora o tokenizador junte alguns deles com os vizinhos.

**Cada modelo parte o texto do seu jeito, e um provedor cobra pela sua própria contagem.** Palavras
comuns tendem a ser um token, palavras raras ou longas são partidas em pedaços, e a pontuação muitas
vezes se junta ao que está ao lado. Então essas contagens são do `llama3.2:3b` e não são a conta de
ninguém. O que vale em qualquer lugar é a proporção de que esta aula trata: numa resposta JSON, uma
parte grande do que o modelo escreve é estrutura.

## Para onde vão os tokens de uma resposta

Aqui está uma resposta do prompt que pede o objeto JSON e mais nada:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 4471"}
stop: stop, tokens in 123, out 28, 3.5 s
```

O `out 28` é o tamanho dessa resposta em tokens. O resumo, a parte que uma pessoa lê, é a minoria
deles. O resto é a moldura: nomes de campo, rótulos e pontuação.

Essa proporção decide duas coisas no resto desta aula. **Um limite escolhido pensando em quanto um
resumo deveria ter vai ficar pequeno demais**, porque o resumo é só parte da resposta. E pedir um
resumo mais curto mexe no total menos do que você esperaria, porque a moldura não encolhe quando a
frase encolhe.
