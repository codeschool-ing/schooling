---
title: A API própria do Ollama
version: 1
---

O Ollama tem uma biblioteca Python oficial, a `ollama`, e o `lab/local_chat.py` a usa para
classificar um dos casos da ana com o prompt de triagem da aula 1:

```python
import json

import ollama

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = ollama.chat(model="standin-local", options={"temperature": 0},
                messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(f"{case['id']}: {r.message.content}   (a person said {case['label']})")
print(f"read {r.prompt_eval_count} tokens, wrote {r.eval_count}")
print(f"{r.eval_count / r.eval_duration * 1e9:.1f} tokens/s while writing, {r.total_duration / 1e9:.2f} s in all")
```

```
ana@desk:~/desk$ python lab/local_chat.py
c05: other   (a person said other)
read 51 tokens, wrote 1
20.0 tokens/s while writing, 0.95 s in all
```

A resposta é do substituto, tirada da tabela dele, e as durações também: o `standin-local` tem 0,9
segundo antes do primeiro token e 50 milissegundos por token depois. O que é real é o formato.
**Toda resposta traz a própria contabilidade**: quantos tokens foram lidos (`prompt_eval_count`),
quantos escritos (`eval_count`) e quanto tempo cada parte levou, em nanossegundos. A linha de
tokens por segundo é a fórmula que a documentação do Ollama dá, e é a vazão da seção 05 da aula 3
medida no seu hardware em vez de calculada a partir de uma largura de banda.

O que foi pelo fio é JSON simples para `localhost`, sem chave:

```
ana@desk:~/desk$ wire --headers user-agent
POST /api/chat
user-agent: ollama-python/0.6.3 (x86_64 linux) Python/3.11.15

{
  "model": "standin-local",
  "stream": false,
  "options": {
    "temperature": 0
  },
  "messages": [
    {
      "role": "system",
      "content": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
    },
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "tools": []
}
```

Os ajustes que uma API põe no nível de cima, o Ollama põe em `options`: `temperature` aqui, e
`num_ctx` na seção 04.

## Carregado, e por quanto tempo

Um modelo local precisa estar na memória para responder, e carregar gigabytes de pesos do disco
leva tempo, que a primeira requisição paga. O Ollama mantém o modelo carregado depois de uma requisição, e diz até quando:

```
ana@desk:~/desk$ python -c "import ollama; [print(m.model, m.expires_at) for m in ollama.ps().models]"
standin-local:latest 2026-10-05 18:13:34-03:00
```

```
ana@desk:~/desk$ sources quote ollama-faq "By default models are kept in memory"
# ollama/ollama@42e911bc docs/faq.mdx
 291: By default models are kept in memory for 5 minutes before being unloaded. This allows
      for quicker response times if you're making numerous requests to the LLM. If you want to
      immediately unload a model from memory, use the `ollama stop` command:
```

Cinco minutos depois da última requisição, a memória é devolvida. O `keep_alive` numa requisição
muda isso: uma duração o mantém por mais tempo, um número negativo como `-1` o mantém carregado, e
`0` o descarrega na hora:

```
ana@desk:~/desk$ python -c "import ollama; print(ollama.generate(model=\"standin-local\", keep_alive=0).done_reason); print(len(ollama.ps().models), \"models loaded\")"
unload
0 models loaded
```

Para a mesa da ana a troca é a da aula 3: um modelo mantido carregado responde o primeiro e-mail da
manhã tão rápido quanto o centésimo, e segura a memória a noite inteira para isso.

## Local é uma propriedade de onde roda

```
ana@desk:~/desk$ sources quote ollama-faq "Ollama runs locally"
# ollama/ollama@42e911bc docs/faq.mdx
 161: Ollama runs locally. We don't see your prompts or data when you run locally. When using
      cloud-hosted models, we process your prompts and responses to provide the service but do
      not store or log that content and never train on it. We collect basic account info and
      limited usage metadata to provide the service that does not include prompt or response
      content. We don't sell your data. You can delete your account anytime.
```

**Quando roda localmente.** A mesma documentação descreve modelos hospedados na nuvem, e um endpoint
compatível com a OpenAI em ollama.com que não precisa de instalação nenhuma:

```
ana@desk:~/desk$ sources quote ollama-openai "No Ollama installation required|base_url=\"https://ollama.com"
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
   9: Set your [API key](https://ollama.com/settings/keys) in `OLLAMA_API_KEY`. Install the
      client with `pip install openai`. No Ollama installation required.
  16: base_url="https://ollama.com/v1",
```

Então *usamos o Ollama* só responde a pergunta da seção 07 da aula 2 depois de uma segunda: para que
endereço o programa manda? `localhost:11434` mantém o e-mail na máquina; `ollama.com` o manda a um
provedor, nos termos desse provedor, como qualquer API das aulas 6 a 9.
