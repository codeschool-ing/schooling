---
title: Um programa, qualquer servidor
version: 1
---

As duas ferramentas também respondem no formato da OpenAI, o mesmo que a seção 05 da aula 9 viu a
Mistral compartilhar. Então a biblioteca da OpenAI, apontada para outro endereço, fala com
qualquer uma. O `lab/two_servers.py` pergunta a cada servidor que modelo ele tem carregado e
classifica o mesmo caso com ele:

```python
import json

from openai import OpenAI

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

SERVERS = {"Ollama": ("http://127.0.0.1:11434/v1", "ollama"),
           "LM Studio": ("http://127.0.0.1:1234/v1", "lm-studio")}
for name, (url, key) in SERVERS.items():
    client = OpenAI(base_url=url, api_key=key)   # the library needs a key; neither server reads it here
    model = client.models.list().data[0].id
    r = client.chat.completions.create(model=model, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{name:9} {model:22} {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python lab/two_servers.py
Ollama    standin-local:latest   other
LM Studio standin-local          other
```

```
ana@desk:~/desk$ wire --count 4
GET /v1/models -> 200 ollama 
POST /v1/chat/completions -> 200 ollama standin-local
GET /v1/models -> 200 lmstudio 
POST /v1/chat/completions -> 200 lmstudio standin-local
```

Os mesmos caminhos, duas portas. As chaves são marcadores tirados dos exemplos de cada projeto, que
estão lá porque a biblioteca se recusa a começar sem uma. A documentação do Ollama chama o marcador
dela de "required but ignored"; o LM Studio só confere uma chave com o ajuste *Require
Authentication* ligado, que serve para quando o servidor é compartilhado. **O nome do
modelo é a única coisa que não é portátil**: o Ollama diz `standin-local:latest` onde o LM Studio
diz `standin-local`, e é por isso que o programa pergunta em vez de supor.

O formato também tem um custo, e a documentação do Ollama o declara:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

A API da OpenAI não tem `options`, então não há `num_ctx` para mandar. Pelo `/v1`, a janela é a que
o modelo recebeu quando foi criado, e mudá-la exige um Modelfile, a receita de modelo do Ollama, com
`PARAMETER num_ctx` dentro e um nome novo. **A portabilidade compra a parte comum e perde o resto**:
a verificação da seção 04 precisa do `prompt_eval_count`, que a API nativa devolve, e a aula 20 é
sobre exatamente essa troca em todo provedor que oferece o formato.
