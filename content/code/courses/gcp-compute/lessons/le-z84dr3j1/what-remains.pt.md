---
title: O que resta, e quando ainda serve
version: 1
---

O App Engine continua suportado, continua recebendo deploys e continua sendo o lugar mais barato
para algumas aplicações morarem. Ele também carrega decisões de 2008 que produtos mais novos
tomaram de outro jeito, e **uma equipe que o escolhe hoje deve escolhê-lo sabendo quais dessas
decisões está aceitando.**

## Quatro coisas permanentes, ou quase

**Uma aplicação por projeto, numa região, para sempre.** A aplicação é criada uma vez, a região
dela é escolhida ali, e a documentação do Google é explícita: ela não pode ser mudada. Escrita em
Terraform, a aplicação é um recurso cujo único atributo obrigatório é essa localização. **Crie
`~/gcp/appengine` e salve isto como `main.tf`:**

```hcl
# appengine/main.tf
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

resource "google_app_engine_application" "app" {
  location_id = "southamerica-east1"
}
```

Depois `terraform init` e o plan:

```
ana@laptop:~/gcp/appengine$ terraform plan -no-color | grep -E '^  #|location_id|default_hostname|url_dispatch|^Plan'
  # google_app_engine_application.app will be created
      + default_hostname  = (known after apply)
      + location_id       = "southamerica-east1"
      + url_dispatch_rule = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

Uma equipe que quer a vitrine em São Paulo e em Iowa precisa de dois projetos. Uma equipe que
escolheu a região errada precisa de um projeto novo e de uma migração.

**O serviço default não pode ser apagado**, e toda aplicação tem um. Outros serviços podem ir e
vir.

**Os serviços legados embutidos pertencem ao passado.** Os runtimes de primeira geração vinham com
o acesso próprio do App Engine ao Datastore, Memcache, Task Queues, Mail e Users, embutidos no
runtime. Os de segunda geração, o Python 3 entre eles, os deixam de fora por padrão; o Google os
oferece por uma camada de compatibilidade para migrações, e recomenda os produtos independentes no
lugar: Firestore, Memorystore, Cloud Tasks (lição 20) e assim por diante.

**Algumas cotas e limites são do próprio App Engine**, como o tempo que uma requisição pode levar
com escalonamento automático, dez minutos no ambiente padrão, e eles diferem dos do Cloud Run. Leia
antes de portar uma requisição longa.

## Quando ainda serve

| a situação | App Engine padrão? |
|---|---|
| um app web pequeno ou ferramenta interna que fica ociosa quase o dia todo | sim: as horas gratuitas cobrem |
| uma equipe que não quer contêiner, imagem nem registry | sim: só código e `app.yaml` |
| um app do App Engine que já existe e funciona | mantenha, e planeje as atualizações de runtime |
| qualquer linguagem ou biblioteca que os runtimes não têm | não: isso é contêiner, então Cloud Run |
| um app que precisa existir em duas regiões | não: uma região por projeto |
| trabalho novo sem compromisso anterior | o Cloud Run é onde o Google está investindo |

O resumo justo é o que as próprias páginas do Google deixam implícito. **O App Engine padrão
continua um bom lar para aplicações web pequenas e convencionais que cabem nos seus runtimes**, e é
imbatível em preço na parte de baixo da faixa. Todo o resto que um dia precisou dele agora tem um
lugar melhor, e a lição 22 passa os serviços da loja por essa escolha com os números.
