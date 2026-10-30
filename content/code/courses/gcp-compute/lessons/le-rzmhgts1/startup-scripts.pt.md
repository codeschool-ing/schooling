---
title: Scripts de inicialização, e o que os roda
version: 1
---

Uma máquina feita a partir de uma imagem pública não sabe nada da sua loja. **O que a transforma
num servidor web é um script que você entrega ao Compute Engine como metadado, que a máquina busca
e roda como root toda vez que liga.** Não uma vez, na criação: em toda inicialização. Essa única
diferença em relação ao que a maioria espera decide como o script precisa ser escrito.

## Onde o script mora

Um script de inicialização é um valor nos metadados da instância, sob uma de algumas chaves
conhecidas: `startup-script` para o próprio script, `startup-script-url` para um script guardado no
Cloud Storage, e `windows-startup-script-ps1` no Windows. Nada do lado do Google o executa. O
**ambiente convidado**, um conjunto de programas do Google pré-instalados em toda imagem pública,
lê a chave no servidor de metadados quando a máquina liga e roda o que encontrar. A lição 2 volta
a isso: uma imagem custom sem o ambiente convidado liga e ignora o script de inicialização em
silêncio.

A saída vai para dois lugares. Numa máquina Linux, o ambiente convidado a escreve no journal do
sistema sob `google_metadata_script_runner` e a copia para o **console serial** da máquina, que
você lê de fora mesmo quando o SSH está quebrado. Um script que falha não impede a inicialização e
não marca a máquina como doente; a instância aparece como `RUNNING` sem o seu servidor web. Quem
percebe isso são as verificações de saúde da lição 4.

Eis a máquina da loja com um script e três valores de metadados. **Crie uma pasta `meta` em `~/gcp`
e salve estes dois arquivos nela.** Primeiro o Terraform:

```hcl
# meta/main.tf
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

resource "google_service_account" "web" {
  account_id   = "shop-web"
  display_name = "The shop's web servers"
}

resource "google_compute_instance" "web" {
  name         = "web-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  metadata = {
    shop-env               = "staging"
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email  = google_service_account.web.email
    scopes = ["cloud-platform"]
  }
}
```

Depois o script, na mesma pasta:

```sh
#!/bin/bash
# meta/startup.sh: Compute Engine runs this as root on every boot
set -euo pipefail
MD=http://metadata.google.internal/computeMetadata/v1
get() { curl -sSf -H "Metadata-Flavor: Google" "$MD/$1"; }

ENV=$(get instance/attributes/shop-env)
ZONE=$(get instance/zone)

if ! command -v nginx >/dev/null; then
  apt-get update -q
  apt-get install -y -q nginx
fi
echo "shop $ENV, $(hostname), ${ZONE##*/}" > /var/www/html/index.html
```

Leia o script uma vez como a máquina vai ler. Ele pergunta dois valores ao servidor de metadados,
o atributo `shop-env` que você definiu e a zona que o Compute Engine escolheu, instala o nginx só
se ele ainda não estiver lá, e escreve uma página. **O `if` é o que torna seguro rodá-lo em toda
inicialização**: na segunda vez ele encontra o nginx instalado e vai direto para a página. Um
script que instalasse sem condição recorreria ao repositório de pacotes a cada reinício, e falharia
no dia em que o repositório estivesse lento.

## O que roda, e o que não roda

O script é bash puro, então ele roda no seu laptop também. Ele para na primeira pergunta:

```
ana@laptop:~/gcp/meta$ bash startup.sh; echo "exit status $?"
curl: (6) Could not resolve host: metadata.google.internal
exit status 6
```

**Isso é tudo que falta aqui, e nada mais**: não há servidor de metadados num laptop, então o
primeiro `curl` não consegue resolver `metadata.google.internal`. O `-sSf` o fez falhar alto, com
mensagem e status 6, e o `set -euo pipefail` fez o script parar ali em vez de seguir com um `ENV`
vazio. Sem essas opções ele teria escrito uma página dizendo `shop , web-1, ` e saído com 0, o
tipo de falha que ninguém encontra até um cliente encontrar.

Agora o plan, do mapa `metadata` até o fim do script:

```
ana@laptop:~/gcp/meta$ terraform plan -no-color | sed -n '/+ metadata  /,/^ *EOT$/p'
      + metadata                = {
          + "block-project-ssh-keys" = "TRUE"
          + "enable-oslogin"         = "TRUE"
          + "shop-env"               = "staging"
        }
      + metadata_fingerprint    = (known after apply)
      + metadata_startup_script = <<-EOT
            #!/bin/bash
            # meta/startup.sh: Compute Engine runs this as root on every boot
            set -euo pipefail
            MD=http://metadata.google.internal/computeMetadata/v1
            get() { curl -sSf -H "Metadata-Flavor: Google" "$MD/$1"; }
            
            ENV=$(get instance/attributes/shop-env)
            ZONE=$(get instance/zone)
            
            if ! command -v nginx >/dev/null; then
              apt-get update -q
              apt-get install -y -q nginx
            fi
            echo "shop $ENV, $(hostname), ${ZONE##*/}" > /var/www/html/index.html
        EOT
```

As outras duas chaves não são para o seu script, e sim para o ambiente convidado: `enable-oslogin`
faz o acesso SSH à máquina passar pelo IAM em vez de chaves coladas nos metadados, e
`block-project-ssh-keys` impede que chaves definidas para o projeto inteiro cheguem a esta máquina.
O `gcp-foundations` trata do OS Login.

O script está no plan palavra por palavra, o que vale saber por dois motivos. **Ele faz parte do
recurso**: quem pode ler o plan ou os metadados da instância pode ler o script, então senha nunca
vai nele. E ele é o atributo `metadata_startup_script` do provider, que a documentação do provider
marca como forçando uma instância nova quando muda. Edite uma linha do script e o próximo apply
destrói a `web-1` e cria outra. O mesmo texto sob a chave `startup-script` de `metadata` é
atualizado no lugar e roda na próxima inicialização. Nenhum dos dois comportamentos pode ser
mostrado sem um apply, então fique com a documentação do provider; escolha a chave de propósito.

## Rodando de novo, e o script de desligamento

Numa máquina ligada, o ambiente convidado consegue rodar o script de novo sem reiniciar, que é como
se testa uma mudança: `sudo google_metadata_script_runner startup` na instância, tirado da
documentação do Google e não executado aqui. O mesmo programa roda o `shutdown-script` quando a
máquina é parada, apagada ou sofre preempção. **Um script de desligamento é de melhor esforço**:
ele tem um tempo limitado, não roda se a máquina falha de repente, e a lição 6 mostra como esse
tempo é curto quando uma máquina Spot é recolhida. O que precisa sobreviver à máquina deve estar em
outro lugar antes de o desligamento começar.
