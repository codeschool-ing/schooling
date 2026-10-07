---
title: Chamando a Mistral
version: 1
---

A Mistral tem o próprio SDK em Python, `mistralai`, na versão 3.0.0 na mesa. O `mistral_sort.py`
manda o prompt de classificação da ana e um e-mail por ele. Sem uma chave da Mistral, ele os manda
ao relay da seção 03, que os repassa ao Ollama e ao modelo do curso:

```python
from mistralai.client import Mistral

# with a Mistral key: api_key=os.environ["MISTRAL_API_KEY"], and no server_url
client = Mistral(api_key="ollama", server_url="http://127.0.0.1:8500")
r = client.chat.complete(model="llama3.2:3b", messages=[
    {"role": "system", "content": open("prompts/triage.txt").read()},
    {"role": "user", "content": "Hello, where is my parcel? LB-20488"}])
print(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens)
```

```
ana@desk:~/desk$ python mistral_sort.py
product-question 72 3
```

A resposta é do llama3.2:3b, e os dois números são os tokens que ele leu e escreveu. **O SDK da
própria Mistral recebeu uma resposta do Ollama**, que é a parte interessante, e o relay mostra por
que ele pôde:

```
ana@desk:~/desk$ python relay.py show --headers user-agent,authorization
POST /v1/chat/completions
user-agent: mistral-client-python/3.0.0
authorization: Bearer ollam…

{
  "model": "llama3.2:3b",
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

**`POST /v1/chat/completions`**, com a chave como um token `Bearer` e um corpo de `model` e
`messages` com papéis: o mesmo caminho e o mesmo formato do Chat Completions da OpenAI, que a aula
20 ensina como o formato comum do mercado, e que o Ollama responde. Só o `user-agent`, que nomeia o
SDK e a versão, diz que este é o SDK da Mistral. A outra coisa que importa é **a chave**: aqui um
valor de mentira, e na Mistral o que decide qual conta está pagando.

## O que isso significa na prática

Um programa escrito para o Chat Completions da OpenAI chega à Mistral trocando o endereço e a chave,
e a aula 20 faz exatamente isso. O SDK vale a pena mesmo assim pelo que acrescenta por cima,
respostas tipadas e novas tentativas, e a requisição que ele manda não é mais difícil de ler que a
que o SDK da OpenAI teria mandado. **Quando dois provedores compartilham um formato, trocar de um
para o outro é uma mudança de configuração**, que é a propriedade em que o harness da aula 5 se
apoiou para avaliar vários candidatos com um laço só.
