---
title: Um programa, qualquer servidor
version: 1
---

As duas ferramentas também respondem no formato da OpenAI, o mesmo que a seção 05 da aula 9 viu a
Mistral compartilhar. Então a biblioteca da OpenAI, apontada para outro endereço, fala com
qualquer uma. O `two_servers.py` pergunta a cada servidor que modelos ele tem e
classifica o mesmo caso com um deles:

```python
import json

from openai import OpenAI, APIConnectionError

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

SERVERS = {"Ollama": ("http://127.0.0.1:11434/v1", "ollama"),
           "LM Studio": ("http://127.0.0.1:1234/v1", "lm-studio")}
for name, (url, key) in SERVERS.items():
    # the library needs a key; neither server reads it here
    client = OpenAI(base_url=url, api_key=key, max_retries=0)
    try:
        models = [m.id for m in client.models.list().data]
    except APIConnectionError:
        print(f"{name:9} nothing is listening at {url}")
        continue
    model = "llama3.2:3b" if "llama3.2:3b" in models else models[0]
    r = client.chat.completions.create(model=model, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{name:9} {len(models)} models, among them {model}: {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python two_servers.py
Ollama    3 models, among them llama3.2:3b: other.
LM Studio nothing is listening at http://127.0.0.1:1234/v1
```

**O mesmo caminho, duas portas**, e na máquina em que este curso foi gravado só uma respondeu: não
havia LM Studio lá, e o programa diz isso em vez de parar, porque `APIConnectionError` é o que a
biblioteca levanta quando ninguém está escutando. Com o LM Studio rodando e o servidor dele ligado,
a segunda linha também é um caso classificado.

As chaves são marcadores tirados dos exemplos de cada projeto, que estão lá porque a biblioteca se
recusa a começar sem uma. A documentação do Ollama chama o marcador dela de "required but ignored";
o LM Studio só confere uma chave com o ajuste *Require Authentication* ligado, que serve para quando
o servidor é compartilhado. **O nome do modelo é a única coisa que não é portátil**: cada servidor
lista o que tem com os próprios nomes, e é por isso que o programa pede a lista em vez de supor um.

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
