---
title: Outputs, e o que uma configuração devolve
version: 1
---

Os ids que a AWS inventou para a rede da loja estão no arquivo de state e no histórico do terminal
de um apply, e nenhum dos dois é um bom lugar para buscá-los. **O hábito a evitar é ler o arquivo
de state direto**, com `jq` ou `grep`: o formato dele é assunto do Terraform, e a aula 7 o abre
para mostrar por quê. Variáveis são o que uma configuração recebe; **outputs são o que ela promete
devolver**, declarados em blocos como todo o resto:

```hcl
output "vpc_id" {
  description = "The id AWS gave the shop's VPC."
  value       = aws_vpc.shop.id
}

output "web_subnet_id" {
  value = aws_subnet.web_a.id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
```

Cada output tem um nome e um `value`, que é qualquer expressão, aqui três referências a atributos.
`description` é opcional e funciona como numa variável. A Ana aplica:

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-7327c901412b20229]
aws_security_group.web: Refreshing state... [id=sg-3475d5edf795d5594]
aws_subnet.web_a: Refreshing state... [id=subnet-246685d4ada451bad]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-dcc6bf0490cd0c301]

Changes to Outputs:
  + vpc_id                = "vpc-7327c901412b20229"
  + web_security_group_id = "sg-3475d5edf795d5594"
  + web_subnet_id         = "subnet-246685d4ada451bad"

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

vpc_id = "vpc-7327c901412b20229"
web_security_group_id = "sg-3475d5edf795d5594"
web_subnet_id = "subnet-246685d4ada451bad"
```

**Acrescentar um output não muda recurso nenhum, e mesmo assim precisa de um apply.** O plano acima
não tem ação nenhuma sobre recursos, só `Changes to Outputs`, e `0 added, 0 changed, 0 destroyed`.
Os outputs são calculados durante um apply e guardados no state, e é o apply que os escreve lá.

O `terraform output` os lê de volta, em três formatos para três tipos de leitor:

```
ana@laptop:~/shop$ terraform output
vpc_id = "vpc-7327c901412b20229"
web_security_group_id = "sg-3475d5edf795d5594"
web_subnet_id = "subnet-246685d4ada451bad"
ana@laptop:~/shop$ terraform output vpc_id
"vpc-7327c901412b20229"
ana@laptop:~/shop$ terraform output -raw vpc_id; echo
vpc-7327c901412b20229
```

Sem nome, ele lista tudo. Com um nome, imprime aquele valor na sintaxe do HCL, com as aspas que
dizem que é uma string. **Com `-raw`, imprime a string pura, sem aspas e sem nem uma quebra de
linha**, e é por isso que o comando da Ana acrescenta `; echo`: sem ele, o prompt seguinte teria
saído na mesma linha. A falta da quebra de linha é exatamente o que um script quer, porque o valor
vai direto para outro comando:

```
ana@laptop:~/shop$ aws ec2 describe-vpcs --vpc-ids "$(terraform output -raw vpc_id)" --query "Vpcs[].Tags" --output text
Name	shop
Environment	dev
```

Esse comando pergunta à AWS pela VPC que esta configuração criou, seja ela qual for hoje, sem
ninguém copiar um id. As tags que ele devolve são as duas que a seção anterior pôs lá.

Para um programa, e não um shell, o `-json` traz cada output com o seu tipo e com uma marcação que
é assunto da aula 12:

```
ana@laptop:~/shop$ terraform output -json
{
  "vpc_id": {
    "sensitive": false,
    "type": "string",
    "value": "vpc-7327c901412b20229"
  },
  "web_security_group_id": {
    "sensitive": false,
    "type": "string",
    "value": "sg-3475d5edf795d5594"
  },
  "web_subnet_id": {
    "sensitive": false,
    "type": "string",
    "value": "subnet-246685d4ada451bad"
  }
}
```

`sensitive` está `false` nos três. Um output marcado como sensível fica escondido no plano e na
listagem simples, e a aula 12 mostra exatamente o quanto isso protege, que é menos do que parece.

**Os outputs vêm do state, não dos arquivos.** Peça um que ainda não foi aplicado, e o Terraform
diz que não o encontra e sugere o apply:

```
ana@laptop:~/shop$ terraform output bucket_name
╷
│ Error: Output "bucket_name" not found
│ 
│ The output variable requested could not be found in the state file. If you
│ recently added this to your configuration, be sure to run `terraform
│ apply`, since the state won't be updated with new output variables until
│ that command is run.
╵
```

Aqui o nome simplesmente está errado, já que a Ana não tem um output `bucket_name`, mas a mensagem
é a mesma que você recebe depois de escrever um bloco de output novo e esquecer de aplicar.

Os outputs importam além do terminal. São a única parte de uma configuração feita para outras
configurações lerem: a aula 8 faz a aplicação da loja ler os outputs da rede a partir de outro
state, e a aula 10 os transforma na interface de um módulo. **Escolher o que vira output é escolher
do que outras pessoas podem depender**, então um output merece um momento de reflexão antes de ser
publicado, e uma descrição quando o significado não é óbvio pelo nome.
