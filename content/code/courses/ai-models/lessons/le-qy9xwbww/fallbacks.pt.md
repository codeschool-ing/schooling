---
title: Uma lista de modelos é uma promessa sobre dois modelos
version: 1
---

O roteamento escolhe entre provedores de um modelo. O campo `models` vai além e escolhe entre
**modelos**:

```
ana@desk:~/desk$ sources quote openrouter-fallbacks "lets you automatically try other models"
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
  21: The `models` parameter lets you automatically try other models if the primary model's
      providers are down, rate-limited, or refuse to reply due to content moderation.
```

Com o `standin-east` fora do ar de novo, a ana pede `standin/small` primeiro e `standin/large`
depois. O `standin/small` só tem esse provedor:

```
ana@desk:~/desk$ python lab/or_sort.py '{"models": ["standin/small", "standin/large"]}'
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ wire --count 1
POST /openrouter/api/v1/chat/completions -> 200 openrouter standin-large routed={'model': 'standin/large', 'provider': 'standin-west', 'tried': ['standin/small at standin-east: 503', 'standin/large at standin-east: 503']}
```

A resposta voltou, a requisição deu certo, e **quem respondeu foi o segundo modelo**. O log do lab
mostra as duas tentativas que falharam antes; o programa da ana só vê `model=standin/large` na
resposta, e só porque o imprime.

Isso é útil e é uma armadilha, pelo motivo em que a aula 5 se apoia. Uma lista de fallback afirma
que **todo modelo nela é bom o bastante** para a tarefa. Se só o primeiro foi avaliado, a queda que
manda o tráfego para o segundo é também o momento em que a mesa começa a classificar e-mail com um
modelo que ninguém mediu, a outro preço, e nada falha. Daí duas regras:

- **Avalie todo modelo que você lista**, com os mesmos casos e o mesmo harness, antes de ele entrar
  na lista.
- **Conte qual modelo respondeu**, pela resposta, para que um mês em que um terço do correio foi
  para o fallback apareça num relatório e não em reclamações.
