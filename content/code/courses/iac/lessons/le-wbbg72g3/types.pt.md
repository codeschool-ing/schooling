---
title: Tipos, e o formato de uma variável
version: 1
---

Uma variável sem `type` aceita qualquer coisa, e isso parece cômodo até um valor errado passar.
Alguém passa `"sa-east-1a"` onde se queria uma lista de zonas, e o erro chega três recursos
depois, dentro de um argumento, apontando uma sub-rede em vez da entrada que o causou. **Uma
restrição de tipo leva esse erro para a porta**, onde ele nomeia a variável.

A HCL tem três famílias de tipo.

| família | tipos | guarda |
| --- | --- | --- |
| primitiva | `string`, `number`, `bool` | um valor |
| coleção | `list(T)`, `set(T)`, `map(T)` | qualquer quantidade de valores, todos do tipo `T` |
| estrutural | `object({...})`, `tuple([...])` | um formato fixo, cada parte com seu tipo |

A diferença entre as duas últimas linhas é a que vale guardar. **Uma coleção tem um tipo de
elemento e qualquer tamanho**: uma `list(string)` de zonas pode ter uma ou seis. **Um tipo
estrutural tem formato fixo**: um object nomeia seus atributos, cada um com tipo próprio, e uma
tuple fixa o tipo de cada posição. Também existe `any`, que quer dizer "descubra pelo valor", e
isso devolve a porta para onde estava.

A variável `network` da Ana, do arquivo mostrado na seção de expressões, é um object de três
atributos: uma string, uma lista de strings e um booleano marcado **`optional(bool, false)`**. O
default dela deixa `public` de fora, e o console mostra o que o Terraform fez disso:

```
ana@laptop:~/shop$ echo 'var.network' | terraform console
{
  "azs" = tolist([
    "sa-east-1a",
    "sa-east-1c",
  ])
  "cidr" = "10.20.0.0/16"
  "public" = false
}
ana@laptop:~/shop$ echo 'type(var.network)' | terraform console
object({
    azs: list(string),
    cidr: string,
    public: bool,
})
```

`public` está lá com o valor `false`, preenchido pela declaração `optional()`, então as sub-redes
podem ler `var.network.public` sem conferir se alguém o definiu. As zonas saíram como
`tolist([...])`: o default foi escrito como tuple, e o Terraform o converteu na lista que o tipo
pede. `type()` é uma função que só o console tem, e é o jeito mais rápido de ver o que um valor
realmente é.

## Conversão, e onde ela para

O Terraform converte entre tipos quando a conversão não pode perder nada:

```
ana@laptop:~/shop$ echo '"5" + 1' | terraform console
6
ana@laptop:~/shop$ echo 'tonumber("three")' | terraform console
╷
│ Error: Invalid function argument
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Invalid value for "v" parameter: cannot convert "three" to number; given
│ string must be a decimal representation of a number.
╵

ana@laptop:~/shop$ echo 'toset(["sa-east-1c", "sa-east-1a", "sa-east-1c"])' | terraform console
toset([
  "sa-east-1a",
  "sa-east-1c",
])
```

`"5" + 1` é `6`, porque `"5"` é um número escrito como string. `"three"` não é, e o `tonumber` diz
isso. Um set é uma coleção sem ordem e sem repetidos, então o `toset` descartou o segundo
`sa-east-1c` e imprimiu o que sobrou em ordem. Essa última propriedade pesa na aula 4, onde o
`for_each` aceita um set ou um map, e não uma lista.

## O erro na porta

Um arquivo `.tfvars` que dá a `azs` uma string em vez de uma lista:

```hcl
network = {
  cidr = "10.20.0.0/16"
  azs  = "sa-east-1a"
}
```

```
ana@laptop:~/shop$ terraform plan -var-file=wrong.tfvars
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for input variable
│ 
│   on wrong.tfvars line 1:
│    1: network = {
│    2:   cidr = "10.20.0.0/16"
│    3:   azs  = "sa-east-1a"
│    4: }
│ 
│ The given value is not suitable for var.network declared at
│ variables.tf:7,1-19: attribute "azs": list of string required, but have
│ string.
╵
```

**O erro aponta o arquivo, a variável, o atributo e os dois tipos**: lista de strings exigida,
string recebida. Nada foi planejado. Sem a restrição, esse valor teria chegado a
`var.network.azs[0]` no `network.tf`, e a primeira reclamação teria vindo de lá, num arquivo que
quem escreveu o `.tfvars` talvez nunca tenha aberto.

Um tipo diz que formato um valor tem. Não consegue dizer que `azs` deve nomear zonas de São Paulo,
nem que o ambiente é uma de duas palavras. Isso é uma regra de validação, e é a última seção desta
aula.
