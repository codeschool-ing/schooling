---
title: Imagens públicas, e para onde o nome de uma imagem aponta
version: 1
---

Uma máquina sobe a partir de um disco, e o disco é feito de uma **imagem**: um retrato de um sistema
operacional, congelado num momento, que o Compute Engine copia para cada disco de boot novo. **Você
nunca envia o Debian ou o Ubuntu por conta própria. O Google e as distribuições publicam as imagens
em projetos públicos, e você aponta para elas pelo nome.**

## Imagens moram em projetos

Uma imagem pertence a um projeto, como tudo no Google Cloud. As públicas moram em projetos que só
existem para guardá-las, e o nome do projeto é metade de toda referência de imagem que você vai
escrever:

| projeto | o que guarda |
|---|---|
| `debian-cloud` | Debian, que este curso usa |
| `ubuntu-os-cloud` | Ubuntu, incluindo as versões LTS |
| `rocky-linux-cloud` | Rocky Linux, uma recompilação do Red Hat Enterprise Linux |
| `cos-cloud` | Container-Optimized OS, o sistema pequeno que os nós do GKE rodam |
| `rhel-cloud`, `suse-cloud`, `windows-cloud` | sistemas com licença, cobrada por hora além da máquina |

**A última linha é a que surpreende numa fatura.** Uma distribuição livre não custa nada além da
máquina e do disco. Red Hat, SUSE e Windows trazem uma taxa de licença que o Google soma por hora
enquanto a máquina roda, então a mesma `e2-standard-2` custa mais com Windows do que com Debian. A
taxa está na página de preços do sistema operacional, não na da máquina.

## Dois jeitos de nomear uma

Dentro de um projeto, toda imagem tem um nome datado, e a maioria também pertence a uma **família**.
A família é um ponteiro para a imagem mais nova dela que não foi aposentada, e é isso que deixa você
dizer "o Debian 12 atual" em vez de uma compilação específica. A seção 03 desta lição é sobre
famílias; aqui basta saber que `debian-cloud/debian-12` quer dizer "a imagem mais nova da família
`debian-12` do projeto `debian-cloud`".

No Terraform há dois jeitos de pôr isso num disco de boot, e eles se comportam de forma diferente
no seu laptop. O primeiro pergunta ao Google para qual imagem a família aponta, com um **data
source**. Crie uma pasta `images` em `~/gcp` e salve isto como `main.tf` dentro dela:

```hcl
# images/main.tf
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

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "web" {
  name         = "web-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = "default"
  }
}
```

Rode `terraform init` ali, como na lição 1, e depois o plan. Ele não falha na hora:

```
ana@laptop:~/gcp/images$ terraform plan
data.google_compute_image.debian: Reading...
data.google_compute_image.debian: Still reading... [00m10s elapsed]
data.google_compute_image.debian: Still reading... [00m20s elapsed]
data.google_compute_image.debian: Still reading... [00m30s elapsed]
```

E segue assim, uma linha a cada dez segundos, por cinco minutos e meio, porque o provider tenta o
endereço do Google de novo e de novo antes de desistir. Então:

```
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: error retrieving image information: Get "https://compute.googleapis.com/compute/v1/projects/debian-cloud/global/images/family/debian-12?alt=json": dial tcp: lookup compute.googleapis.com on 8.8.4.4:53: dial udp 8.8.4.4:53: connect: network is unreachable (Client.Timeout exceeded while awaiting headers)
│ 
│   with data.google_compute_image.debian,
│   on main.tf line 16, in data "google_compute_image" "debian":
│   16: data "google_compute_image" "debian" {
│ 
╵
```

**Um data source é lido durante o plan, então precisa da API.** O plan nem conseguiu resolver
`compute.googleapis.com`, porque este laboratório não tem rede; num laptop com internet, a mesma
requisição chegaria ao Google e seria recusada pelo token `no-account`. De um jeito ou de outro a
lição é a mesma: um data source é uma pergunta ao Google, feita antes de qualquer coisa ser criada.

O segundo jeito entrega a família ao Compute Engine como uma string e deixa que ele resolva o nome
quando criar o disco. Apague o bloco do data source e ponha a string no lugar; o `sed` faz as duas
coisas:

```
ana@laptop:~/gcp/images$ sed -i '/^data/,/^}/d; s|data.google_compute_image.debian.self_link|"debian-cloud/debian-12"|' main.tf
ana@laptop:~/gcp/images$ grep -n image main.tf
1:# images/main.tf
24:      image = "debian-cloud/debian-12"
ana@laptop:~/gcp/images$ terraform plan -no-color | grep -E '^  #|image|^Plan'
  # google_compute_instance.web will be created
              + image                  = "debian-cloud/debian-12"
Plan: 1 to add, 0 to change, 0 to destroy.
```

Esse plan não precisou de nada do Google, e essa é a troca. **O data source diz qual imagem você vai
receber antes de recebê-la; a string só descobre na criação.** Para uma equipe que revisa plans, o
primeiro é o melhor hábito quando houver conta, porque a imagem aparece no plan como um nome datado
que alguém consegue ler. Neste laboratório só pode ser o segundo.

## O que há por trás do nome

`gcloud compute images list` é o comando que mostra toda imagem pública com projeto e família. Aqui
ele para na falta de conta, como todo comando remoto deste curso, então mostramos o comando e não a
saída. Com uma conta, `--filter="family~debian"` restringe às famílias do Debian, e
`--show-deprecated` acrescenta as imagens para as quais uma família já não aponta.
