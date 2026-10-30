---
title: Duas gerações, uma plataforma, e os limites
version: 1
---

Procure por Cloud Functions e você encontra dois produtos com o mesmo nome. **A primeira geração é
o serviço original; a segunda é construída sobre o Cloud Run e o Eventarc, e o Google agora a chama
de Cloud Run functions.** Trabalho novo vai para a segunda. A primeira ainda roda funções
publicadas anos atrás, e é por isso que os limites dela ainda aparecem em respostas na internet.

## O que a segunda geração mudou

| | primeira geração | segunda geração (Cloud Run functions) |
|---|---|---|
| requisições por instância | uma de cada vez | até 1.000 ao mesmo tempo |
| chamada HTTP mais longa | 9 minutos | 60 minutos |
| chamada de evento mais longa | 9 minutos | 9 minutos |
| maior instância | 8 GiB de memória | 32 GiB e 8 vCPUs |
| origens de eventos | uma lista fixa | tudo que o Eventarc entrega; lição 18 |
| o que a roda | uma plataforma própria | um serviço do Cloud Run que você pode inspecionar |

A linha de concorrência é a que muda contas. Na primeira geração, cem requisições simultâneas
queriam dizer cem instâncias; na segunda, uma instância pode atender várias delas, e a lição 11 é
sobre escolher quantas. O preço acompanha a plataforma: a página de preços do Cloud Functions,
lida em 30 de outubro de 2026, abriu nos preços do Cloud Run, que são os que o `prices.py` traz.

## Publicando, como o Google documenta

Publicar exige uma conta, então este laboratório não faz isso. Com uma, a função de cotação da
seção 02 é publicada a partir da pasta dela assim. **Este comando não foi executado:**

```sh
gcloud functions deploy quote --gen2 --region=southamerica-east1 \
  --runtime=python312 --source=. --entry-point=quote --trigger-http
```

O build do Google empacota a pasta, instala o framework e o `requirements.txt` se houver um, e cria
um serviço do Cloud Run chamado `quote`. Uma função de evento troca `--trigger-http` por
`--trigger-topic=orders`, e é nesse momento que a assinatura de push da seção 04 é criada para
você.

## A mesma função, por escrito

O Terraform também descreve a função publicada, e isso o laboratório consegue planejar. **Crie
`~/gcp/functions` e salve isto como `main.tf`:**

```hcl
# functions/main.tf
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

resource "google_cloudfunctions2_function" "quote" {
  name     = "quote"
  location = "southamerica-east1"

  build_config {
    runtime     = "python312"
    entry_point = "quote"
    source {
      storage_source {
        bucket = "planner-dev-sources"
        object = "quote.zip"
      }
    }
  }

  service_config {
    available_memory   = "256Mi"
    timeout_seconds    = 60
    max_instance_count = 10
  }
}
```

A origem é um zip da pasta num bucket, que é o que o `gcloud` envia por trás. Rode o `terraform
init`, depois o plan, filtrado:

```
ana@laptop:~/gcp/functions$ terraform plan -no-color | grep -E '^  #|runtime|entry_point|available_memory|timeout_seconds|max_instance_count|  \+ (uri|url) |^Plan'
  # google_cloudfunctions2_function.quote will be created
      + url              = (known after apply)
          + entry_point           = "quote"
          + runtime               = "python312"
          + available_memory                 = "256Mi"
          + max_instance_count               = 10
          + timeout_seconds                  = 60
          + uri                              = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

Dois números nesse arquivo são decisões, não padrões. **`timeout_seconds` é quanto tempo uma
chamada pode durar** antes de o Google cortá-la, e uma cotação que leva um minuto é um bug, não um
dia lento. **`max_instance_count` é o teto de cópias**, e é a única proteção contra um laço que
chama a função a partir dela mesma, ou um pico que de outro modo escalaria até virar conta. O `uri`
e o `url` são decididos pelo Google na publicação, e é por isso que os dois estão `(known after
apply)`.

## Onde uma função deixa de ser a resposta

Uma função serve a um pedaço pequeno de trabalho com um gatilho claro: um webhook, uma reação a um
upload, uma mensagem para processar. Serve menos quando o trabalho é uma aplicação inteira com
muitas rotas, porque cada rota vira uma publicação própria para manter em sintonia. Isso é um
serviço do Cloud Run, o assunto da lição 8, e a fronteira entre os dois foi borrada de propósito:
desde a segunda geração, uma função é um serviço do Cloud Run com um framework dentro.
