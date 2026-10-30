---
title: Propriedades e configurações
version: 1
---

**Toda configuração que o gcloud tem é uma propriedade, e uma configuração é um conjunto nomeado delas.**
`core/project`, `compute/region`, `auth/access_token_file`: uma seção, uma barra e um nome. A lição 1 definiu
cinco delas, e elas valem em toda lição desde então, e é por isso que nenhum comando deste curso precisou dizer
`--project=planner-dev`. Elas vivem na **configuração ativa**, que neste laboratório sempre foi a chamada
`default`:

```
ana@laptop:~/gcp$ gcloud config list
[api_endpoint_overrides]
pubsub = http://localhost:8085/
[auth]
access_token_file = /home/ana/gcp/placeholder-token
[compute]
region = southamerica-east1
[core]
disable_usage_reporting = true
project = planner-dev

Your active configuration is: [default]
```

Esse é o laboratório exatamente como a lição 1 o deixou: o projeto, a região, o token de mentira, e o override
que manda o Pub/Sub para o emulador. **Uma configuração é um conjunto inteiro**, e uma segunda começa vazia.

## Uma segunda configuração

Os engenheiros do planner trabalham em desenvolvimento o dia todo e em produção raramente, e querem que as duas
nunca se confundam. Uma configuração para cada resolve. Crie uma para a produção sem mudar para ela, dê a ela o
seu projeto, e liste as duas:

```
ana@laptop:~/gcp$ gcloud config configurations create prod --no-activate
Created [prod].
To use this configuration, activate it by running:
  $ gcloud config configurations activate prod


ana@laptop:~/gcp$ gcloud config set project planner-prod --configuration=prod
Updated property [core/project].
ana@laptop:~/gcp$ gcloud config configurations list
NAME     IS_ACTIVE  ACCOUNT  PROJECT       COMPUTE_DEFAULT_ZONE  COMPUTE_DEFAULT_REGION
default  True                planner-dev                         southamerica-east1
prod     False               planner-prod
```

O `prod` tem um projeto e nada mais: nem conta, nem token, nem override, e a próxima seção esbarra nisso. Cada
configuração é um pequeno arquivo de texto no diretório do gcloud, que neste laboratório é `~/gcp/gcloud`, o
`CLOUDSDK_CONFIG` da lição 1:

```
ana@laptop:~/gcp$ ls ~/gcp/gcloud/configurations
config_default
config_prod
```

## Que valor ganha

Uma propriedade pode ser dada em quatro lugares, e **o mais específico ganha**:

1. uma **opção** no comando, como `--project=planner-staging`;
2. uma **variável de ambiente** com o nome da propriedade, `CLOUDSDK_CORE_PROJECT` para `core/project`;
3. a **configuração** com que o comando roda: a nomeada por `--configuration`, ou por
   `CLOUDSDK_ACTIVE_CONFIG_NAME`, ou a ativa;
4. nada, e o comando pergunta ou recusa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l22-precedence\" aria-label=\"De onde o gcloud tira o valor de core/project, como quatro camadas empilhadas, a mais específica em cima. Uma opção no comando, --project=planner-staging, ganha de tudo. Abaixo dela, uma variável de ambiente, CLOUDSDK_CORE_PROJECT. Abaixo disso, a configuração com que o comando roda, escolhida por --configuration, por CLOUDSDK_ACTIVE_CONFIG_NAME ou por ser a ativa: default tem planner-dev e prod tem planner-prod. Embaixo, nada, e o comando pergunta ou recusa.\"><rect x=\"60.0\" y=\"20.0\" width=\"600.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. uma opção</text><text x=\"640.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--project=planner-staging</text><rect x=\"80.0\" y=\"72.0\" width=\"560.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. uma variável de ambiente</text><text x=\"620.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CLOUDSDK_CORE_PROJECT</text><rect x=\"100.0\" y=\"124.0\" width=\"520.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. a configuração</text><text x=\"600.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">default: planner-dev · prod: planner-prod</text><rect x=\"120.0\" y=\"176.0\" width=\"480.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. nada</text><text x=\"580.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o comando pergunta ou recusa</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a primeira camada que tem um valor ganha</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a configuração é escolhida por --configuration, CLOUDSDK_ACTIVE_CONFIG_NAME, ou por ser a ativa</text></svg>", "caption": "O lugar mais específico em que uma propriedade é definida ganha."}
```

Peça o projeto de quatro jeitos: da configuração ativa, de outra, de uma variável e de uma opção:

```
ana@laptop:~/gcp$ gcloud config get project
planner-dev
ana@laptop:~/gcp$ CLOUDSDK_ACTIVE_CONFIG_NAME=prod gcloud config get project
Your active configuration is: [prod]
planner-prod
ana@laptop:~/gcp$ CLOUDSDK_CORE_PROJECT=planner-staging gcloud config get project
planner-staging
ana@laptop:~/gcp$ gcloud config get project --project=planner-staging
planner-staging
```

**O `CLOUDSDK_ACTIVE_CONFIG_NAME` escolhe a configuração para um terminal**, ou para um comando, sem mudar qual
está ativa para todos os outros terminais, e o gcloud diz no fluxo de erro qual está usando. Esse é o hábito do
planner: a produção nunca é a configuração ativa, e um terminal que trabalha em produção diz isso na variável
com que foi aberto. Um prompt de shell que imprime a variável torna o hábito visível.
