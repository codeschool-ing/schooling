---
title: O provider, baixado e conferido
version: 1
---

O `iac` ensinou o modelo do Terraform desde a primeira lição: providers, o plano, o estado e um backend remoto.
Esta lição é sobre a parte que só aparece contra o Azure. O Terraform vai para `~/.local/bin`, na versão que o
`iac` usa; o Ubuntu põe esse diretório no path no seu próximo login, e a última linha o põe agora:

```sh
mkdir -p ~/.local/bin && cd ~/azure
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
export PATH="$HOME/.local/bin:$PATH"
```

Num computador Arm, o arquivo é `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/azure/tf/shop$ terraform version
Terraform v1.16.4
on linux_amd64
```

A primeira configuração da loja declara o provider, fixado numa versão exata, e um grupo de recursos,
`rg-shop`, em São Paulo:

```hcl
# main.tf
resource "terraform_data" "release" {
  input = "v42"
}
```

`features {}` é exigido pelo provider `azurerm` mesmo vazio; é onde se ajusta o comportamento do provider como um
todo, como recusar ou não apagar um grupo de recursos que ainda tem recursos dentro. `subscription_id` também é
exigido desde a versão 4 do provider: o Terraform não vai adivinhar qual das suas assinaturas mudar, e essa é uma
recusa que vale a pena ter. Ele vem de uma variável, para os mesmos arquivos servirem a todo ambiente.

```
ana@laptop:~/azure/tf/shop$ terraform init -input=false -no-color
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/tf/shop$ du -sh .terraform
254M	.terraform
ana@laptop:~/azure/tf/shop$ cat .terraform.lock.hcl | head -5
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "5.12.0"
```

O `init` baixou o provider do Terraform Registry, conferiu a assinatura da HashiCorp e escreveu o
`.terraform.lock.hcl`, que registra a versão exata e os checksums do que foi instalado. **Faça commit do arquivo de
lock**, como o próprio comentário dele diz, para um colega e a esteira instalarem os mesmos bytes. O provider tem
um quarto de gigabyte por diretório de trabalho, o que é motivo para manter `.terraform/` fora do repositório e
motivo para a esteira guardá-lo em cache.

```
ana@laptop:~/azure/tf/shop$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/shop$ terraform fmt -check; echo "exit status $?"
exit status 0
```

**`validate` e `fmt` não precisam de credenciais nem de assinatura**, e por isso pertencem ao primeiro estágio de
uma esteira e a este laboratório. O `validate` confere a configuração contra o esquema do provider: tipos,
argumentos obrigatórios, referências que se resolvem. O `fmt -check` sai com código diferente de zero quando um
arquivo não está no layout canônico, o que poupa toda revisão de uma discussão sobre espaços.
