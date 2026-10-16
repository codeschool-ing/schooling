---
title: Um indicador, contado a partir do que os clientes veem
version: 1
---

Os alarmes da lição 10 perguntam se algo está errado agora. Um **objetivo de nível de serviço** faz
outra pergunta: num mês, **o serviço foi tão confiável quanto prometemos, e quanta folga ainda resta?**
Ele começa com um indicador, e o erro comum é escolher um fácil de medir em vez de um que os clientes
sentem. CPU a 40% é fácil; ninguém nunca deixou uma loja por causa disso.

Um **indicador de nível de serviço** é uma razão de eventos:

> SLI = eventos bons / eventos válidos

Para a API da loja, dois deles cobrem o que os clientes sentem:

| SLI | um evento válido | um evento bom |
|---|---|---|
| disponibilidade | uma requisição à API, sem os health checks | uma requisição respondida sem 5xx |
| latência | a mesma | uma requisição respondida em menos de 300 ms |

Três escolhas se escondem nessas duas linhas, e cada uma muda o número:

- **o que conta como válido**: health checks, chamadores internos e robôs são tráfego, e não clientes;
  contá-los incha o numerador e o denominador com sucessos fáceis;
- **onde é medido**: no balanceador, uma requisição que a API nunca recebeu porque a tarefa estava morta
  é um 502 e conta; medida no próprio código da API, ela é invisível;
- **o que conta como bom**: um 4xx é erro do cliente e costuma ser bom para o serviço; um 429 que o
  serviço mandou por estar sobrecarregado é, discutivelmente, ruim.

**Meça na borda mais próxima do cliente**, em contagens, e guarde as definições num documento que a
equipe combinou, porque um SLI que muda de definição quando fica feio não mede nada.

## Contagens, não médias

Os dois indicadores são contagens de requisições, e é por isso que a loja publica `Requests` e `Errors`
como somas por minuto. Um SLI de latência é contado do mesmo jeito, requisições abaixo do limite sobre
todas as requisições, e não como latência média: a lição 8 mostrou o que uma média esconde. Num
balanceador, as contagens de requisições e de 5xx já existem como métricas, de graça.
