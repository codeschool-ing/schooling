---
title: O que o nome de um tipo de máquina diz
version: 1
---

`e2-standard-2` parece um código que você precisaria consultar, e não é. **O nome de um tipo de
máquina predefinido são três palavras ligadas por hífens: a série, o tipo e o número de vCPUs.**
Leia da esquerda para a direita e você sabe o que está pagando antes de abrir uma página de preços.

## Três palavras

A **série** vem primeiro. A letra diz para que a série serve, o número depois dela é a geração, e
uma letra depois disso, quando há, nomeia o processador:

| série | a letra | para que serve |
|---|---|---|
| `e2` | E, eficiente | o menor preço por vCPU; o Google escolhe o processador |
| `n4`, `n2`, `n2d` | N, uso geral | máquinas equilibradas com processador fixo; `d` é AMD |
| `c4`, `c4a` | C, desempenho | processadores mais novos e mais rápidos; `a` é Arm, o Axion do próprio Google |
| `t2a`, `t2d` | T, Tau | trabalho que escala para fora, a preço baixo por núcleo |
| `m3`, `x4` | M e X, memória | de cerca de um terabyte de memória para cima |
| `g2`, `a3` | G e A, aceleradores | uma GPU presa à máquina; lição 2 |

O **tipo** é a proporção de memória por vCPU, e há três comuns. `standard` dá cerca de 4 GiB por
vCPU, `highmem` cerca de 8 e `highcpu` 1 ou 2, conforme a série. O **último número** é a própria
quantidade de vCPUs, o que facilita a leitura em relação aos tamanhos da maioria das nuvens:
`n4-standard-8` tem oito vCPUs, ponto.

**Uma vCPU não é um núcleo.** Nas séries Intel e AMD ela é uma thread de hardware, e duas threads
dividem cada núcleo físico. Nas séries Arm, `c4a` e `t2a`, não há threads compartilhadas e uma
vCPU é um núcleo inteiro. Duas máquinas com o mesmo número de vCPUs podem então fazer quantidades
de trabalho bem diferentes, um dos motivos de a série importar tanto quanto o tamanho.

Mais três formatos completam o vocabulário. Um tipo **custom** escreve as próprias vCPUs e a
memória em MiB, como em `n4-custom-4-10240`; a seção 06 trata de quando ele compensa. Um tipo de
**núcleo compartilhado**, `e2-micro`, `e2-small` e `e2-medium`, vende uma fração de vCPU, também
na seção 06. E algumas séries acrescentam um **sufixo** para algo que vem junto com a máquina:
`-lssd` para SSDs locais, assunto da lição 3, e `-metal` para um servidor inteiro sem hypervisor.

## Escrevendo uma

Toda máquina deste curso é escrita em Terraform, porque o `terraform plan` é o único lugar do seu
laptop onde um recurso do Google ganha a forma completa. **Crie uma pasta `vm` em `~/gcp` e salve
isto como `main.tf` dentro dela:**

```hcl
# vm/main.tf
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
}
```

O primeiro bloco fixa o provider que você espelhou na seção 02; o segundo dá nome ao projeto e à
região; o terceiro é a máquina. Depois, em `~/gcp/vm`:

```
ana@laptop:~/gcp/vm$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "8.9.0"...
- Installing hashicorp/google v8.9.0...
- Installed hashicorp/google v8.9.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced
│ to calculate lock file checksums locally for the following providers:
│   - hashicorp/google
│ 
│ The current .terraform.lock.hcl file only includes checksums for
│ linux_amd64, so Terraform running on another platform will fail to install
│ these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

**O `(unauthenticated)` e o aviso são sobre a origem do provider, não sobre o Google.** Ele foi
instalado do seu próprio espelho em vez de baixado do registry da HashiCorp, então o Terraform não
pôde comparar a assinatura com a do registry e gravou checksums só da sua plataforma. Para um
laboratório está certo. Numa equipe, o lock file que ele menciona vai para o git.

Agora o plan, filtrado nas quatro linhas que importam aqui. **O Terraform colore a saída mesmo num
pipe**, então `-no-color` vem primeiro sempre que você passar por `grep`:

```
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E '^  #|^      \+ (machine_type|name|zone) |^Plan'
  # google_compute_instance.web will be created
      + machine_type         = "e2-standard-2"
      + name                 = "web-1"
      + zone                 = "southamerica-east1-a"
Plan: 1 to add, 0 to change, 0 to destroy.
```

O plan sem filtro tem 85 linhas, a maioria `(known after apply)`: valores que só o Compute Engine
pode decidir, como o id da instância e o endereço interno. Tudo que você escreveu está lá exatamente
como você escreveu.

Se o seu plan parar com um erro sobre **application default credentials**, a linha
`GOOGLE_OAUTH_ACCESS_TOKEN` da seção 02 não foi digitada neste terminal:

```
ana@laptop:~/gcp/vm$ terraform plan

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Attempted to load application default credentials since neither `credentials` nor `access_token` was set in the provider block.  No credentials loaded. To use your gcloud credentials, run 'gcloud auth application-default login'.  Original error: google: could not find default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more information
│ 
│   with provider["registry.terraform.io/hashicorp/google"],
│   on main.tf line 11, in provider "google":
│   11: provider "google" {
│ 
╵
```

**Não siga o conselho dentro dessa mensagem.** O `gcloud auth application-default login` poria uma
credencial real do Google no seu computador, e todo plan deste curso ficaria a um `terraform apply`
de uma máquina real, cobrada. Digite a linha com `no-account`.

## O que o plan não verifica

Troque o tipo por um que não existe, depois por um custom, e rode o plan a cada vez:

```
ana@laptop:~/gcp/vm$ sed -i 's/e2-standard-2/e2-standard-3/' main.tf
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E 'machine_type|^Plan'
      + machine_type         = "e2-standard-3"
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/vm$ sed -i 's/e2-standard-3/n4-custom-4-10240/' main.tf
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E 'machine_type|^Plan'
      + machine_type         = "n4-custom-4-10240"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Não existe `e2-standard-3`**: os tamanhos da E2 vão 2, 4, 8, 16, 32. O Terraform planejou mesmo
assim, porque o provider verifica o formato do seu arquivo e não o catálogo do Google. O catálogo
mora no Compute Engine, zona por zona, e o primeiro a recusar esse nome seria a chamada de API que
cria a máquina. `gcloud compute machine-types list --zones=southamerica-east1-a` é como se pergunta
a uma zona o que ela oferece; neste laboratório ele para na falta de conta, como a seção 02 mostrou.

Esse é o limite honesto deste laboratório, e vale dizer uma vez: **um plan limpo diz que o seu
arquivo é coerente, não que o Google o aceitaria.** Nomes, cotas e se uma série é oferecida numa
zona são verificados do outro lado.
