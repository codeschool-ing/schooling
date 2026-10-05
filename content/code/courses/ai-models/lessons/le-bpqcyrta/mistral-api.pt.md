---
title: Chamando a Mistral
version: 1
---

A Mistral tem o próprio SDK em Python, `mistralai`, na versão 3.0.0 no laboratório. O
`lab/mistral_sort.py` manda o prompt de classificação da ana e um e-mail por ele:

```python
import os

from mistralai.client import Mistral

client = Mistral(api_key=os.environ["MISTRAL_API_KEY"], server_url=os.environ["MISTRAL_SERVER_URL"])
r = client.chat.complete(model="standin-small", messages=[
    {"role": "system", "content": open("prompts/triage.txt").read()},
    {"role": "user", "content": "Hello, where is my parcel? LB-20488"}])
print(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens)
```

```
ana@desk:~/desk$ python lab/mistral_sort.py
order-status 50 2
```

A resposta, `order-status`, é a tabela do substituto, como em todo o curso; o 50 e o 2 são as
contagens de tokens dele. A parte interessante é o que o SDK pôs no fio, que o `wire` imprime a partir
do log do substituto:

```
ana@desk:~/desk$ wire --headers user-agent,authorization
POST /v1/chat/completions
user-agent: mistral-client-python/3.0.0
authorization: Bearer lab-m…

{
  "model": "standin-small",
  "messages": [
    {
      "content": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
      "role": "system"
    },
    {
      "content": "Hello, where is my parcel? LB-20488",
      "role": "user"
    }
  ],
  "stream": false
}
```

**`POST /v1/chat/completions`**, com a chave como token `Bearer` e um corpo de `model` e `messages` com
papéis: o mesmo caminho e o mesmo formato do Chat Completions da OpenAI, que a aula 20 ensina como o
formato comum do setor. Só duas coisas dizem que isto é Mistral: o `user-agent`, que nomeia o SDK e a
versão, e **a chave**, que é o que um provedor de verdade usa para decidir de quem é a conta que paga. O
substituto decide do mesmo jeito, e é só por isso que consegue responder OpenAI e Mistral num caminho
só.

## O que isso significa na prática

Um programa escrito para o Chat Completions da OpenAI chega à Mistral trocando o endereço e a chave, e
a aula 20 faz exatamente isso. O SDK vale a pena mesmo assim pelo que acrescenta por cima, respostas
tipadas e novas tentativas, e a requisição que ele manda não é mais difícil de ler que a que o SDK da
OpenAI teria mandado. **Quando dois provedores compartilham um formato, trocar de um para o outro é uma
mudança de configuração**, que é a propriedade em que o harness da aula 5 se apoiou para avaliar vários
candidatos com um laço só.
