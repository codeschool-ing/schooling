---
title: Três coisas que toda requisição leva
version: 1
---

A aula 6 escolheu entre os modelos Claude; esta aula é a API pela qual todos eles respondem, a
**Messages API**, e a biblioteca `anthropic` que a chama. O api.anthropic.com é alcançável da
máquina em que este curso foi gravado, mas uma chave é uma conta que um curso não pode distribuir. O
Ollama fala o mesmo formato em `/v1/messages`, e a seção 04 da aula 1 já apontou o
`ANTHROPIC_BASE_URL` para ele, então as respostas abaixo são do llama3.2:3b e o que a biblioteca
manda é exatamente o que ela mandaria à Anthropic. Onde o Ollama se comporta diferente do que a
Anthropic documenta, a seção diz.

Todo programa desta aula passa pelo relay da seção 03 da aula 9, para que o que a biblioteca manda
possa ser lido de volta. Suba o relay num segundo terminal e, no terminal em que você trabalha,
mande as duas bibliotecas para ele:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

O `claude_sort.py` recebe um arquivo de prompt, um caso e um limite:

```python
import json
import sys

import anthropic

client = anthropic.Anthropic()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
prompt_file, case_id, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])

r = client.messages.create(model="llama3.2:3b", max_tokens=max_tokens,
                           system=open(prompt_file).read(),
                           messages=[{"role": "user", "content": cases[case_id]["text"]}])
print(repr(r.content[0].text), r.stop_reason, f"{r.usage.input_tokens} in, {r.usage.output_tokens} out")
```

```
ana@desk:~/desk$ python claude_sort.py prompts/triage.txt c05 16
'other.' end_turn 19 in, 3 out
```

```
ana@desk:~/desk$ python relay.py show --headers anthropic-version,x-api-key,user-agent
POST /v1/messages
user-agent: Anthropic/Python 1.11.0
x-api-key: ollama…
anthropic-version: 2023-06-01

{
  "max_tokens": 16,
  "messages": [
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "model": "llama3.2:3b",
  "system": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

Seu rótulo pode sair outro: a biblioteca não define temperatura, então o modelo sorteia. Três
coisas diferem do formato da OpenAI. **`system` é um campo próprio**, não uma mensagem com papel.
**`max_tokens` é obrigatório**: toda requisição diz de que tamanho a resposta pode ser, onde a Chat
Completions tem um padrão. E dois cabeçalhos levam a conta e a versão: `x-api-key`, que aqui leva o
valor de mentira `ollama` do `desk.env` e na Anthropic leva a chave, e `anthropic-version`, que a
documentação fixa numa data:

```
# https://platform.claude.com/docs/en/api/versioning, read 2026-10-07
 186: anthropic-version: 2023-06-01
```

O cabeçalho de versão é o que deixa a Anthropic mudar a API sem quebrar um programa escrito para um
formato mais antigo: o programa diz para que formato foi escrito.

## Por que parou

O `stop_reason` diz por que a resposta terminou. `end_turn` é o modelo terminando. O outro a
conferir é `max_tokens`, o limite atingido. O prompt de extração da ana, com espaço e depois sem:

```
ana@desk:~/desk$ python claude_sort.py prompts/extract.txt c01 64
'{"order": "LB-20417"}' end_turn 79 in, 10 out
```

```
ana@desk:~/desk$ python claude_sort.py prompts/extract.txt c01 8
'{"order": "LB-20417' max_tokens 1 in, 8 out
```

Oito tokens cortaram o JSON ao meio, e a resposta continua sendo um 200 com texto dentro. **Um
programa que lê o texto sem ler o `stop_reason` tenta interpretar um objeto quebrado**, e numa
resposta em prosa, uma frase cortada parece uma frase curta. A seção 09 da aula 5 contou respostas
ilegíveis como falhas; esta é a mais barata de evitar: confira o `stop_reason`, e dimensione o
`max_tokens` pela resposta certa mais longa dos casos, com folga.

A coluna `in` muda por um motivo que a seção 04 explica: o Ollama guarda o que já leu, e o
`input_tokens` conta só o que ele teve de ler de novo.
