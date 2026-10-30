---
title: Ambientes, e o job de deployment
version: 1
---

**Um ambiente no Azure Pipelines é um alvo com nome que se lembra do que foi implantado nele.** É um objeto
no projeto, aqui `shop-production`, e faz três coisas que um job comum não faz. Guarda um **histórico**: cada
execução que fez deploy nele, com o commit e a esteira, então "o que está em produção agora, e desde quando"
tem uma resposta que não é a memória de alguém. Carrega **verificações**: aprovações, horário comercial, um
template obrigatório, que a lição 3 configura. E é o alvo de um **job de deployment**.

Um job de deployment é escrito `deployment:` em vez de `job:`, nomeia o seu ambiente e tem uma
**estratégia**. A esteira desta lição usa `runOnce`: cada passo uma vez, em ordem. Existem mais duas:

- **`rolling`** substitui a aplicação num conjunto de máquinas virtuais algumas de cada vez, para um ambiente
  cujos recursos são VMs registradas nele;
- **`canary`** faz deploy para uma fatia crescente, com ganchos para o que fazer a cada incremento e na
  falha.

```yaml
      - deployment: web
        environment: shop-production
        strategy:
          canary:
            increments: [10, 50]
            deploy:
              steps:
                - script: ./deploy.sh --percent $(strategy.increment)
            on:
              failure:
                steps:
                  - script: ./deploy.sh --percent 0
```

Os ganchos (`preDeploy`, `deploy`, `routeTraffic`, `postRouteTraffic`, e `on: failure` ou `on: success`) são
lugares para pôr passos. **O Azure Pipelines não move tráfego sozinho**: o `deploy.sh` acima é seu, e a
estratégia só o chama com `10`, depois `50`. Mover tráfego cabe a quem o recebe, que para a loja é o App
Service e os slots dele, e a lição 3 faz isso lá.

## O que o ambiente não sabe

Um ambiente registra que uma execução fez deploy nele, não que o deploy funcionou. Um job de deployment que
enviou uma imagem quebrada e saiu com 0 é uma linha verde no histórico. Por isso as verificações da loja
depois de um deploy, e as regras de alerta da lição 12, são consultas sobre o que a aplicação está fazendo,
e não sobre o que a esteira disse.
