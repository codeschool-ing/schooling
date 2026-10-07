---
title: Três coisas que toda requisição leva
version: 1
---

A aula 6 escolheu entre os modelos Claude; esta aula é a API pela qual todos eles respondem, a
**Messages API**, e a biblioteca `anthropic` que a chama. O api.anthropic.com é alcançável da máquina
em que este curso foi gravado, mas uma chave é uma conta que um curso não pode distribuir, então
quem responde abaixo é o substituto do lab, e o que a biblioteca manda é real.

O `lab/claude_sort.py` recebe um arquivo de prompt, um caso e um limite:

```python
import json
import sys

import anthropic

client = anthropic.Anthropic()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
prompt_file, case_id, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])

r = client.messages.create(model="standin-large", max_tokens=max_tokens,
                           system=open(prompt_file).read(),
                           messages=[{"role": "user", "content": cases[case_id]["text"]}])
print(repr(r.content[0].text), r.stop_reason, f"{r.usage.input_tokens} in, {r.usage.output_tokens} out")
```

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/triage.txt c05 16
'other' end_turn 51 in, 1 out
```

```
ana@desk:~/desk$ wire --headers anthropic-version,x-api-key,user-agent
POST /v1/messages
user-agent: Anthropic/Python 1.11.0
x-api-key: lab-anthropi…
anthropic-version: 2023-06-01

{
  "max_tokens": 16,
  "messages": [
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "model": "standin-large",
  "system": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

Três coisas diferem do formato da OpenAI. **`system` é um campo próprio**, não uma mensagem com
papel. **`max_tokens` é obrigatório**: toda requisição diz de que tamanho a resposta pode ser, onde
a Chat Completions tem um padrão. E dois cabeçalhos levam a conta e a versão: `x-api-key`, e
`anthropic-version`, que a documentação fixa numa data:

```
# https://platform.claude.com/docs/en/api/versioning, read 2026-10-05
 186: anthropic-version: 2023-06-01
```

O cabeçalho de versão é o que deixa a Anthropic mudar a API sem quebrar um programa escrito para um
formato mais antigo: o programa diz para que formato foi escrito.

## Por que parou

O `stop_reason` diz por que a resposta terminou. `end_turn` é o modelo terminando. O outro a conferir
é `max_tokens`, o limite atingido. O prompt de extração da ana, com espaço e depois sem:

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/extract.txt c01 64
'{"order": "LB-20417"}' end_turn 71 in, 9 out
```

```
ana@desk:~/desk$ python lab/claude_sort.py prompts/extract.txt c01 8
'{"order": "LB-20417' max_tokens 71 in, 8 out
```

Oito tokens cortaram o JSON ao meio, e a resposta continua sendo um 200 com texto dentro. **Um
programa que lê o texto sem ler o `stop_reason` tenta interpretar um objeto quebrado**, e numa
resposta em prosa, uma frase cortada parece uma frase curta. A seção 09 da aula 5 contou respostas ilegíveis como falhas;
esta é a mais barata de evitar: confira o `stop_reason`, e dimensione o `max_tokens` pela resposta
certa mais longa dos casos, com folga.
