---
title: Onde o Terragrunt entra
version: 2
---

**O Terragrunt é um invólucro: ele escreve as partes repetitivas de uma configuração raiz para você e
depois roda o Terraform nela.** É um programa separado, da Gruntwork, com o seu próprio arquivo, o
`terragrunt.hcl`, e não substitui a linguagem do Terraform; os módulos ficam exatamente como estão. O
que ele assume é o layout de um diretório por ambiente da seção anterior, menos as cópias.

**Instalando o Terragrunt.** É um programa só, publicado no GitHub a cada versão. As transcrições
abaixo foram feitas com a versão 1.1.6, e estes dois comandos instalam a mesma:

```sh
curl -fsSLo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v1.1.6/terragrunt_linux_amd64
sudo install terragrunt /usr/local/bin/terragrunt && rm terragrunt
```

Numa máquina ARM, como uma máquina virtual num Mac com Apple silicon, o arquivo a baixar termina em
`_linux_arm64`. Depois, `terragrunt --version` diz a versão.

A Ana acrescenta uma árvore `live` ao lado de `envs`, usando os mesmos dois módulos. Cada diretório
folha é uma **unit**: um módulo, um ambiente, um estado.

```
ana@laptop:~/shop-infra$ tree --noreport live
live
├── dev
│   ├── network
│   │   └── terragrunt.hcl
│   └── web
│       └── terragrunt.hcl
├── prod
│   ├── network
│   │   └── terragrunt.hcl
│   └── web
│       └── terragrunt.hcl
└── root.hcl
```

Tudo o que as units compartilham é escrito uma vez, no `live/root.hcl`:

```hcl
terraform_binary = "terraform"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "shop-tfstate-123456789012"
    key          = "live/${path_relative_to_include()}/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "sa-east-1"
}
EOF
}
```

O `remote_state` é o bloco de backend, escrito uma vez. O Terragrunt **gera** um `backend.tf` a partir
dele em cada unit, e a key é calculada: `path_relative_to_include()` é o caminho da unit relativo ao
`root.hcl`, então `dev/network` recebe `live/dev/network/terraform.tfstate` e duas units não têm como
dividir uma key por engano. O bloco `generate "provider"` escreve o bloco do provider do mesmo jeito.
O `terraform_binary` está ali porque o Terragrunt agora roda o OpenTofu, a não ser que alguém diga o
contrário; a própria ajuda dele diz isso:

```
ana@laptop:~/shop-infra/live$ terragrunt run --help | grep -e --tf-path
   --tf-path value                             Path to the OpenTofu/Terraform binary. Default is tofu (on PATH). [$TG_TF_PATH]
```

Uma unit é curta. Ela inclui a raiz, nomeia o seu módulo e entrega a ele as entradas.
`live/dev/network/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "dev"
  cidr        = "10.21.0.0/16"
  azs         = ["sa-east-1a"]
}
```

A unit `web` precisa do id da VPC, que é um output do estado de outra unit. Numa configuração única
isso seria uma referência; entre dois estados é um bloco **`dependency`**, que lê os outputs da outra
unit e também diz ao Terragrunt para rodar aquela unit primeiro.
`live/dev/web/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/web"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  vpc_id      = dependency.network.outputs.vpc_id
}
```

As duas units de prod são iguais, com os valores de prod, `live/prod/network/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "prod"
  cidr        = "10.20.0.0/16"
  azs         = ["sa-east-1a", "sa-east-1c"]
}
```

e `live/prod/web/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/web"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "prod"
  vpc_id      = dependency.network.outputs.vpc_id
}
```

A partir desses blocos o Terragrunt deduz a ordem da árvore inteira:

```
ana@laptop:~/shop-infra/live$ terragrunt list --tree --dag
.
├── dev/network
│   ╰── dev/web
╰── prod/network
    ╰── prod/web
```

O `run --all` roda um comando do Terraform em cada unit abaixo do diretório atual, nessa ordem. A Ana
pede a dev um plan antes de qualquer coisa existir, com as linhas do próprio Terraform filtradas do
log:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all plan 2>&1 | grep -v "terraform: "
12:16:11.586 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
12:16:11.740 INFO   [network] Downloading Terraform configurations from ../../modules/network into ./network/.terragrunt-cache/8NfM1BhQNSu3ej20knfGNG3b5dU/vkRyJKeJSFFqzwTOQfTUBt_KXk0
12:16:23.752 ERROR  [web] Error: Unknown variable
12:16:23.752 ERROR  [web]   on /home/ana/shop-infra/live/dev/web/terragrunt.hcl line 15:
12:16:23.752 ERROR  [web]   15:   vpc_id      = dependency.network.outputs.vpc_id
12:16:23.752 ERROR  [web] There is no variable named "dependency".
12:16:23.753 ERROR  Run failed: 2 errors occurred:

