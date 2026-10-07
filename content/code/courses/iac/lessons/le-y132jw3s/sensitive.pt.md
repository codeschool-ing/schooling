---
title: O que o sensitive esconde, e o que não esconde
version: 2
---

A primeira ferramenta que quase todo mundo procura é `sensitive = true`, e vale saber exatamente o
que ela compra. Uma variável ou um output marcado como sensitive é um valor que o Terraform aceita não
**imprimir**. É uma promessa sobre a tela, e é só isso.

A Ana marca a senha:

```
ana@laptop:~/shop$ sed -i 's/^  type        = string$/  type        = string\n  sensitive   = true/' main.tf
ana@laptop:~/shop$ sed -n "/^variable/,/^}/p" main.tf
variable "db_password" {
  type        = string
  sensitive   = true
  description = "The password the shop's application uses for its database."
}
```

E o plan para de mostrá-la. A marcação acompanha o valor: o `user_data` foi montado a partir da
variável, então o argumento inteiro fica escondido agora, e nada mais no plan mudou:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "user_data  |^Plan"
      + user_data                            = (sensitive value)
Plan: 1 to add, 0 to change, 0 to destroy.
```

Isso resolve a cópia dois, a tela e o log de CI. **A marcação também se espalha para tudo o que é
calculado a partir do valor**, e o Terraform a confere na única porta por onde um valor sai de uma
configuração de propósito. A Ana acrescenta um output, em `outputs.tf`, para que o script de um colega
possa buscar a senha:

```hcl
output "db_password" {
  value = var.db_password
}
```

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Output refers to sensitive values
│ 
│   on outputs.tf line 1:
│    1: output "db_password" {
│ 
│ To reduce the risk of accidentally exporting sensitive data that was
│ intended to be only internal, Terraform requires that any root module
│ output containing sensitive data be explicitly marked as sensitive, to
│ confirm your intent.
│ 
│ If you do intend to export this data, annotate the output value as
│ sensitive by adding the following argument:
│     sensitive = true
╵
```

A recusa é a parte útil. Um output montado a partir de um segredo precisa dizer isso ele mesmo, então
um valor não vira legível por acidente a três referências de distância de onde foi marcado. Ela
acrescenta o argumento que a mensagem pede:

```hcl
output "db_password" {
  value     = var.db_password
  sensitive = true
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 4

Outputs:

db_password = <sensitive>
```

## Escondido de uma listagem, não de quem lê

`<sensitive>` é o que uma listagem dos outputs mostra. Pedir o valor pelo nome, ou em JSON, devolve o
valor:

```
ana@laptop:~/shop$ terraform output
db_password = <sensitive>
ana@laptop:~/shop$ terraform output -raw db_password; echo
s3cr3t-Shop-2026
ana@laptop:~/shop$ terraform output -json
{
  "db_password": {
    "sensitive": true,
    "type": "string",
    "value": "s3cr3t-Shop-2026"
  }
}
```

Isso é de propósito. Um output existe para ser lido por alguma coisa: um script, outra configuração
(aula 8), um passo do pipeline. O `sensitive` impede que ele seja impresso quando ninguém pediu, e sai
da frente quando alguém pede.

## E o estado não liga

Depois desse apply, o estado guarda a senha em duas linhas, e uma delas é o `user_data` que o plan
parou de mostrar:

```
ana@laptop:~/shop$ grep -c s3cr3t-Shop-2026 terraform.tfstate
2
ana@laptop:~/shop$ jq -r ".resources[] | select(.type == \"aws_instance\") | .instances[0].attributes.user_data" terraform.tfstate
#!/bin/sh
echo "DB_PASSWORD=s3cr3t-Shop-2026" > /etc/shop.env
```

**`sensitive = true` não muda nada do que é gravado em disco.** O estado, o plan salvo e o histórico
do git da seção anterior estão exatamente como estavam. A maioria dos providers já marca como
sensitive, no próprio schema, os argumentos obviamente secretos, como o `password` de um banco ou o
`secret_string` de um secret, e é por isso que um plan raramente os imprime. O `user_data` não é um
deles, porque a maioria dos scripts não é secreta, então precisou da marcação da Ana para ficar
escondido.

O hábito a manter é barato: marque toda variável e todo output que carrega um segredo, e deixe a
conferência dos outputs pegar os que você esqueceu. A crença a abandonar é a de que um valor sensitive
é um valor protegido.
