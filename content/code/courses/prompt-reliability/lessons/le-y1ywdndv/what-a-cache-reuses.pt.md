---
title: O que um cache reaproveita
version: 2
---

A palavra sugere a coisa errada. Um cache de prompt não guarda respostas, e não se lembra de uma
conversa anterior. **Ele guarda o trabalho de ler o começo de um prompt**, para que a próxima chamada
que comece exatamente com os mesmos tokens possa pular essa parte. A resposta continua sendo escrita
do zero toda vez.

A maior parte de um prompt de produção é igual em toda chamada. O prompt que esta aula usa é o
`v8-guide.txt` da aula 5: um guia longo das categorias seguido da mensagem de um cliente, e só a
mensagem muda. Um cache é um jeito de não ler o guia de novo em toda chamada.

## O cache do Ollama

O Ollama mantém um. Ele guarda os prompts que leu recentemente e, quando chega um pedido, procura
entre eles o que tem o começo mais longo em comum com o prompt novo, token por token desde o início,
e reaproveita o trabalho desse trecho. Nada precisa ser ligado, e nada numa resposta diz que isso
aconteceu, a não ser o tempo. O Ollama relata esse tempo em toda resposta, dividido em dois: quanto
levou para ler o prompt e quanto para escrever a resposta. O `pl` só guarda o total, então este
programa pergunta direto ao Ollama e imprime as duas metades para as primeiras mensagens de um
conjunto de teste. Salve-o como `timing.py`:

```python
"""timing: where each call's time went, as Ollama reports it: reading the
prompt, and writing the reply."""
import json
import sys
import urllib.request

from pl import DEFAULTS, OLLAMA, read_jsonl, read_prompt, render, values_of

prompt_path, cases_path = sys.argv[1], sys.argv[2]
count = int(sys.argv[3]) if len(sys.argv) > 3 else 5
params, template = read_prompt(prompt_path)
params = {**DEFAULTS, **params}
options = {k: float(v) if "." in v else int(v) for k, v in params.items() if k != "model"}
print("case  read tokens  read ms  wrote tokens  write ms")
for case in read_jsonl(cases_path)[:count]:
    body = {"model": params["model"], "stream": False, "options": options,
            "messages": [{"role": "user", "content": render(template, values_of(case, {}))}]}
    req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    r = json.load(urllib.request.urlopen(req, timeout=600))
    print("%-5s %11d %8.0f %13d %9.0f" % (case["id"], r["prompt_eval_count"],
                                         r["prompt_eval_duration"] / 1e6,
                                         r["eval_count"], r["eval_duration"] / 1e6))
```

`prompt_eval_duration` e `eval_duration` são os nomes que o Ollama dá às duas metades, em
nanossegundos; o programa imprime milissegundos. Aqui estão as cinco primeiras mensagens do dev com o
`v8-guide.txt`, num Ollama recém-iniciado, sem nada no cache ainda:

```
ana@lab:~/triage$ python3 timing.py prompts/v8-guide.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287     5009            28      3129
t02           288      813            29      3148
t03           288      780            32      3686
t04           284      669            32      3376
t05           285      746            27      2932
```

A primeira chamada leu 287 tokens em 5009 milissegundos. As quatro seguintes leram o mesmo número de
tokens entre 669 e 813: **a contagem é a mesma e o trabalho não**, porque só a mensagem no fim era
nova. Os 287 da coluna `read tokens` são o que um provedor hospedado cobraria, e o que o `pl` registra
como `tokens_in`; é no tempo que o cache aparece.

A metade da escrita não mexeu, uns três segundos por chamada, porque o cache só mexe no prompt. E ele
não dura: o `ollama ps` da aula 1 dizia que o modelo ficaria na memória *4 minutes from now*. Depois de
cinco minutos ocioso, o Ollama o descarrega, com cache e tudo, e a próxima chamada lê o prompt
inteiro de novo.

## Caches reais

Provedores hospedados também guardam um prefixo, e **todo detalhe que importa é deles**: o menor
prompt que eles guardam, quanto tempo um prefixo sem uso fica, e quanto custa ler e escrever nele.
Alguns aplicam o cache automaticamente a qualquer prompt longo o bastante; a documentação de prompt
caching da OpenAI descreve assim. Outros só guardam até onde você marca o fim do prefixo: a
documentação da Anthropic manda pôr um marcador `cache_control` no pedido. Antes de contar com um
cache, **leia a documentação do seu provedor para o modelo que você chama**, e meça o que ele relata.

O que todas as versões têm em comum é a regra desta aula: o cache casa a partir do começo do prompt,
então o que vem primeiro decide o que pode ser reaproveitado.
