---
title: Constantes num bloco, e o iota
version: 1
---

Quem chega de Java, C# ou TypeScript procura uma palavra-chave `enum`. **Go não tem, e não precisa:
um conjunto de valores com nome é um bloco `const`, um tipo para eles e o `iota`.** Esta seção
separa as três peças, começando pelo que uma constante pode guardar.

## O que pode ser constante

A lição 5 declarou constantes uma de cada vez e mostrou que uma constante sem tipo é um número sem
tamanho. A outra metade dessa regra é que uma constante só pode ser um valor que o compilador
calcula antes de o programa rodar: um número, uma string ou um booleano. Um slice é montado em
tempo de execução, então não pode ser constante, e o `iota` também não pode ser usado em lugar
nenhum fora de uma declaração de constante:

```go
package main

import "fmt"

const primes = []int{2, 3, 5}

func main() {
	n := iota
	fmt.Println(primes, n)
}
```

```
ana@vm:~/zero-const$ go build
# example.com/const
./main.go:5:16: []int{…} (value of type []int) is not constant
./main.go:8:7: cannot use iota outside constant declaration
```

**Um valor que só existe com o programa rodando pertence a um `var`.** Uma tabela de primos que
nada deve mudar é, em Go, um `var` no nível do pacote, e mantê-la intacta é questão de não escrever
nela.

## Um Weekday, um tamanho e um status

O programa abaixo declara três conjuntos de constantes e imprime no que eles viraram. Leia as notas
ao lado de cada bloco, depois a saída embaixo.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command days numbers a set of constants with iota.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n",
      "note": "O pacote `time` está aqui só pelo `Weekday` dele, impresso no fim para comparar com este."
    },
    {
      "code": "\ntype Weekday int\n",
      "note": "**Um tipo novo cujos valores são `int`s.** Declarar tipos é o assunto da lição 10; aqui isso dá ao conjunto de constantes um tipo próprio, que o `%T` em `main` imprime."
    },
    {
      "code": "\nconst (\n\tSunday Weekday = iota\n\tMonday\n\tTuesday\n\tWednesday\n\tThursday\n\tFriday\n\tSaturday\n)\n",
      "note": "**`iota` é a posição da linha no seu bloco `const`, contando a partir de 0.** Só a primeira linha é escrita por extenso. Cada linha seguinte que tem um nome e mais nada repete a linha de cima, tipo e expressão, então `Monday` é `Weekday = iota` na linha 1, que vale 1, e `Saturday` vale 6."
    },
    {
      "code": "\nconst (\n\t_   = iota\n\tKiB = 1 << (10 * iota)\n\tMiB\n\tGiB\n\tTiB\n)\n",
      "note": "**Um bloco novo recomeça o `iota` em 0, e o `_` gasta uma linha sem dar nome a ela.** A linha 0 é descartada, então `KiB` está na linha 1 e é `1 << 10`: 1 deslocado dez bits para a esquerda, que é 2 elevado a 10, 1024. A expressão repetida faz o resto, então `MiB` é `1 << 20` e `TiB` é `1 << 40`."
    },
    {
      "code": "\ntype Status int\n\nconst (\n\tUnknown Status = iota\n\tActive\n\tSuspended\n)\n\ntype account struct {\n\tname   string\n\tstatus Status\n}\n",
      "note": "**A linha 0 é o que um campo esquecido guarda, então dê a ela um nome que diga isso.** Uma `account` criada sem `status` recebe o `Status` zero, que é `Unknown` e não `Active`."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(Sunday, Monday, Saturday)\n\tfmt.Printf(\"%T\\n\", Monday)\n\n\tvar day Weekday\n\tfmt.Println(day == Sunday)\n\n\tfmt.Println(KiB, MiB, GiB, TiB)\n\n\ta := account{name: \"ana\"}\n\tfmt.Println(a.status == Unknown)\n\n\tfmt.Printf(\"%v %d\\n\", time.Saturday, time.Saturday)\n}\n",
      "note": "Seis linhas de saída, uma por `Println` ou `Printf`. A última imprime o `Saturday` da biblioteca padrão duas vezes: com `%v`, a forma padrão, e com `%d`, como número inteiro."
    }
  ],
  "output": "0 1 6\nmain.Weekday\ntrue\n1024 1048576 1073741824 1099511627776\ntrue\nSaturday 6\n"
}
```

Três coisas nessa saída merecem uma parada.

**`Println(Sunday, Monday, Saturday)` imprimiu `0 1 6`, e não os nomes.** O nome de uma constante é
para quem lê o código-fonte; o programa guarda só o número. O `time.Saturday` da biblioteca padrão
imprimiu `Saturday` porque o tipo dele tem um método que transforma o número numa palavra, e
métodos são a lição 25.

**`day == Sunday` deu `true` para um `Weekday` que ninguém definiu.** É a regra da seção 01
encontrando esta: o valor zero de um `Weekday` é 0, e 0 é domingo. Um registro com o dia esquecido
diria domingo sem avisar ninguém. O `Status` evita isso gastando a linha 0 com `Unknown`, então o
campo esquecido diz o que aconteceu, e `a.status == Unknown` deu `true`.

**`KiB` a `TiB` são quatro linhas de aritmética escritas uma vez só.** O padrão é comum para
tamanhos e para flags de bits. Funciona porque uma linha repetida repete a expressão com o `iota`
ainda dentro dela, e cada linha a calcula na sua própria posição.

A biblioteca padrão faz exatamente isso com os dias da semana dela, e o `go doc` mostra o bloco sem
edição:

```
ana@vm:~/zero-iota$ go doc time.Sunday
package time // import "time"

const (
	Sunday Weekday = iota
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
)
```

**Constantes numeradas pelo `iota` são numeradas pela posição**, então inserir uma linha no meio do
bloco renumera todas as constantes depois dela. Isso não faz mal enquanto os números ficam dentro
do programa, e vira bug assim que um deles é gravado num arquivo ou num banco de dados e lido de
volta por um build mais novo. Um conjunto cujos números saem do programa fica mais seguro escrito à
mão: `Active Status = 1`, `Suspended Status = 2`.
