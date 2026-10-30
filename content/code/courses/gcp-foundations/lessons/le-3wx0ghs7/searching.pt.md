---
title: Buscando no ambiente
version: 1
---

**Uma busca nomeia um escopo, uma consulta e, se quiser, os tipos de recurso**, e devolve o que casa em qualquer
lugar sob o escopo. A API é pública no sentido que importa aqui: o **documento de discovery** dela, a descrição
legível por máquina que toda API do Google publica, não exige credencial nenhuma, e é dele que o gcloud, as
bibliotecas cliente e o provider do Terraform aprendem o que uma API oferece. Pergunte a ele que métodos a API do
Cloud Asset tem:

```
ana@laptop:~/gcp$ curl -s 'https://cloudasset.googleapis.com/$discovery/rest?version=v1' | jq -r '.resources.v1.methods | keys[]'
analyzeIamPolicy
analyzeIamPolicyLongrunning
analyzeMove
analyzeOrgPolicies
analyzeOrgPolicyGovernedAssets
analyzeOrgPolicyGovernedContainers
batchGetAssetsHistory
exportAssets
queryAssets
searchAllIamPolicies
searchAllResources
```

**Uma resposta real do Google**, sem token nenhum mandado: a lista de métodos, que são os comandos do gcloud da
seção anterior com os nomes da API. E o que o planner mais usa:

```
ana@laptop:~/gcp$ curl -s 'https://cloudasset.googleapis.com/$discovery/rest?version=v1' | jq '.resources.v1.methods.searchAllResources | {httpMethod, flatPath, parameters: (.parameters | keys)}'
{
  "httpMethod": "GET",
  "flatPath": "v1/{v1Id}/{v1Id1}:searchAllResources",
  "parameters": [
    "assetTypes",
    "orderBy",
    "pageSize",
    "pageToken",
    "query",
    "readMask",
    "scope"
  ]
}
```

Um `GET` num escopo, `organizations/123456789012` ou `folders/…` ou `projects/…`, com `query` e `assetTypes` como
os parâmetros que fazem o trabalho. Os outros paginam os resultados e escolhem que campos voltam.

## A linguagem de consulta

Uma consulta é um conjunto de condições sobre campos, a mesma ideia dos filtros do gcloud da lição 22, sobre os
campos que todo recurso tem:

| consulta | acha |
|---|---|
| `labels.team:planner` | recursos cujo rótulo `team` é `planner` |
| `NOT labels.team:*` | recursos **sem** rótulo `team` nenhum |
| `location:southamerica-east1` | recursos em São Paulo |
| `state:ACTIVE` | recursos cujo estado é ativo |
| `createTime<1735689600` | recursos criados antes de 1º de janeiro de 2025, o tempo escrito em segundos |
| `name:scratch` | recursos cujo nome contém a palavra |

Condições se unem com `AND` e `OR`, e **os tipos de recurso restringem a busca** antes da consulta:
`--asset-types=pubsub.googleapis.com/Topic` olha só para tópicos.

A pergunta semanal do planner, todo tópico da organização sem dono:

```
ana@laptop:~/gcp$ gcloud asset search-all-resources --scope=organizations/123456789012 --query="NOT labels.team:*" --asset-types=pubsub.googleapis.com/Topic
ERROR: (gcloud.asset.search-all-resources) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.cloud.asset.v1.AssetService.SearchAllResources
    service: cloudasset.googleapis.com
  reason: CREDENTIALS_MISSING
```

Recusada pelo `cloudasset.googleapis.com`, nas palavras do método que o documento de discovery nomeou,
`SearchAllResources`. Com `roles/cloudasset.viewer` na organização, a resposta seria uma linha por tópico sem
rótulo em todo projeto, com o projeto, a localização e a data de criação: a lista que o `forgotten.sql` da lição
14 ia querer ao lado.
