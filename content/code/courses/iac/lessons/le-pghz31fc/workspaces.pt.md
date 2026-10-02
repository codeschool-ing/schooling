---
title: "Workspaces: um diretório, um estado por nome"
version: 1
---

Um **workspace** é um estado com nome para uma configuração. O diretório, os arquivos e o bloco de
backend ficam exatamente como estão; selecionar um workspace muda qual estado todo comando seguinte
lê e grava. Toda configuração já tem um, chamado `default`, que é onde tudo neste curso rodou até
agora:

```
ana@laptop:~/shop$ terraform workspace list
* default

ana@laptop:~/shop$ terraform workspace new dev
Created and switched to workspace "dev"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
ana@laptop:~/shop$ terraform workspace new prod
Created and switched to workspace "prod"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
ana@laptop:~/shop$ terraform workspace list
  default
  dev
* prod
```

O `new` cria um workspace e o seleciona, e a mensagem diz a parte importante: um workspace novo
começa **vazio**. O asterisco no `list` marca o selecionado. Um plan em `dev` não vai ver o que
`default` ou `prod` guardam, que é exatamente a propriedade que faltava na seção anterior.

Dentro da configuração, o nome do workspace selecionado está disponível como `terraform.workspace`.
A Ana o usa no nome de tudo, para que um recurso carregue o nome do estado que é dono dele:

```
ana@laptop:~/shop$ sed -i 's/name = "shop-${var.environment}"/name = "shop-${terraform.workspace}"/' main.tf
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index e140d1e..c309bff 100644
--- a/main.tf
+++ b/main.tf
@@ -12,7 +12,7 @@ provider "aws" {
 }
 
 locals {
-  name = "shop-${var.environment}"
+  name = "shop-${terraform.workspace}"
   tags = { Project = "shop", Environment = var.environment }
 }
```

Depois cada ambiente é aplicado no seu workspace, com os seus valores:

```
ana@laptop:~/shop$ terraform workspace select dev
Switched to workspace "dev".
ana@laptop:~/shop$ terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop$ terraform workspace select prod
Switched to workspace "prod".
ana@laptop:~/shop$ terraform apply -var-file=prod.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**Três adicionados para dev, quatro para prod**, e nada destruído: o plan de prod partiu de um estado
vazio, então a rede de dev não estava nele para ser substituída. As duas redes existem lado a lado
agora, e o bucket mostra para onde foram os estados:

```
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:41:36       6318 env:/dev/shop/terraform.tfstate
2026-10-02 07:41:44       8445 env:/prod/shop/terraform.tfstate
2026-10-02 07:41:25        181 shop/terraform.tfstate
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Project,Values=shop --query "Vpcs[].[Tags[?Key==\`Name\`]|[0].Value,CidrBlock]" --output text
shop-dev	10.21.0.0/16
shop-prod	10.20.0.0/16
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um diretório, ~/shop, com um main.tf, um backend.tf e dois arquivos tfvars, e um arquivinho .terraform/environment que diz prod. Três setas saem dele para três objetos no bucket de estado: default vai para shop/terraform.tfstate, dev para env:/dev/shop/terraform.tfstate e prod para env:/prod/shop/terraform.tfstate. Só a seta de prod é cheia, porque prod é o workspace selecionado.\"><defs><marker id=\"wk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"wk-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/shop</text><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma configuração</text><text x=\"130.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">main.tf  backend.tf</text><text x=\"130.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dev.tfvars  prod.tfvars</text><rect x=\"36\" y=\"160\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">.terraform/environment</text><text x=\"130.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">prod</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o bucket de estado</text><text x=\"550.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">shop-tfstate-123456789012</text><rect x=\"414\" y=\"78\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">shop/terraform.tfstate</text><rect x=\"414\" y=\"133\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">env:/dev/shop/terraform.tfstate</text><rect x=\"414\" y=\"188\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">env:/prod/shop/terraform.tfstate</text><path d=\"M240 110 L300 110 L330 95 L410 95\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#wk-ah-wire)\"></path><path d=\"M240 135 L300 135 L330 150 L410 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#wk-ah-wire)\"></path><path d=\"M240 185 L300 185 L330 205 L410 205\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wk-ah-amber)\"></path><text x=\"368.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">default</text><text x=\"368.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dev</text><text x=\"368.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">prod</text><text x=\"130.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o workspace selecionado escolhe a key</text></svg>", "caption": "Workspaces: uma configuração e um bloco de backend, e um objeto de estado por workspace. Qual deles um comando toca é decidido por um arquivo em `.terraform`."}
```

O backend S3 guarda o estado de um workspace em `env:/<workspace>/` seguido da key do bloco de
backend; o prefixo é a configuração `workspace_key_prefix` do backend, e `env:` é o padrão dela.
**O workspace `default` mantém a key simples**, e por isso `shop/terraform.tfstate` continua lá: é o
estado da seção anterior, esvaziado pelo destroy, 181 bytes de nada. Outros backends guardam
workspaces do seu jeito, mas todo backend remoto mantém um estado por workspace, com a sua trava.

Então onde fica a seleção? Nem no bucket nem nos arquivos que a Ana commitou:

```
ana@laptop:~/shop$ terraform workspace show
prod
ana@laptop:~/shop$ cat .terraform/environment; echo
prod
ana@laptop:~/shop$ echo terraform.workspace | terraform console -var-file=prod.tfvars
"prod"
```

**Ela é uma linha em `.terraform/environment`**, um arquivo dentro do diretório que o `init` cria, que
o git ignora e ninguém lê. O `terraform workspace show` a imprime, e o console também, que é o que a
configuração enxerga. Daí saem duas consequências. A seleção pertence a este checkout, neste notebook:
o clone de um colega, ou um job de CI, começa em `default` até que algo selecione outro. E nada mais na
tela a mostra. Esse segundo ponto é a próxima seção.

Apagar um workspace tem uma proteção que vale conhecer. O Terraform recusa enquanto o estado do
workspace ainda rastreia alguma coisa, porque apagá-lo deixaria esses recursos rodando sem registro
nenhum deles:

```
ana@laptop:~/shop$ terraform workspace select default
Switched to workspace "default".
ana@laptop:~/shop$ terraform workspace delete prod
╷
│ Error: Workspace is not empty
│ 
│ Workspace "prod" is currently tracking the following resource instances:
│   - aws_security_group.web
│   - aws_subnet.public["sa-east-1a"]
│   - aws_subnet.public["sa-east-1c"]
│   - aws_vpc.shop
│ 
│ Deleting this workspace would cause Terraform to lose track of any
│ associated remote objects, which would then require you to delete them
│ manually outside of Terraform. You should destroy these objects with
│ Terraform before deleting the workspace.
│ 
│ If you want to delete this workspace anyway, and have Terraform forget
│ about these managed objects, use the -force option to disable this safety
│ check.
╵
```

A saída é um `destroy` dentro do workspace antes. O `-force` apaga mesmo assim e esquece os recursos,
que é a situação que o "losing-it" da aula 7 mostrou, alcançada de propósito.
