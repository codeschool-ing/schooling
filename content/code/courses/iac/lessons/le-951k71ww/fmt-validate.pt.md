---
title: fmt e validate, as duas verificações que não custam nada
version: 1
---

Os dois primeiros degraus são comandos que você já conhece, e a aula 3 mostrou o `validate`
pegando uma faixa sem aspas. O que muda numa suíte de testes é como eles rodam: **como
verificações que falham, não como comandos que consertam**. Um pipeline não pode parar e perguntar,
então cada um precisa responder com um código de saída.

## fmt: formatação, como sim ou não

O `terraform fmt` sozinho reescreve os arquivos no layout canônico e imprime o nome de cada arquivo
que mudou. Com `-check` ele não muda nada e sai com um código diferente de zero se algum arquivo
fosse mudar; `-diff` mostra qual seria a mudança. O `outputs.tf` da Ana foi digitado com pressa:

```
ana@laptop:~/shop/modules/network$ terraform fmt -check -diff; echo "exit $?"
outputs.tf
--- old/outputs.tf
+++ new/outputs.tf
@@ -1,7 +1,7 @@
 output "vpc_id" {
-    value = aws_vpc.this.id
+  value = aws_vpc.this.id
 }
 
 output "subnet_ids" {
-  value = {for k, s in aws_subnet.this: k => s.id}
+  value = { for k, s in aws_subnet.this : k => s.id }
 }
exit 3
```

O código é `3`, onde um diretório arrumado responde `0`, e o diff diz exatamente por quê: quatro
espaços onde cabem dois, e nenhum espaço dentro das chaves de um `for`. Qualquer coisa diferente de
`0` para um pipeline. Para consertar, é o comando sem a flag:

```
ana@laptop:~/shop/modules/network$ terraform fmt
outputs.tf
ana@laptop:~/shop/modules/network$ terraform fmt -check; echo "exit $?"
exit 0
```

As duas formas olham um diretório. `-recursive` as estende a todo diretório abaixo dele, que é como
um pipeline cobre os arquivos de teste em `tests/` e todas as configurações de um repositório com
um comando só.

## validate: coerente, e com o quê

O `validate` precisa dos providers, porque o schema contra o qual ele confere está dentro deles.
Num checkout novo ele avisa:

```
ana@laptop:~/shop/modules/network$ terraform validate
╷
│ Error: Missing required provider
│ 
│ This configuration requires provider registry.terraform.io/hashicorp/aws,
│ but that provider isn't available. You may be able to install it
│ automatically by running:
│   terraform init
╵
```

Então um pipeline roda `terraform init` antes, e, quando a configuração tem um backend remoto,
`terraform init -backend=false`, que instala providers e módulos sem tocar no state. Depois disso,
o mesmo comando responde:

```
ana@laptop:~/shop/modules/network$ terraform validate
Success! The configuration is valid.
```

Eis o que ele pega. A Ana digita errado um argumento da VPC:

```
ana@laptop:~/shop/modules/network$ terraform validate
╷
│ Error: Unsupported argument
│ 
│   on main.tf line 6, in resource "aws_vpc" "this":
│    6:   cidr_blocks          = var.cidr
│ 
│ An argument named "cidr_blocks" is not expected here. Did you mean
│ "cidr_block"?
╵
```

O schema do provider não tem `cidr_blocks` em `aws_vpc`, e o Terraform sugere o nome mais próximo
que tem. Uma referência com erro de digitação, um argumento do tipo errado e um bloco no lugar
errado são recusados do mesmo jeito, com o arquivo e a linha.

**Repare no que o `validate` não pediu.** O módulo tem três variáveis e nenhuma tem default. Um plan
pediria as três, e num pipeline, sem ninguém para responder, pararia. O `validate` imprimiu
`Success!` sem nenhuma, porque ele confere a configuração e nunca os valores que vão passar por
ela. Então ele não tem como saber que uma sub-rede foi pensada para uma zona de outra região, ou
para uma faixa fora da VPC, e **toda verificação daqui para baixo na escada existe para perguntar
sobre valores**.

Esse é o resumo honesto dos dois degraus mais baratos. Eles garantem que os arquivos estão
arrumados e coerentes entre si, sem conta e sem rede. Não provam nada sobre o que o módulo vai
fazer com uma entrada específica, e uma suíte que para neles testou a ortografia.
