---
title: Zonas, públicas e privadas
version: 1
---

**O Cloud DNS serve zonas: uma zona é o conjunto de registros de um nome de domínio e de tudo abaixo dele**,
guardado pelo Google e respondido pelos servidores de nomes do Google. Uma **zona gerenciada** é o recurso do
Cloud DNS que guarda uma, e ela é de um de dois tipos:

| tipo | quem pode perguntar a ela | para que serve |
|---|---|---|
| **pública** | qualquer um na internet | os nomes que os clientes digitam: `planner.example.com`, `api.planner.example.com` |
| **privada** | só máquinas nas redes VPC que a zona lista | nomes que só existem por dentro: bancos, serviços internos, e sobreposições de nomes públicos, o `googleapis.com` da lição 17 |

Uma zona pública não faz nada até o mundo saber dela. Quando ela é criada, o Google lhe atribui quatro
servidores de nomes, com nomes como `ns-cloud-a1.googledomains.com`, e **o registrador do domínio tem de
receber esses quatro nomes**: essa delegação é o que manda o resolvedor de um estranho ao Google para perguntar
sobre `planner.example.com`. Até ela ser feita, a zona existe e ninguém pergunta a ela. É um passo fora do
Google Cloud, na empresa de quem o domínio foi comprado, e é o passo que as pessoas esquecem.

Uma zona privada não precisa de delegação. Máquinas nas redes que ela nomeia perguntam ao **resolvedor do
servidor de metadados**, em `169.254.169.254`, o endereço da lição 16 que é sempre alcançável, e esse
resolvedor conhece as zonas privadas que aquelas redes podem ver.

## As duas zonas do planner

Zonas são um serviço compartilhado, então o planner as guarda no `planner-network` junto com a própria rede.
Em `~/gcp/dns-zones`, com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/dns-zones && cd ~/gcp/dns-zones
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `zones.tf`. Todo nome no Cloud DNS é escrito **totalmente qualificado, com o ponto final**:
`planner.example.com.` é o nome; sem o ponto, seria um nome relativo a alguma coisa.

```hcl
resource "google_dns_managed_zone" "public" {
  project  = "planner-network"
  name     = "planner-example-com"
  dns_name = "planner.example.com."

  dnssec_config {
    state = "on"
  }
}

resource "google_dns_managed_zone" "internal" {
  project    = "planner-network"
  name       = "planner-internal"
  dns_name   = "planner.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }
}
```

```
ana@laptop:~/gcp/dns-zones$ terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|name_servers|visibility|state"
  # google_dns_managed_zone.internal will be created
      + dns_name         = "planner.internal."
      + name_servers     = (known after apply)
      + visibility       = "private"
      + private_visibility_config {
  # google_dns_managed_zone.public will be created
      + dns_name         = "planner.example.com."
      + name_servers     = (known after apply)
      + visibility       = "public"
          + state         = "on"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Os servidores de nomes estão *known after apply***: o Google os escolhe quando a zona é feita, e o
registrador fica sabendo deles depois, e é por isso que a delegação é um passo depois do apply e não parte
dele. `name` é o nome do recurso no projeto e `dns_name` o domínio que ele serve; os dois são textos diferentes
para leitores diferentes.

**O DNSSEC está ligado** na zona pública: o Google assina os registros dela, então um resolvedor que confere
assinaturas consegue distinguir uma resposta real de uma forjada. Ligá-lo no Cloud DNS é metade do trabalho; a
outra metade é um registro `DS` que o registrador publica na zona mãe, e até isso ser feito as assinaturas são
feitas e ninguém as confere.

A zona privada usa `.internal`, um nome de primeiro nível reservado em 2024 exatamente para isso, nomes
privados que nunca vão existir na internet, então um nome nela nunca colide com o nome público de alguém.
