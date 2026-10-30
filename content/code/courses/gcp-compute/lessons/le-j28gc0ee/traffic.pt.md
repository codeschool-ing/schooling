---
title: Dividindo o tráfego entre revisões
version: 1
---

O endereço de um serviço não aponta para uma revisão. **Ele aponta para uma divisão de tráfego: uma
lista de revisões com uma porcentagem cada, somando cem.** Por padrão a lista tem uma entrada,
`LATEST`, com 100%, e é por isso que uma publicação simples manda todo mundo para o código novo de
uma vez. Mude a lista e o mesmo endereço atende duas revisões na proporção que você escolheu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"As requisições ao endereço do serviço chegam a uma divisão de tráfego, que manda 90 por cento à revisão orders-v1 e 10 por cento à revisão orders-v2. Um segundo endereço, a tag canary, chega à orders-v2 direto, seja qual for a divisão. As duas revisões são retratos imutáveis de uma imagem e das suas configurações.\"><defs><marker id=\"l9-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"190\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o endereço do serviço</text><text x=\"115.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders-….run.app</text><rect x=\"20\" y=\"190\" width=\"190\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a tag canary</text><text x=\"115.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">canary---orders-…</text><rect x=\"270\" y=\"40\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">divisão de tráfego</text><path d=\"M210 64 L270 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders-v1</text><text x=\"600.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">imagem e configurações, congeladas</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders-v2</text><text x=\"600.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">imagem e configurações, congeladas</text><path d=\"M420 56 L500 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><text x=\"460\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90%</text><path d=\"M420 76 L500 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><text x=\"452\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10%</text><path d=\"M210 214 L500 194\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l9-ah)\"></path><text x=\"355\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sempre esta revisão</text><text x=\"600\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada é editado nunca</text></svg>", "caption": "O endereço aponta para a divisão, e a divisão aponta para revisões. Uma tag é um segundo endereço que pula a divisão."}
```

## A divisão, por escrito

Salve isto como `traffic/main.tf` em `~/gcp`. Ele descreve o serviço depois que a `orders-v2` foi
publicada, com nove requisições em cada dez ainda indo para a `orders-v1`:

```hcl
# traffic/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    revision = "orders-v2"

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:2"
    }
  }

  traffic {
    type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    revision = "orders-v1"
    percent  = 90
  }

  traffic {
    type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    revision = "orders-v2"
    percent  = 10
    tag      = "canary"
  }
}
```

`template.revision` é o nome da revisão que este `template` cria; os dois blocos `traffic` são a
divisão. Depois, em `~/gcp/traffic`, `terraform init` como na lição 1, e os blocos de tráfego do
plan:

```
ana@laptop:~/gcp/traffic$ terraform plan -no-color | sed -n '/+ traffic {/,/^        }/p'
      + traffic {
          + percent  = 90
          + revision = "orders-v1"
          + type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
        }
      + traffic {
          + percent  = 10
          + revision = "orders-v2"
          + tag      = "canary"
          + type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
        }
```

**Cada requisição é atribuída de forma independente, ao acaso, na proporção escrita.** O Cloud Run
não manda um usuário para uma revisão e o mantém lá: quem carrega três páginas pode ver as duas
versões. Uma mudança que precisa ser coerente para um usuário ao longo das requisições, um fluxo
novo de pagamento por exemplo, precisa de mais que uma porcentagem, em geral uma flag na aplicação
que decide por usuário.

## O que o plan não pega

Suba o canário para 20% e deixe a outra em 90%:

```
ana@laptop:~/gcp/traffic$ sed -i 's/percent  = 10/percent  = 20/' main.tf
ana@laptop:~/gcp/traffic$ terraform plan -no-color | grep -E 'percent|^Plan'
          + percent  = 90
          + percent  = 20
Plan: 1 to add, 0 to change, 0 to destroy.
```

**110 por cento planejados sem uma palavra.** A regra de as porcentagens somarem cem é imposta pela
API do Cloud Run quando a mudança é aplicada, não pelo provider quando ela é planejada, então este
arquivo falharia no `terraform apply` com um erro do Google. É o aviso da lição 1 em outra forma: um
plan limpo diz que o arquivo é coerente, e nada mais.

## Outros jeitos de nomear um alvo

Vale conhecer outro tipo de entrada, pela documentação do provider e do Google.
`TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST` manda a sua parte para a revisão mais nova, qualquer que
seja, então a próxima publicação move essa parte sozinha; é o padrão, e é o que faz uma publicação
simples ir a 100% de uma vez. Uma revisão nomeada explicitamente fica onde está até alguém movê-la.
**Para uma liberação que você controla, nomeie revisões; para um serviço em que toda publicação deve
entrar no ar de uma vez, use `LATEST`.** Misturar os dois é permitido e confuso: `LATEST` com 10% ao
lado de uma revisão nomeada quer dizer que a próxima publicação leva esses 10% sem ninguém decidir.
