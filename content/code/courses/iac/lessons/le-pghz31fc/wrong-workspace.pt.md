---
title: O workspace errado
version: 1
---

Workspaces põem a escolha do ambiente num arquivo escondido, e esse é o risco inteiro. **Nada no
comando, no diretório ou no prompt diz qual ambiente um comando está prestes a tocar.** O prompt
abaixo diz `ana@laptop:~/shop$` em dev e em prod, igualzinho, e o comando é o mesmo comando.

Eis o acidente, gravado exatamente como acontece. A última coisa que a Ana fez foi o apply de prod,
então `prod` continua selecionado. Na manhã seguinte ela quer testar algo em dev, e começa com um plan
usando os valores de dev:

```
ana@laptop:~/shop$ terraform plan -var-file=dev.tfvars -no-color | grep -E "^  #|# forces|^Plan:"
  # aws_security_group.web must be replaced
      ~ vpc_id                 = "vpc-6f5c1302ec4961db4" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1a"] must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.21.1.0/24" # forces replacement
      ~ vpc_id                                         = "vpc-6f5c1302ec4961db4" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1c"] will be destroyed
  # (because key ["sa-east-1c"] is not in for_each map)
  # aws_vpc.shop must be replaced
      ~ cidr_block                           = "10.20.0.0/16" -> "10.21.0.0/16" # forces replacement
Plan: 3 to add, 0 to change, 4 to destroy.
```

**Lido como um plan de dev, isso parece não fazer sentido; é um plan de prod.** Os valores de dev
aplicados ao estado de prod: a VPC de produção substituída por uma com a faixa de dev, a segunda
sub-rede destruída, o security group recriado. Quatro recursos destruídos, em produção, por um comando
pensado para o ambiente em que errar é barato. Com `-auto-approve`, ou um `yes` apressado, isso é uma
queda.

A seleção que causou isso é o arquivo de uma palavra da seção anterior:

```
ana@laptop:~/shop$ cat .terraform/environment; echo
prod
```

Toda defesa contra isso é um jeito de devolver o ambiente a algum lugar que uma pessoa ou uma máquina
confere. A mais barata fica na própria configuração. O arquivo de valores já diz para qual ambiente
foi escrito, então a Ana faz a variável se recusar a ser usada em qualquer outro, com um bloco
`validation` do tipo que a aula 3 apresentou, e repete o mesmo erro:

```
ana@laptop:~/shop$ git diff
diff --git a/variables.tf b/variables.tf
index 313010f..2966bc7 100644
--- a/variables.tf
+++ b/variables.tf
@@ -1,6 +1,11 @@
 variable "environment" {
   description = "Which environment these values are for: dev or prod."
   type        = string
+
+  validation {
+    condition     = var.environment == terraform.workspace
+    error_message = "These values are for ${var.environment}, and the selected workspace is ${terraform.workspace}."
+  }
 }
 
 variable "cidr" {
ana@laptop:~/shop$ terraform plan -var-file=dev.tfvars

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on dev.tfvars line 1:
│    1: environment = "dev"
│     ├────────────────
│     │ terraform.workspace is "prod"
│     │ var.environment is "dev"
│ 
│ These values are for dev, and the selected workspace is prod.
│ 
│ This was checked by the validation rule at variables.tf:5,3-13.
╵
```

**O plan é recusado antes de qualquer leitura na AWS, e o erro nomeia os dois lados**: o ambiente
para o qual os valores foram escritos e o workspace a que foram entregues. É exatamente a frase que
faltava na tela da primeira vez. O par certo continua planejando sem problema:

```
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars -no-color | grep -E "^(No changes|Plan:)"
No changes. Your infrastructure matches the configuration.
```

A checagem vale o que vale o arquivo de valores, e pega só esse erro: uma mudança no próprio
`main.tf`, testada no workspace errado, não carrega `environment` nenhum para comparar. Três hábitos
fecham o resto da brecha.

**Diga o workspace em todo comando que importa.** O `TF_WORKSPACE` seleciona um workspace para um
comando sem mexer no arquivo, então um script ou um pipeline nunca depende do que alguém deixou
selecionado:

```
ana@laptop:~/shop$ TF_WORKSPACE=dev terraform plan -var-file=dev.tfvars -no-color | grep -E "^(No changes|Plan:)"
No changes. Your infrastructure matches the configuration.
ana@laptop:~/shop$ terraform workspace show
prod
```

O plan rodou em dev, senão a validação o teria recusado, e a seleção guardada continua sendo prod: a
variável valeu para aquele comando e não mudou mais nada. Pipelines deveriam passá-la sempre, ou rodar
`terraform workspace select` como primeiro passo.

**Ponha no prompt.** Um prompt de shell que lê `.terraform/environment` quando ele existe põe o
ambiente em toda linha, que é a defesa mirada na falha de verdade, uma pessoa que não percebe. São
umas poucas linhas de configuração do shell e não têm nada a ver com o Terraform.

**Dê a prod credenciais que dev não tem.** Um plan que não consegue se autenticar na conta de prod não
consegue substituir a VPC de prod, seja qual for o workspace selecionado. Essa é a camada de
isolamento da primeira seção, e é nela que os workspaces são mais fracos: um diretório e um bloco de
backend significam um conjunto de credenciais lendo o estado de todos os ambientes, num bucket só. A
própria documentação do Terraform diz isso, que workspaces da CLI não servem para ambientes que
precisam de credenciais e controles de acesso separados. O layout da próxima seção é a resposta
de costume.
