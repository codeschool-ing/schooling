---
title: Expressões, e o console para testá-las
version: 2
---

Tudo o que está à direita de um `=` é uma expressão, e uma expressão é qualquer coisa que produz
um valor. O literal `"10.20.0.0/16"` é a mais simples. As interessantes calculam: leem outro
valor, comparam dois, escolhem entre eles ou montam uma string a partir de pedaços.

**O `terraform console` é onde você as testa.** Ele lê a configuração do diretório atual e o
state ao lado dela, avalia o que você der e imprime o valor. Não cria nada nem muda nada. Nestas
aulas a expressão chega por `echo`, então cada comando e sua resposta ficam em duas linhas;
digitado num terminal, o console espera num prompt `>`. As variáveis que ele lê estão num arquivo
novo, `variables.tf`, que a seção de tipos desta aula desmonta:

```hcl
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }
}
```

```
ana@laptop:~/shop$ echo 'var.environment' | terraform console
"dev"
ana@laptop:~/shop$ echo 'var.environment == "prod" ? 3 : 1' | terraform console
1
ana@laptop:~/shop$ echo '"shop-${var.environment}"' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo 'aws_vpc.shop.cidr_block' | terraform console
(known after apply)
```

**Uma referência nomeia um valor declarado em outro lugar.** `var.environment` é uma variável de
entrada, `local.name` vai ser um local, e `aws_vpc.shop.cidr_block` é um atributo de um recurso: o
tipo, o nome, depois o atributo. A aula 2 mostrou que uma referência entre dois recursos também é
uma ordem, porque a sub-rede não pode ser criada antes da VPC cujo id ela lê. Data sources são
referenciados como `data.…`, na aula 5, e módulos como `module.…`, na aula 10.

A última resposta é a que merece atenção. **O console responde a partir do state, não do
arquivo**, e nada foi aplicado ainda, então até um valor que a Ana digitou literalmente aparece
como `(known after apply)`. Isso não é erro. É como o Terraform escreve um valor que só vai
existir quando o recurso existir, e os plans estão cheios disso.

Os operadores são os que você imaginaria. Aritmética é `+ - * / %`, comparação é `==`, `!=`, `<`,
`>`, `<=` e `>=`, e lógica é `&&`, `||` e `!`. O condicional `condição ? a : b` é o único jeito
de escolher: não existe instrução `if`, porque não existem instruções. Os dois ramos precisam
produzir o mesmo tipo, ou tipos que o Terraform consiga converter num só.

## Strings que são montadas

`"shop-${var.environment}"` é um **template**: o `${…}` guarda uma expressão, e o valor dela é
escrito dentro da string. Uma segunda forma, `%{…}`, guarda uma diretiva, `if` ou `for`, e decide
que texto aparece:

```
ana@laptop:~/shop$ echo '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo '"shop-${var.environment}%{ if var.environment == "prod" } (reviewed)%{ endif }"' | terraform console -var environment=prod
"shop-prod (reviewed)"
```

A mesma expressão dá duas strings, porque o `-var` mudou a variável que ela lê. Uma diretiva
dentro de uma string de uma linha fica difícil de ler a partir desse tamanho, e quando uma
condição escolhe um valor inteiro o operador condicional diz isso com mais clareza.

Para texto de várias linhas existe o **heredoc**, que a Ana usa para um script curto de
inicialização, no `boot.tf`:

```hcl
locals {
  boot_script = <<-EOT
    #!/bin/sh
    echo "shop ${var.environment}" > /etc/motd
    echo "owner: ${var.owner}" >> /etc/motd
  EOT
}
```

```
ana@laptop:~/shop$ echo 'local.boot_script' | terraform console
<<EOT
#!/bin/sh
echo "shop dev" > /etc/motd
echo "owner: ana" >> /etc/motd

EOT
```

`<<-EOT` remove a indentação comum a todas as linhas, para o script poder ficar indentado junto
com o código em volta; o `<<EOT` simples mantém cada espaço. O console imprime o resultado também
como heredoc, com a quebra de linha que termina a última linha. Um aviso: um heredoc é uma
string, e uma policy escrita como JSON dentro de um também é uma string, sem conferência nenhuma
até a AWS lê-la. O `jsonencode()`, da próxima seção, monta o mesmo JSON a partir de um valor de
verdade e não consegue esquecer uma vírgula.
