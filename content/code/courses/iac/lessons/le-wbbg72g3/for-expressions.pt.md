---
title: Expressões for e splats
version: 2
---

Uma expressão `for` monta uma coleção a partir de outra. É o mais perto de um laço que a HCL tem,
e não é um laço no sentido de uma instrução que roda: **é uma expressão, e o resultado inteiro
dela é um valor**, calculado de uma vez. É assim que uma lista de zonas vira uma lista de nomes, ou
um map de zona para faixa.

Os delimitadores em volta decidem o que sai. **Colchetes fazem uma lista; chaves fazem um map**, e
a forma de map precisa de um `=>` entre a chave e o valor:

```
ana@laptop:~/shop$ echo '[for az in var.network.azs : "${local.name}-${az}"]' | terraform console
[
  "shop-dev-sa-east-1a",
  "shop-dev-sa-east-1c",
]
ana@laptop:~/shop$ echo '{ for i, az in var.network.azs : az => cidrsubnet(var.network.cidr, 8, i + 1) }' | terraform console
{
  "sa-east-1a" = "10.20.1.0/24"
  "sa-east-1c" = "10.20.2.0/24"
}
ana@laptop:~/shop$ echo '[for az in var.network.azs : az if endswith(az, "c")]' | terraform console
[
  "sa-east-1c",
]
```

A primeira linha transformou cada zona num nome. A segunda pegou dois nomes antes do `in`, a
posição e o elemento, e usou a posição como o `netnum` que o `cidrsubnet` quer, que é a conta da
seção de funções feita uma vez por zona. A terceira acrescentou um `if`, que mantém só os
elementos para os quais a condição é verdadeira.

Esse segundo resultado, um map de zona para faixa, merece um segundo olhar. É exatamente o formato
que o `for_each` da aula 4 aceita para criar uma sub-rede por entrada, e montá-lo com uma
expressão `for` é como uma lista que alguém digitou vira recursos identificados por algo com
significado.

## Dois itens, uma chave

Um map não guarda a mesma chave duas vezes, e um `for` que produz isso é um erro, e não uma
sobrescrita silenciosa:

```
ana@laptop:~/shop$ echo '{ for az in var.network.azs : substr(az, 0, 9) => az }' | terraform console
╷
│ Error: Duplicate object key
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Two different items produced the key "sa-east-1" in this 'for' expression.
│ If duplicates are expected, use the ellipsis (...) after the value
│ expression to enable grouping by key.
╵

ana@laptop:~/shop$ echo '{ for az in var.network.azs : substr(az, 0, 9) => az... }' | terraform console
{
  "sa-east-1" = [
    "sa-east-1a",
    "sa-east-1c",
  ]
}
```

`substr(az, 0, 9)` cortou as duas zonas até a região, `sa-east-1`, então os dois itens reclamaram
a mesma chave. **O erro sugere a correção**: reticências depois do valor agrupam numa lista todos os itens com aquela chave. Querer o
agrupamento ou o erro depende de dois itens com a mesma chave serem um fato dos dados ou um engano
neles.

## Splats

O `for` mais comum lê um atributo de cada elemento de uma lista, e tem uma forma curta, o
**splat** `[*]`:

```
ana@laptop:~/shop$ echo '[aws_subnet.a, aws_subnet.c][*].cidr_block' | terraform console
[
  "10.20.1.0/24",
  "10.20.2.0/24",
]
```

`[aws_subnet.a, aws_subnet.c][*].cidr_block` é o mesmo que
`[for s in [aws_subnet.a, aws_subnet.c] : s.cidr_block]`. As sub-redes existem agora, então o
console leu as faixas delas do state. Splats aparecem mais em recursos criados com `count`, onde
`aws_subnet.private[*].id` lê todos os ids de uma vez; isso é a aula 4.

## Uma expressão for num output

A mesma expressão funciona em qualquer lugar onde cabe uma expressão. A Ana acrescenta um output
que diz que faixa cada sub-rede recebeu, no `outputs.tf`:

```hcl
output "subnet_cidrs" {
  value = {
    for s in [aws_subnet.a, aws_subnet.c] : s.tags["Name"] => s.cidr_block
  }
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]

Changes to Outputs:
  + subnet_cidrs = {
      + shop-dev-a = "10.20.1.0/24"
      + shop-dev-c = "10.20.2.0/24"
    }

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

subnet_cidrs = {
  "shop-dev-a" = "10.20.1.0/24"
  "shop-dev-c" = "10.20.2.0/24"
}
ana@laptop:~/shop$ terraform output subnet_cidrs
{
  "shop-dev-a" = "10.20.1.0/24"
  "shop-dev-c" = "10.20.2.0/24"
}
```

**Nada mudou na AWS**, e o apply diz isso: zero adicionados, alterados ou destruídos. Só o output
era novo, e o Terraform o gravou no state. Identificá-lo pela tag `Name` em vez da zona é uma
escolha com motivo: duas sub-redes podem um dia dividir uma zona, e a próxima seção mostra um plan
em que isso teria acontecido.
