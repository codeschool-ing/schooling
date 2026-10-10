---
title: Mais de um cluster
version: 1
---

**Este curso roda um cluster com dois namespaces**, o que basta para ver cada ideia e é barato o
bastante para um notebook. Organizações de verdade separam a produção do resto por cluster, e não por
namespace, e rodam vários de cada, por região ou por time. A organização já tem o lugar para isso:
`clusters/` guarda uma pasta por cluster, cada uma com o seu `flux-system` e os seus arquivos
apontando para `apps/`.

```
fleet/
  apps/
    bulletin/
      staging/
      production/
  clusters/
    staging-sp/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/staging
    production-sp/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/production
    production-us/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/production
```

Cada cluster roda o próprio Flux, com bootstrap no próprio caminho `clusters/<nome>`, e puxa só o que a
pasta dele aponta. **Acrescentar uma região é uma pasta nova em `clusters/`**; a configuração da
aplicação não é copiada, porque os dois clusters de produção apontam para o mesmo
`apps/bulletin/production/`. Quando dois deles precisam diferir, um overlay por cluster guarda só a
diferença, e a aula 6 é sobre overlays.

O Argo CD chega à mesma forma pelo outro lado: um Argo CD que gerencia vários clusters, com um
ApplicationSet que gera uma Application por cluster a partir de um modelo e de uma lista, ou dos
clusters que o Argo CD conhece. De qualquer jeito, **um lugar no Git por cluster, e um lugar por
aplicação e ambiente**, é a organização que cresce bem.

Esta organização não foi rodada como três clusters para este curso: os comandos da aula 1 montam um, e
um segundo é o mesmo `kind create cluster` com outro nome e outro mapeamento de porta.