* resolving dependency "network" outputs: /home/ana/shop-infra/live/dev/network/terragrunt.hcl is a dependency of /home/ana/shop-infra/live/dev/web/terragrunt.hcl but detected no outputs. Either the target module has not been applied yet, or the module has no outputs.
  
  If this dependency is accessed before the outputs are ready (which can happen during the planning phase of an unapplied stack), consider using mock_outputs:
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O layout do Terragrunt para a loja. No alto, o root.hcl, incluído por toda unit, guarda o remote_state e um bloco generate para o provider. Abaixo dele, duas linhas, dev e prod, cada uma com uma unit network e uma unit web. Uma seta rotulada dependency, vpc_id, vai de network para web em cada linha, e embaixo de cada unit está a key de estado que ela recebe: live/dev/network/terraform.tfstate e assim por diante, quatro keys ao todo.\"><defs><marker id=\"tu-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"160\" y=\"14\" width=\"400\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">live/root.hcl</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">remote_state { … }   generate \"provider\" { … }</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">incluído por toda unit abaixo</text><text x=\"36.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dev</text><rect x=\"70\" y=\"100\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dev/network</text><text x=\"185.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/dev/network/terraform.tfstate</text><rect x=\"450\" y=\"100\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dev/web</text><text x=\"565.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/dev/web/terraform.tfstate</text><path d=\"M300 130 L447 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tu-ah-phosphor)\"></path><text x=\"374.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">dependency</text><text x=\"374.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">vpc_id</text><text x=\"36.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">prod</text><rect x=\"70\" y=\"200\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod/network</text><text x=\"185.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/prod/network/terraform.tfstate</text><rect x=\"450\" y=\"200\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod/web</text><text x=\"565.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/prod/web/terraform.tfstate</text><path d=\"M300 230 L447 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tu-ah-phosphor)\"></path><text x=\"374.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">dependency</text><text x=\"374.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">vpc_id</text><text x=\"360.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run --all: network primeiro, depois web, em cada ambiente</text></svg>", "caption": "Terragrunt: toda unit inclui um arquivo raiz, ganha uma key de estado a partir do próprio caminho e espera pelas units de que depende.", "same": ["dependency"]}
```

**Um plan entre estados que dependem uns dos outros não pode ficar completo antes do primeiro
apply.** A unit de rede planejou. A unit web não conseguiu, porque a entrada dela é um output de um
estado que ainda não existe. O erro oferece `mock_outputs`, valores provisórios que um plan pode usar
até os de verdade existirem; o outro caminho é aplicar em ordem. O Terragrunt pergunta antes, uma vez,
pela fila inteira:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all apply 2>&1 | grep -v "terraform: "
12:16:23.958 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
Are you sure you want to run 'terragrunt apply' in each unit of the run queue displayed above? (y/n) 12:16:23.959 INFO   TIP (debugging-docs): For help troubleshooting errors, visit https://docs.terragrunt.com/troubleshooting/debugging
12:16:23.959 ERROR  EOF
```

A página mostra o que acontece quando a pergunta fica sem resposta: a máquina em que estas aulas
foram gravadas não deu entrada nenhuma ao comando, e o Terragrunt parou com `EOF` antes de rodar
qualquer coisa. No seu terminal ele espera por você. A pergunta pode nem aparecer, porque o `grep` só
imprime uma linha quando ela termina, então o cursor fica parado embaixo da árvore. Digite `n` e
Enter, e nada é aplicado, como na página. Respondida com `y`, ou pulada com `--non-interactive`, ele
aplica cada unit por vez:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all --non-interactive --summary-disable apply 2>&1 | grep -e "units will be run" -e "Apply complete"
12:16:24.196 INFO   The following units will be run, starting with dependencies and then their dependents:
12:16:31.197 STDOUT [network] terraform: Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
12:16:44.227 STDOUT [web] terraform: Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Essa pergunta é a única confirmação que um ambiente inteiro recebe.** Sob o `run --all`, o
Terragrunt acrescenta `-auto-approve` a todo comando do Terraform que roda, a não ser que lhe digam
para não fazer isso:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --help | grep -e --no-auto-approve
   --no-auto-approve                           Don't automatically append '-auto-approve' to the underlying OpenTofu/Terraform commands run with 'run --all'. [$TG_NO_AUTO_APPROVE]
```

Depois do apply, um plan nas units não encontra nada a fazer, e cada unit tem a sua key:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all --summary-disable plan 2>&1 | grep -e "No changes" -e "Plan:"
12:16:52.410 STDOUT [network] terraform: No changes. Your infrastructure matches the configuration.
12:17:01.528 STDOUT [web] terraform: No changes. Your infrastructure matches the configuration.
```

```
ana@laptop:~/shop-infra/live/dev$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 12:15:49        181 envs/dev/terraform.tfstate
2026-10-02 12:15:57        181 envs/prod/terraform.tfstate
2026-10-02 12:16:31       4480 live/dev/network/terraform.tfstate
2026-10-02 12:16:44       2041 live/dev/web/terraform.tfstate
2026-10-02 12:13:21        181 shop/terraform.tfstate
ana@laptop:~/shop-infra/live/dev$ find network/.terragrunt-cache -name backend.tf -exec cat {} \;
# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    encrypt      = true
    key          = "live/dev/network/terraform.tfstate"
    region       = "sa-east-1"
    use_lockfile = true
  }
}
```

Os estados de `envs/` estão vazios: a Ana destruiu aqueles dois ambientes antes de construir a mesma
coisa com o Terragrunt. O último comando mostra o arquivo que o Terragrunt gerou para a unit de rede,
dentro de `.terragrunt-cache`, onde ele copia o módulo e roda o Terraform. Essa cópia é o que o
Terraform realmente enxerga, e é por isso que `.terragrunt-cache/` vai para o `.gitignore`.

**O que ele custa é uma segunda ferramenta.** Todo mundo que opera a infraestrutura, e todo pipeline,
precisa do Terragrunt numa versão conhecida além do Terraform; os erros chegam por duas camadas de log;
e quem revisa tem um segundo conjunto de blocos para aprender, escritos em HCL mas sem significado
nenhum para o Terraform. Para dois ambientes com um estado cada, as cópias da seção anterior saem mais
baratas. O Terragrunt começa a compensar quando há muitas units, que é quando quarenta e cinco blocos
de backend deixam de ser força de expressão.
