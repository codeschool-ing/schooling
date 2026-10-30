---
title: Eventarc, o roteador entre uma origem e um serviço
version: 1
---

A lição 17 ligou um tópico a uma função à mão. **O Eventarc é o produto que faz essa ligação por
você, para toda origem que o Google oferece, e entrega todo evento no mesmo formato**: um
CloudEvent por HTTP, para um serviço do Cloud Run, uma função ou um workflow. Quando uma função é
publicada com `--trigger-topic`, é um gatilho do Eventarc que é criado por trás dela.

## O que um gatilho diz

Um gatilho são três respostas e uma identidade:

- **quais eventos**: uma lista de critérios de seleção, sempre com `type`, e para a maioria dos
  tipos mais um ou dois atributos que o estreitam, como o bucket em que um objeto caiu;
- **para onde vão**: o destino, um serviço do Cloud Run pelo nome e pela região, ou uma função;
- **por onde**: o transporte, que para a maioria das origens é um tópico e uma assinatura do
  Pub/Sub que o Eventarc cria e gerencia, o mesmo push que você rodou à mão;
- **com que identidade**: uma conta de serviço cujo token de identidade acompanha cada entrega,
  para que o destino possa recusar tudo que não for o Eventarc.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um gatilho do Eventarc em três partes. À esquerda, a origem: um bucket, shop-photos, onde um objeto é finalizado. No meio, o gatilho: os critérios type igual a google.cloud.storage.object.v1.finalized e bucket igual a shop-photos, e um transporte, um tópico e uma assinatura do Pub/Sub que o Eventarc cria e gerencia. À direita, o destino: o serviço do Cloud Run thumbnails, que recebe um CloudEvent por HTTP com um token de identidade da conta de serviço do gatilho.\"><defs><marker id=\"f18trig-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12\" y=\"70\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"87\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">origem</text><text x=\"87\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">shop-photos</text><text x=\"87\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um objeto é</text><text x=\"87\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">finalizado</text><rect x=\"196\" y=\"20\" width=\"328\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o gatilho photo-uploaded</text><rect x=\"210\" y=\"54\" width=\"300\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">critérios de seleção</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">type = ...storage.object.v1.finalized</text><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bucket = shop-photos</text><rect x=\"210\" y=\"140\" width=\"300\" height=\"76\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">transporte, criado pelo Eventarc</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um tópico e uma assinatura</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de push do Pub/Sub</text><rect x=\"558\" y=\"70\" width=\"150\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">destino</text><text x=\"633\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">thumbnails</text><text x=\"633\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um CloudEvent, com</text><text x=\"633\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token de identidade</text><path d=\"M162 125 L208 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f18trig-phosphor)\"></path><path d=\"M512 178 L556 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f18trig-phosphor)\"></path></svg>", "caption": "Um gatilho responde quais eventos, para onde vão e com que identidade. O transporte entre eles é um tópico e uma assinatura do Pub/Sub que o Eventarc cria para você."}
```
Os tipos de evento têm nomes como um domínio invertido dá nome a um pacote. Alguns que a loja vai
encontrar:

| tipo de evento | quando dispara |
|---|---|
| `google.cloud.storage.object.v1.finalized` | um objeto foi gravado num bucket |
| `google.cloud.storage.object.v1.deleted` | um objeto foi apagado |
| `google.cloud.pubsub.topic.v1.messagePublished` | uma mensagem chegou a um tópico |
| `google.cloud.audit.log.v1.written` | uma entrada de log de auditoria foi gravada; seção 04 |

## Um gatilho para as fotos

A loja guarda as fotos dos produtos num bucket chamado `shop-photos` e quer um serviço que faça
miniaturas sempre que uma chegar. **Crie `~/gcp/eventarc` e salve isto como `main.tf`:**

```hcl
# eventarc/main.tf
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

resource "google_eventarc_trigger" "photos" {
  name     = "photo-uploaded"
  location = "southamerica-east1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = "shop-photos"
  }

  destination {
    cloud_run_service {
      service = "thumbnails"
      region  = "southamerica-east1"
    }
  }

  service_account = "eventarc@planner-dev.iam.gserviceaccount.com"
}
```

Rode o `terraform init` e o plan, filtrado no que o gatilho promete:

```
ana@laptop:~/gcp/eventarc$ terraform plan -no-color | grep -E '^  #|attribute|value|service +=|region +=|service_account|transport|^Plan'
  # google_eventarc_trigger.photos will be created
      + service_account         = "eventarc@planner-dev.iam.gserviceaccount.com"
              + region  = "southamerica-east1"
              + service = "thumbnails"
          + attribute = "bucket"
          + value     = "shop-photos"
            # (1 unchanged attribute hidden)
          + attribute = "type"
          + value     = "google.cloud.storage.object.v1.finalized"
            # (1 unchanged attribute hidden)
      + transport (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**O transporte está `(known after apply)`**: o Eventarc cria o tópico e a assinatura quando o
gatilho é criado, e dá os nomes ele mesmo. Dois detalhes importam antes de aplicar isto de verdade.
Um gatilho sobre um bucket precisa morar na região do próprio bucket, então um bucket em São Paulo
pede um gatilho em `southamerica-east1`. E o agente de serviço do bucket precisa de permissão para
publicar no Pub/Sub, que a documentação do Google lista como uma concessão única por projeto; o
plan não tem como dizer que ela falta, porque nenhuma API foi consultada.
