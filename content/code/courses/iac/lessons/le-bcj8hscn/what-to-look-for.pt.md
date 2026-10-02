---
title: O que um revisor procura
version: 1
---

Uma trava pega exclusões. **A mudança mais perigosa desta aula não apaga nada**, e um revisor que lê
só a linha do resumo a deixaria passar. A Ana edita duas linhas, uma na regra de SSH e uma na
política do bucket:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index cc59f60..ef46b27 100644
--- a/main.tf
+++ b/main.tf
@@ -33,7 +33,7 @@ resource "aws_vpc_security_group_ingress_rule" "ssh" {
   ip_protocol       = "tcp"
   from_port         = 22
   to_port           = 22
-  cidr_ipv4         = "203.0.113.0/24"
+  cidr_ipv4         = "0.0.0.0/0"
 }
 
 resource "aws_instance" "web" {
@@ -62,7 +62,7 @@ resource "aws_s3_bucket" "assets" {
 
 data "aws_iam_policy_document" "assets_read" {
   statement {
-    actions   = ["s3:GetObject"]
+    actions   = ["s3:*"]
     resources = ["${aws_s3_bucket.assets.arn}/*"]
   }
 }
```

E o plano:

```
  # aws_iam_role_policy.web_assets will be updated in-place
  ~ resource "aws_iam_role_policy" "web_assets" {
        id          = "web:assets-read"
        name        = "assets-read"
      ~ policy      = jsonencode(
          ~ {
              ~ Statement = [
                  ~ {
                      ~ Action   = "s3:GetObject" -> "s3:*"
                        # (2 unchanged attributes hidden)
                    },
                ]
                # (1 unchanged attribute hidden)
            }
        )
        # (2 unchanged attributes hidden)
    }

  # aws_vpc_security_group_ingress_rule.ssh will be updated in-place
  ~ resource "aws_vpc_security_group_ingress_rule" "ssh" {
      ~ cidr_ipv4              = "203.0.113.0/24" -> "0.0.0.0/0"
        id                     = "sgr-b7e88ab5e67d5b3a9"
        # (8 unchanged attributes hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.
```

Dois `~`, zero destruições, e a trava o deixaria passar. Na prática, o plano abre o SSH do `web`
para todo endereço da internet, onde antes estava aberto para a faixa de um escritório. E deixa a role da
instância fazer qualquer coisa com os objetos do bucket, inclusive apagá-los, onde antes ela só
podia lê-los. Nada nos símbolos coloca isso acima de uma troca de tag. **Um alargamento é um update
in-place**, e só uma pessoa que lê os valores o enxerga.

Repare quanta ajuda o plano dá aqui. O `cidr_ipv4` mostra o valor antigo e o novo lado a lado, e a
política, que é uma string JSON, não aparece como uma string comprida trocada por outra: o Terraform
a decodifica e mostra a única chave que mudou, `Action`. É essa a diferença a ler.

## A mudança que não está no `main.tf`

Algumas mudanças nunca aparecem num bloco de recurso. A Ana sobe a restrição de versão do provider
`random`, e o plano seguinte se recusa a rodar:

```
ana@laptop:~/shop$ git diff versions.tf
diff --git a/versions.tf b/versions.tf
index fd2116b..79bd152 100644
--- a/versions.tf
+++ b/versions.tf
@@ -6,7 +6,7 @@ terraform {
     }
     random = {
       source  = "hashicorp/random"
-      version = "~> 3.8.0"
+      version = "~> 3.9"
     }
   }
 }
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/random: locked version selection 3.8.1 doesn't match the updated version constraints "~> 3.9"
│ 
│ To update the locked dependency selections to match a changed
│ configuration, run:
│   terraform init -upgrade
╵
```

O lock file fixa a versão exata que toda execução usa, e ela continua fixa até alguém pedir:

```
ana@laptop:~/shop$ terraform init -upgrade | grep -i random
- Finding hashicorp/random versions matching "~> 3.9"...
- Installing hashicorp/random v3.9.1...
- Installed hashicorp/random v3.9.1 (unauthenticated)
│   - hashicorp/random
ana@laptop:~/shop$ git diff .terraform.lock.hcl
diff --git a/.terraform.lock.hcl b/.terraform.lock.hcl
index 9a76a4c..ff14c76 100644
--- a/.terraform.lock.hcl
+++ b/.terraform.lock.hcl
@@ -10,9 +10,9 @@ provider "registry.terraform.io/hashicorp/aws" {
 }
 
 provider "registry.terraform.io/hashicorp/random" {
-  version     = "3.8.1"
-  constraints = "~> 3.8.0"
+  version     = "3.9.1"
+  constraints = "~> 3.9"
   hashes = [
-    "h1:Eexl06+6J+s75uD46+WnZtpJZYRVUMB0AiuPBifK6Jc=",
+    "h1:g40qr7yDmIpaur4SsK5BcOda3HSo1RJ6zHVMqN4EJ+0=",
   ]
 }
```

**O diff do lock file é o upgrade do provider**, e ele entra na mesma revisão que o código. Uma
versão nova de provider pode mudar padrões, acrescentar atributos e, de vez em quando, transformar
um update numa substituição no plano seguinte, então ela é revisada como uma mudança própria, e não
enfiada ao lado de outra. Dois detalhes aqui são do laboratório: o mirror dele registra só um hash
`h1:`, onde o registry público acrescentaria linhas `zh:` para cada plataforma, e instala o provider
`(unauthenticated)`. A aula 2 explica por quê.

## Um checklist de revisor

Nada disso precisa de ferramenta. Precisa do hábito de ler o plano na mesma ordem toda vez:

| procure | onde aparece | por que importa |
| --- | --- | --- |
| a substituição de algo que guarda dados | `-/+` e `# forces replacement` num banco, num volume, num bucket | o novo começa vazio |
| qualquer destruição que você não pretendia | `-` e `(because … is not in configuration)` | um bloco renomeado ou apagado destrói |
| uma regra ou uma política ficando mais larga | `~` em `cidr_ipv4`, `0.0.0.0/0`, `Action`, `*` | passa por toda contagem e toda trava |
| endereços que mudam de lugar | o mesmo tipo destruído em `[1]` e criado em `[0]` | o problema do índice da aula 4 |
| uma mudança de versão de provider ou de módulo | o diff do `.terraform.lock.hcl` | comportamento novo chega sem edição em recurso nenhum |
| contagens que não batem com a mudança que você queria | a linha `Plan:` | a mudança mexeu em mais coisa do que o diff sugere |

A última linha é por onde começar. **Antes de ler um plano, diga o que você espera que ele diga**:
"um update, mais nada". Aí o plano vira uma conferência do seu entendimento em vez de um texto em que
você passa os olhos, e um `2 to destroy` que você não previu é uma pergunta com resposta em algum
lugar do corpo.

A Ana descarta as duas edições de alargamento com `git checkout`, e elas nunca são aplicadas.
