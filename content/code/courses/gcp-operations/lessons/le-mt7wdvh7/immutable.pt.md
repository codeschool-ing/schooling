---
title: Tags imutáveis, e as imagens que ninguém usa mais
version: 1
---

**Um repositório do Artifact Registry pode se recusar a mover uma tag.** Com as tags imutáveis ligadas,
um envio que apontaria uma tag existente para outra imagem é recusado, e a tag fica onde estava. O
segundo envio de `v1` da seção anterior teria falhado em vez de funcionar em silêncio. O registro no seu
computador não tem essa configuração, então nada nesta seção foi executado; ela é ensinada pela
documentação do Google.

É uma propriedade do repositório, definida na criação ou depois:

```sh
gcloud artifacts repositories update shop \
  --location=southamerica-east1 \
  --immutable-tags
```

Três coisas decorrem disso, e a primeira surpreende:

- **Vale para todas as tags do repositório**, inclusive `latest`. Um build que envia `:latest` a cada
  merge falha a partir da segunda execução depois que a configuração é ligada. Tire `latest` do build,
  ou mantenha-a num repositório só dela.
- **Uma tag ainda pode ser apagada** por alguém com permissão para apagar, e depois enviada de novo
  apontando para outro lugar. A imutabilidade impede o acidente, não uma pessoa que quer mover uma tag
  de propósito e tem `roles/artifactregistry.repoAdmin`.
- **Não custa nada**, e nada no download muda.

A loja liga isso no `shop`. Uma tag de `$SHORT_SHA` nomeia um commit, então nunca precisa se mover, e
um envio que tenta mover uma é um build que deu errado.

## Políticas de limpeza

Cada build envia uma imagem, e nada apaga uma sozinho. A 440 builds por mês e uns 50 MB por imagem, o
repositório da loja cresceria cerca de 22 GB por mês. O armazenamento é cobrado por gibibyte e por hora:
a página de preços, lida em 30 de outubro de 2026, dá 0,000136986 USD por GiB-hora depois do primeiro
0,5 GiB do mês, igual para toda região, o que dá 0,10 USD por GiB num mês de 730 horas. Um ano guardando
tudo são cerca de 264 GB e 26 USD por mês no fim dele, por imagens que ninguém vai baixar nunca.

Uma **política de limpeza** é uma lista de regras no repositório, cada uma `DELETE` ou `KEEP`, com uma
condição. O Artifact Registry as aplica mais ou menos uma vez por dia. `KEEP` vence `DELETE`, então o
formato comum é uma exclusão ampla e exceções estreitas. A da loja, num arquivo `cleanup.json`:

```json
[
  {
    "name": "delete-untagged-after-a-week",
    "action": {"type": "Delete"},
    "condition": {"tagState": "untagged", "olderThan": "7d"}
  },
  {
    "name": "delete-tagged-after-90-days",
    "action": {"type": "Delete"},
    "condition": {"tagState": "tagged", "olderThan": "90d"}
  },
  {
    "name": "keep-the-last-ten",
    "action": {"type": "Keep"},
    "mostRecentVersions": {"packageNamePrefixes": ["api"], "keepCount": 10}
  }
]
```

```sh
gcloud artifacts repositories set-cleanup-policies shop \
  --location=southamerica-east1 \
  --policy=cleanup.json \
  --dry-run
```

**`--dry-run` é a primeira execução, sempre.** Nesse modo o Artifact Registry não apaga nada e escreve
no Cloud Logging, que a lição 9 lê, o que teria apagado; uma regra escrita ao contrário aparece ali em
vez de em produção. Nenhum dos dois comandos foi executado aqui.

O que uma política nunca deve apagar é uma imagem que algo ainda está rodando. **Uma política conhece
tags e idades; ela não conhece os seus deploys.** Uma API que roda a mesma imagem há quatro meses, sem
ninguém fazer deploy, é exatamente a imagem que a regra de 90 dias apaga, e o próximo restart não
consegue baixá-la. A regra `Keep` das últimas dez versões é a proteção para isso, e o motivo de a loja
fazer deploy com frequência suficiente para que dez versões cubram tudo o que está rodando.
