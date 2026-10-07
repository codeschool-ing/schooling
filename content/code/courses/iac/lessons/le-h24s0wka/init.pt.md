---
title: O que o terraform init instala
version: 2
---

**O `terraform init` prepara um diretório, e não toca na nuvem.** Ele lê o `required_providers`,
encontra uma versão de cada provider que atenda à restrição, instala, e anota o que escolheu. Nada
na AWS é criado, lido ou alterado. Você roda uma vez ao começar, de novo sempre que a lista de
providers muda, e a cada cópia nova da configuração de outra pessoa.

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced
│ to calculate lock file checksums locally for the following providers:
│   - hashicorp/aws
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

As três linhas que começam com hífen trazem a notícia: o Terraform procurou versões de
`hashicorp/aws` que atendessem a `~> 6.0`, escolheu a 6.67.0 e a instalou. **A palavra
`(unauthenticated)` vem da máquina em que estas aulas foram gravadas.** Ela não tinha internet,
então instalava os providers a partir de um diretório local de pacotes, e um diretório não tem
assinatura para conferir. O seu `init` baixa do Terraform Registry, confere a assinatura do
provider e imprime `(signed by HashiCorp)` nesse lugar. Ele também pode escolher uma 6.x mais nova
que a 6.67.0, o que o `~> 6.0` permite. O quadro de aviso também é da máquina da gravação, e o seu
não tem nenhum; o lock file abaixo diz por quê.

Duas coisas apareceram ao lado dos arquivos da Ana:

```
ana@laptop:~/shop$ ls -A
.terraform
.terraform.lock.hcl
main.tf
versions.tf
ana@laptop:~/shop$ find .terraform
.terraform
.terraform/providers
.terraform/providers/registry.terraform.io
.terraform/providers/registry.terraform.io/hashicorp
.terraform/providers/registry.terraform.io/hashicorp/aws
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64/terraform-provider-aws_v6.67.0_x5
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64/LICENSE.txt
ana@laptop:~/shop$ du -sh .terraform
789M	.terraform
```

**O `.terraform/` guarda o próprio provider, e ele não é pequeno**: 789M, quase tudo num único
arquivo, `terraform-provider-aws_v6.67.0_x5`. É o programa que o Terraform vai iniciar e com o qual
vai conversar em todo plano. Cada diretório de trabalho ganha a sua cópia, a não ser que haja um
cache de plugins configurado, e o diretório pode ser apagado e refeito com `init` a qualquer
momento. Ele nunca vai para o git. O seu tem um cache, ligado pelas duas últimas linhas do
`iac-env.sh` da aula 1, então na sua tela o `linux_amd64` é um link para dentro de
`~/.terraform.d/plugin-cache`, o `find` para nele, e o `du` conta poucos kilobytes.

**O `.terraform.lock.hcl` é o contrário: pequeno, e vai, sim, para o git.**

```
ana@laptop:~/shop$ cat .terraform.lock.hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:EB9ixYOZrSlYD7wtJxf88qwoyyWrlKDKxhzaCLIb3t4=",
  ]
}
```

Ele registra a versão exata que o init escolheu, a restrição sob a qual ela foi escolhida e um
checksum do pacote. O próximo `init`, em qualquer máquina, instala a 6.67.0 e nenhuma outra, mesmo
depois que a 6.68 sair, e recusa um pacote cujo checksum não confira. Sem o arquivo, duas pessoas
rodando `init` com uma semana de diferença poderiam receber duas versões do provider e dois planos
diferentes da mesma configuração. Passar para uma versão mais nova vira um ato deliberado, que a
seção sobre providers executa.

**Este arquivo é onde a sua tela e a página mais diferem.** Instalado a partir do registry, como o
seu foi, o `hashes` traz uma linha `h1:` para a sua plataforma e uma linha `zh:` para cada
plataforma para a qual a HashiCorp compila o provider, mais de uma dúzia, e assim um lock file
escrito no Linux também funciona no Mac de um colega. A cópia local da máquina da gravação só tinha
o pacote de Linux, então o init só conseguiu calcular o hash de `linux_amd64`, e o aviso na saída
dele disse isso: um Mac recusaria este lock file. O comando que o aviso indica,
`terraform providers lock`, baixa os pacotes das outras plataformas para calcular os hashes, e na
máquina da gravação ele falhou, porque o registry estava fora de alcance:

```
ana@laptop:~/shop$ terraform providers lock -platform=darwin_arm64
╷
│ Error: Could not retrieve providers for locking
│ 
│ Terraform failed to fetch the requested providers for darwin_arm64 in order
│ to calculate their checksums: some providers could not be installed:
│ - registry.terraform.io/hashicorp/aws: could not connect to
│ registry.terraform.io: failed to request discovery document: GET
│ https://registry.terraform.io/.well-known/terraform.json giving up after 4
│ attempt(s): Get "https://registry.terraform.io/.well-known/terraform.json":
│ dial tcp: lookup registry.terraform.io on 127.0.0.1:53: server misbehaving.
╵
```

Rode você mesmo e ele dá certo: baixa o pacote do Mac, acrescenta o hash `h1:` dessa plataforma ao
arquivo e diz que o lock file foi atualizado. O seu já funcionava num Mac pelas linhas `zh:`, então
o que ele ganha é só um segundo tipo de hash para mais uma plataforma.

O que vai para o git, então, é a configuração e o lock file, e não os providers. A Ana transforma o
diretório num repositório com `git init`, e o `.gitignore` dela diz isso antes do primeiro commit:

```
.terraform/
*.tfstate
*.tfstate.*
```

```
ana@laptop:~/shop$ git add . && git status --short
A  .gitignore
A  .terraform.lock.hcl
A  main.tf
A  versions.tf
```

Ela faz o commit com `git commit -m "The shop network, first configuration"`, e o `git diff` das
próximas seções compara com commits como esse. Os dois padrões de `tfstate` são para um arquivo que
ainda não existe. O primeiro apply o escreve, e a aula 7 explica por que ele merece
um lugar mais seguro que um repositório.
