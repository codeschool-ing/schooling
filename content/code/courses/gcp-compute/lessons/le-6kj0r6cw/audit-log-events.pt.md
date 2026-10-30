---
title: Eventos vindos do log de auditoria
version: 1
---

Alguns serviços anunciam as próprias mudanças, como o Cloud Storage. A maioria não. **Para esses, o
Eventarc escuta o Cloud Audit Logs: toda chamada administrativa a uma API do Google é registrada
ali, e um gatilho pode selecionar qualquer uma delas por serviço e método.** É a rede mais larga
que o Eventarc tem, e a mais lenta.

## O que uma entrada de auditoria traz

Uma entrada de log de auditoria registra quem chamou qual método de qual serviço, sobre que
recurso, e se deu certo. Um gatilho sobre elas dá três coisas:

| critério | um exemplo |
|---|---|
| `type` | `google.cloud.audit.log.v1.written` |
| `serviceName` | `compute.googleapis.com` |
| `methodName` | `v1.compute.instances.insert` |

Então "rodar algo sempre que alguém criar uma máquina virtual neste projeto" é um gatilho só, sem
nada para instalar nas máquinas e nada para consultar de tempos em tempos. A documentação do Google
lista os serviços e os métodos que gravam entradas de auditoria; os nomes dos métodos são os da
própria API, e é por isso que se leem como `v1.compute.instances.insert` e não como português.

## Por escrito

No Terraform o gatilho se parece com o da seção 02, com outros critérios. **Este bloco não foi
planejado no laboratório**, porque o plan imprimiria o mesmo que o da seção 02 imprimiu:

```hcl
resource "google_eventarc_trigger" "new_machines" {
  name     = "machine-created"
  location = "southamerica-east1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = "compute.googleapis.com"
  }
  matching_criteria {
    attribute = "methodName"
    value     = "v1.compute.instances.insert"
  }

  destination {
    cloud_run_service {
      service = "inventory"
      region  = "southamerica-east1"
    }
  }

  service_account = "eventarc@planner-dev.iam.gserviceaccount.com"
}
```

## Três coisas que surpreendem

**Os logs de acesso a dados vêm desligados.** Ações administrativas, como criar uma máquina, são
sempre registradas; ler dados, como baixar um objeto, só é registrado nos serviços em que você liga
os logs de acesso a dados, e você paga pelo volume. Um gatilho sobre um método que não é registrado
nunca dispara, e nada avisa.

**Não é imediato.** Uma entrada de auditoria é gravada depois que a chamada termina, e o Google
documenta a entrega como podendo levar alguns minutos, contra segundos de um evento direto. Serve
para manter um inventário, não serve para algo que uma pessoa está esperando.

**A localização é `global` para serviços globais.** Os logs de auditoria de um serviço sem região
são gravados globalmente, e um gatilho em `southamerica-east1` não veria nada; a localização do
gatilho precisa bater com onde as entradas são gravadas.

Nada disto pôde rodar aqui: não há projeto, então nada grava entradas de auditoria. O formato do
evento que chega é um CloudEvent como qualquer outro, com a entrada de auditoria como dados, e a
função que o recebe é escrita exatamente como na lição 17.
