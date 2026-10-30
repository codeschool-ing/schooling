---
title: Regras de ciclo de vida, e o relógio que o emulador não tem
version: 1
---

**Uma configuração de ciclo de vida é uma lista de regras que o Cloud Storage aplica aos objetos de um
bucket conforme eles envelhecem**: movê-los para uma classe mais fria depois de tantos dias, apagá-los
depois de mais tantos, apagar versões não atuais, limpar uploads que começaram e nunca terminaram. É o
único lugar em que o Cloud Storage trabalha sozinho, sem nenhuma requisição sua, e é exatamente a parte
que um emulador não consegue imitar.

Cada regra é uma ação e uma condição, e a ação acontece com um objeto quando todas as partes da
condição são verdadeiras para ele. A documentação do Google, cloud.google.com/storage/docs/lifecycle,
lista três ações:

| ação | o que faz |
|---|---|
| `SetStorageClass` | move o objeto para uma classe mais fria, sem reescrevê-lo |
| `Delete` | apaga o objeto; um vivo num bucket versionado passa a não atual, um não atual some de vez |
| `AbortIncompleteMultipartUpload` | remove as partes de um upload que começou e nunca terminou |

E as condições de que a maioria das regras é feita:

| condição | verdadeira para um objeto quando |
|---|---|
| `age` | ele foi criado há pelo menos tantos dias |
| `matchesPrefix`, `matchesSuffix` | o nome dele começa ou termina com uma das strings dadas |
| `matchesStorageClass` | a classe dele é uma das dadas |
| `isLive` | ele é a versão viva (`true`) ou uma não atual (`false`) |
| `daysSinceNoncurrentTime` | ele está não atual há pelo menos tantos dias |
| `numNewerVersions` | existem pelo menos tantas versões mais novas do mesmo nome |

Não há tags no Cloud Storage para filtrar, ao contrário de outros armazenamentos de objetos, então **o
nome é o filtro**. É mais um motivo para o esquema de nomes da aula 1 pôr o tipo de dado no começo da
chave: `raw/orders/` e `raw/scratch/` podem ser distinguidos por uma regra, e um arquivo que escondesse
o tipo no fim de um nome longo só poderia ser pego com `matchesSuffix`.

## As regras da Quitanda

O bucket raw guarda as exportações noturnas sob `raw/orders/`. Os analistas leem o último mês com
frequência, o último ano raramente, e nada mais antigo a não ser numa auditoria. Arquivos temporários
sob `raw/scratch/` não valem nada depois de uma semana. Escreva isso como regras, num arquivo:

`lifecycle.json`:

```json
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30, "matchesPrefix": ["raw/orders/"], "matchesStorageClass": ["STANDARD"]}
    },
    {
      "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
      "condition": {"age": 365, "matchesPrefix": ["raw/orders/"], "matchesStorageClass": ["NEARLINE"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 2555, "matchesPrefix": ["raw/orders/"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 7, "matchesPrefix": ["raw/scratch/"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"isLive": false, "daysSinceNoncurrentTime": 7}
    },
    {
      "action": {"type": "AbortIncompleteMultipartUpload"},
      "condition": {"age": 3}
    }
  ]
}
```

**Uma exportação fica em Standard no primeiro mês, em Nearline até completar um ano, em Archive por mais
seis anos, e depois some**, já que 2.555 dias são sete anos. Um arquivo temporário vive uma semana. Em
qualquer lugar do bucket, uma versão vive sete dias depois de substituída, e um upload deixado pela
metade é limpo depois de três. As condições `matchesStorageClass` restringem cada mudança aos objetos
para os quais foi escrita. Uma regra de ciclo de vida só move um objeto para uma classe mais fria, então
só uma reescrita traz um de volta.

**Nos sete anos, um GiB sob essas regras custa uns 0,48 USD**, contra 2,98 se tivesse ficado em
Standard. Os preços são os de São Paulo, da aula 2, e um mês tem 30 dias:

```
ana@laptop:~/gcp$ python3 -c 'print(round(30 / 30 * 0.035 + 335 / 30 * 0.020 + 2190 / 30 * 0.003, 4), round(2555 / 30 * 0.035, 4))'
0.4773 2.9808
```

O primeiro número são 30 dias de Standard a 0,035, 335 de Nearline a 0,020 e 2.190 de Archive a
0,003; o segundo são os 2.555 dias todos em Standard. As estadias mínimas são todas cumpridas, então
nenhuma exclusão antecipada é cobrada; e as mudanças de classe que uma regra faz ficam livres da cobrança
de exclusão antecipada de qualquer forma, segundo a página de preços. **Cada mudança é uma operação Class
A ao preço da classe de destino.** Para uma exportação de algumas centenas de megabytes, isso não é
nada. Para um milhão de arquivos de 10 KB movidos para o Archive são 50 USD, e é por isso que uma regra
num bucket de arquivos pequenos merece uma segunda olhada.

## O que o emulador faz com as regras

Aplique o arquivo e leia o bucket de volta:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=lifecycle.json
  
Updating gs://quitanda-raw-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-prod --format=json
{
  "creation_time": "2026-10-30T15:37:25-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-raw-prod",
  "storage_url": "gs://quitanda-raw-prod/",
  "update_time": "2026-10-30T15:37:25-0300",
  "versioning_enabled": false
}
```

**O emulador respondeu com sucesso e não guardou nada.** No Cloud Storage o `describe` traria um
`lifecycle_config` com as seis regras; aqui esse campo não existe. O fake-gcs-server 1.54.0 não guarda
configuração de ciclo de vida, e não tem relógio que envelheça um objeto, então não poderia aplicar uma
se guardasse: nada nele acontece entre duas requisições.

O que confere alguma coisa é a linha de comando, antes de a requisição sair:

```
ana@laptop:~/gcp$ printf '{"rule": [{"action": {"type": "Teleport"}, "condition": {"age": 1}}]}' > odd.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=odd.json
  
Updating gs://quitanda-raw-prod/...

ana@laptop:~/gcp$ printf '{"rule": [{"action": {"type": "Delete"}, "condition": {"agee": 1}}]}' > typo.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=typo.json
  
Updating gs://quitanda-raw-prod/...
ERROR: Found invalid JSON/YAML for the lifecycle rule
```

**Uma condição digitada errado é recusada pelo próprio `gcloud`**, que conhece os nomes das condições.
Uma ação chamada `Teleport` não é, porque a linha de comando repassa o tipo da ação, e o emulador a
aceitou como aceita tudo. O Cloud Storage recusa uma regra cuja ação não conhece. Então, neste
laboratório, um arquivo de ciclo de vida é conferido quanto aos nomes das condições e ao JSON, e nada
mais: se ele faz sentido como regras, e o que elas fariam ao longo de meses, é ensinado aqui a partir da
documentação do Google e conferido por você.

Dois detalhes documentados completam o quadro. **O Cloud Storage aplica as regras de forma
assíncrona**: a documentação diz que uma ação pode levar até 24 horas depois que o objeto se
qualifica, então um objeto chega à nova classe algum tempo depois do dia em que se qualifica, não no
minuto. E uma mudança nas regras pode levar até 24 horas para valer, o que vale saber antes de escrever
uma regra `Delete` com um `age` curto num bucket que guarda algo de valor: teste-a antes em
`quitanda-raw-dev`.
