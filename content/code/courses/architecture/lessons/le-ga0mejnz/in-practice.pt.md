---
title: Na prática
version: 1
---

Ninguém escreve o próprio breaker em produção; o do laboratório tem 25 linhas para poder ser lido. As
bibliotecas que fazem isso, e os lugares onde ele é configurado em vez de escrito:

| onde | o que dá |
| --- | --- |
| Resilience4j (Java), Polly (.NET), Tenacity e Stamina (Python), `cockatiel` (Node.js) | retries com backoff e jitter, circuit breakers, timeouts e bulkheads como decoradores em volta de uma chamada |
| os SDKs da AWS e do Google Cloud | retries ligados por padrão, com backoff, jitter e uma cota de retries, já ajustados para os próprios serviços |
| gRPC | prazos levados em toda chamada, políticas de retry e *retry throttling*, configurados por método |
| o Envoy, e service meshes construídas sobre ele, como o Istio | retries, timeouts e *outlier detection* (um breaker por instância) no sidecar, sem mudar código |

A service mesh da aula 3 é a última linha: o sidecar tenta de novo por você. É conveniente e é também o
jeito como os retries acabam em três camadas ao mesmo tempo, a biblioteca da aplicação, o sidecar e o
gateway, cada um configurado por uma pessoa diferente. **Saiba onde estão os seus retries.**

## O prazo que viaja

A tempestade gastou a maior parte da capacidade com chamadores que tinham ido embora. A resposta do gRPC é
**mandar o prazo junto com a chamada**, como o cabeçalho `X-Deadline` do laboratório fazia, e fazer todo
serviço conferi-lo: uma requisição cujo prazo passou é descartada antes de qualquer trabalho, e um serviço
que chama outro repassa o tempo que sobrou. O serviço do laboratório só contava essas requisições; um
serviço que as recusasse teria gastado a capacidade com chamadores que ainda esperavam.

## Um padrão sensato

Para uma chamada de um serviço a outro, antes que alguma medição diga outra coisa:

1. **Um timeout em toda chamada**, da aula 5, definido a partir da latência que o serviço tem de fato.
2. **Retries só para operações idempotentes**, dois ou três no máximo, com backoff exponencial e jitter
   completo, numa camada só.
3. **Um orçamento de retries**, para os retries não multiplicarem a carga numa queda.
4. **Um circuit breaker por dependência**, com uma alternativa onde houver uma razoável.
5. **Métricas sobre tudo isso**: retries, mudanças de estado do breaker e requisições recusadas por um
   breaker aberto. Um breaker aberto do qual ninguém fica sabendo é uma queda que parece uma tarde
   tranquila.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
