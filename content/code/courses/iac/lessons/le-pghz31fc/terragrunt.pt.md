---
title: Onde o Terragrunt entra
version: 1
---

**O Terragrunt é um invólucro: ele escreve as partes repetitivas de uma configuração raiz para você e
depois roda o Terraform nela.** É um programa separado, da Gruntwork, com o seu próprio arquivo, o
`terragrunt.hcl`, e não substitui a linguagem do Terraform; os módulos ficam exatamente como estão. O
que ele assume é o layout de um diretório por ambiente da seção anterior, menos as cópias.

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

Tudo o que as units compartilham é escrito uma vez, no `root.hcl`:

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

Uma unit é curta. Ela inclui a raiz, nomeia o seu módulo e entrega a ele as entradas:

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
unit e também diz ao Terragrunt para rodar aquela unit primeiro:

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
07:42:59.754 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
07:42:59.757 INFO   [network] Downloading Terraform configurations from ../../modules/network into ./network/.terragrunt-cache/8NfM1BhQNSu3ej20knfGNG3b5dU/vkRyJKeJSFFqzwTOQfTUBt_KXk0
07:43:04.798 ERROR  [web] Error: Unknown variable
07:43:04.799 ERROR  [web]   on /home/ana/shop-infra/live/dev/web/terragrunt.hcl line 15:
07:43:04.799 ERROR  [web]   15:   vpc_id      = dependency.network.outputs.vpc_id
07:43:04.799 ERROR  [web] There is no variable named "dependency".
07:43:04.800 ERROR  Run failed: 2 errors occurred:

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
07:43:04.946 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
Are you sure you want to run 'terragrunt apply' in each unit of the run queue displayed above? (y/n) 07:43:04.946 INFO   TIP (debugging-docs): For help troubleshooting errors, visit https://docs.terragrunt.com/troubleshooting/debugging
07:43:04.946 ERROR  EOF
```

A pergunta ficou sem resposta, porque a entrada deste terminal está vazia, e o Terragrunt parou com
`EOF` antes de rodar qualquer coisa. Respondida com `y`, ou pulada com `--non-interactive`, ele aplica
cada unit por vez:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all --non-interactive --summary-disable apply 2>&1 | grep -e INFO -e "Apply complete"
07:43:05.102 INFO   The following units will be run, starting with dependencies and then their dependents:
07:43:09.305 STDOUT [network] terraform: Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
07:43:10.082 INFO   [web] Downloading Terraform configurations from ../../modules/web into ./web/.terragrunt-cache/IeaLxhtezokSWz7KRPOsZscXNMQ/oggAgWRx6GeDvWQfFfCMEvrgY4Y
07:43:10.120 INFO   [web] terraform: Initializing the backend...
07:43:10.138 INFO   [web] terraform: 
07:43:10.138 INFO   [web] terraform: Successfully configured the backend "s3"! Terraform will automatically
07:43:10.138 INFO   [web] terraform: use this backend unless the backend configuration changes.
07:43:10.149 INFO   [web] terraform: Initializing provider plugins...
07:43:10.149 INFO   [web] terraform: - Finding hashicorp/aws versions matching "~> 6.0"...
07:43:10.149 INFO   [web] terraform: - Installing hashicorp/aws v6.67.0...
07:43:10.865 INFO   [web] terraform: - Installed hashicorp/aws v6.67.0 (unauthenticated)
07:43:10.865 INFO   [web] terraform: Terraform has created a lock file .terraform.lock.hcl to record the provider
07:43:10.865 INFO   [web] terraform: selections it made above. Include this file in your version control repository
07:43:10.865 INFO   [web] terraform: so that Terraform can guarantee to make the same selections by default when
07:43:10.865 INFO   [web] terraform: you run "terraform init" in the future.
07:43:10.865 INFO   [web] terraform: ╷
07:43:10.865 INFO   [web] terraform: │ Warning: Incomplete lock file information for providers
07:43:10.865 INFO   [web] terraform: │ 
07:43:10.865 INFO   [web] terraform: │ Due to your customized provider installation methods, Terraform was forced
07:43:10.865 INFO   [web] terraform: │ to calculate lock file checksums locally for the following providers:
07:43:10.865 INFO   [web] terraform: │   - hashicorp/aws
07:43:10.865 INFO   [web] terraform: │ 
07:43:10.865 INFO   [web] terraform: │ The current .terraform.lock.hcl file only includes checksums for
07:43:10.865 INFO   [web] terraform: │ linux_amd64, so Terraform running on another platform will fail to install
07:43:10.865 INFO   [web] terraform: │ these providers.
07:43:10.865 INFO   [web] terraform: │ 
07:43:10.865 INFO   [web] terraform: │ To calculate additional checksums for another platform, run:
07:43:10.865 INFO   [web] terraform: │   terraform providers lock -platform=linux_amd64
07:43:10.865 INFO   [web] terraform: │ (where linux_amd64 is the platform to generate)
07:43:10.866 INFO   [web] terraform: ╵
07:43:10.866 INFO   [web] terraform: Terraform has been successfully initialized!
07:43:10.866 INFO   [web] terraform: 
07:43:10.866 INFO   [web] terraform: You may now begin working with Terraform. Try running "terraform plan" to see
07:43:10.866 INFO   [web] terraform: any changes that are required for your infrastructure. All Terraform commands
07:43:10.866 INFO   [web] terraform: should now work.
07:43:10.866 INFO   [web] terraform: If you ever set or change modules or backend configuration for Terraform,
07:43:10.866 INFO   [web] terraform: rerun this command to reinitialize your working directory. If you forget, other
07:43:10.866 INFO   [web] terraform: commands will detect it and remind you to do so if necessary.
07:43:15.685 STDOUT [web] terraform: Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
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
07:43:19.768 STDOUT [network] terraform: No changes. Your infrastructure matches the configuration.
07:43:24.127 STDOUT [web] terraform: No changes. Your infrastructure matches the configuration.
```

```
ana@laptop:~/shop-infra/live/dev$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:42:54        181 envs/dev/terraform.tfstate
2026-10-02 07:42:59        181 envs/prod/terraform.tfstate
2026-10-02 07:43:09       4480 live/dev/network/terraform.tfstate
2026-10-02 07:43:15       2041 live/dev/web/terraform.tfstate
2026-10-02 07:41:25        181 shop/terraform.tfstate
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
