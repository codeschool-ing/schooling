---
title: Uma lista de modelos é uma promessa sobre dois modelos
version: 1
---

O roteamento escolhe entre provedores de um modelo. O campo `models` vai além e escolhe entre
**modelos**:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
  21: The `models` parameter lets you automatically try other models if the primary model's
      providers are down, rate-limited, or refuse to reply due to content moderation.
```

A ana lista a Llama 3.3 70B primeiro e a Qwen 2.5 72B depois. Mandada pelo relay, é a mesma
história da seção 03: a lista viaja, e o Ollama, que não tem esse campo, responde com o único modelo
que foi pedido:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"models": ["meta-llama/llama-3.3-70b-instruct", "qwen/qwen-2.5-72b-instruct"]}'
other. model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A3 '"models"'
  "models": [
    "meta-llama/llama-3.3-70b-instruct",
    "qwen/qwen-2.5-72b-instruct"
  ]
```

No OpenRouter, a documentação diz que o modelo que respondeu vem na resposta, e a cobrança segue
ele:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
 116: Requests are priced using the model that was ultimately used, which will be returned in
      the `model` attribute of the response body.
```

Isso é útil e é uma armadilha, pelo motivo em que a aula 5 se apoia. Uma lista de recurso é uma
afirmação de que **todo modelo nela é bom o bastante** para a tarefa. Se só o primeiro foi avaliado,
a queda que manda o tráfego para o segundo é também o momento em que a mesa começa a classificar
e-mails com um modelo que ninguém mediu, a outro preço, e nada falha. Duas regras resultam disso:

- **Avalie todo modelo que você lista**, com os mesmos casos e o mesmo harness, antes de ele entrar
  na lista.
- **Conte qual modelo respondeu**, pelo `model` da resposta, para que um mês em que um terço dos
  e-mails foi para o recurso apareça num relatório e não em reclamações.
