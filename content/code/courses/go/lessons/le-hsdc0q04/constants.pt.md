---
title: Constantes, com e sem tipo
version: 1
---

Em JavaScript, `const` quer dizer uma variável que não pode ser reatribuída, e ela pode guardar
qualquer coisa que o programa calcule enquanto roda. O `const` de Go é outra coisa. **Uma constante
Go é um valor que o compilador conhece, e ela só existe enquanto o programa está sendo compilado.**
Não pode ser reatribuída, e também não pode ser o resultado de nada que aconteça em tempo de
execução:

```go
package main

import (
	"fmt"
	"os"
)

const limit = 10
const args = len(os.Args)

func main() {
	limit = 20
	fmt.Println(limit, args)
}
```

```
ana@vm:~/vars-fixed$ go run .; echo $?
# example.com/vars-fixed
./main.go:9:14: len(os.Args) (value of type int) is not constant
./main.go:12:2: cannot assign to limit (neither addressable nor a map index expression)
1
```

Dois erros numa execução, cada um na sua linha. `os.Args` guarda os argumentos de linha de comando
do programa, que ninguém conhece até o programa começar, então a quantidade deles não pode ser uma
constante. E `limit` não pode receber atribuição nenhuma: uma constante não é um lugar na memória
com um valor dentro, e é isso que o "not addressable" da mensagem quer dizer. Números, strings e
booleanos que o compilador consegue calcular são para o que servem as constantes: um limite, um
nome, uma razão, um tamanho.

## Sem tipo: um número que ainda não escolheu um

`const answer = 42` não tem tipo escrito, e isso não é o mesmo que o tipo ser deduzido do valor,
que foi o que o `var` fez na seção 01. **Uma constante sem tipo continua sendo só um número até ser
usada, e então assume o tipo do lugar onde cai**, desde que caiba:

```go
package main

import "fmt"

const Pi = 3.14159

const (
	answer = 42
	name   = "Ana"
)

func main() {
	var radius float64 = 2
	var small int8 = answer
	var exact float64 = answer

	fmt.Println(Pi*radius*radius, name)
	fmt.Println(small, exact)
	fmt.Printf("%T %T\n", small, exact)
}
```

```
ana@vm:~/vars-const$ go run .
12.56636 Ana
42 42
int8 float64
```

A mesma `answer` virou um `int8` numa variável e um `float64` na seguinte, e `Pi` multiplicou um
`float64` sem que ninguém dissesse de que tipo `Pi` era. Quando uma constante sem tipo cai onde
nenhum tipo é pedido, como em `x := answer`, ela assume o seu **tipo padrão**: `int` para um número
inteiro, `float64` para um com ponto decimal e `string` para texto. São os tipos que o `%T`
informou nas seções 01 e 02.

Escreva o tipo, e a constante passa a tê-lo:

```go
package main

import "fmt"

const answer int = 42

func main() {
	var small int8 = answer
	fmt.Println(small)
}
```

```
ana@vm:~/vars-typed$ go run .; echo $?
# example.com/vars-typed
./main.go:8:19: cannot use answer (constant 42 of type int) as int8 value in variable declaration
1
```

42 cabe perfeitamente num `int8`. A recusa é sobre o tipo: `answer` agora é um `int`, e Go não
transforma um tipo inteiro em outro por conta própria. A lição 10 trata dessa regra e das
conversões que a contornam. **Deixar uma constante sem tipo é o que permite que ela caiba onde for
preciso**, então dê um tipo a ela só quando o tipo faz parte do que a constante significa.

## Maior que qualquer variável

Uma constante inteira sem tipo não está limitada ao tamanho de nenhum tipo inteiro. O compilador
faz a aritmética de constantes de forma exata, e o compilador do Go 1.27.1 aceita até 512 bits
antes de desistir, um limite escrito como `const prec = 512` no código-fonte dele, em
`/usr/local/go/src/cmd/compile/internal/types2/const.go`. Então uma constante pode guardar um valor
que nenhuma variável guardaria:

```go
package main

import "fmt"

const big = 1 << 100

func main() {
	fmt.Println(big >> 98)
	fmt.Println(big / (1 << 90))
}
```

```
ana@vm:~/vars-big$ go run .
4
1024
```

`1 << 100` é 1 deslocado cem casas para a esquerda, 2 elevado a 100. Deslocado de volta 98 casas
dá 4, e dividido por 2 elevado a 90 dá 1024. Os dois resultados são pequenos, então os dois cabem
num `int` quando o `Println` os recebe, e o gigante do meio nunca precisou caber.

**Ela falha no momento em que precisa caber numa variável**:

```go
package main

import "fmt"

const big = 1 << 100

func main() {
	var n int = big
	fmt.Println(n)
}
```

```
ana@vm:~/vars-overflow$ go run .; echo $?
# example.com/vars-overflow
./main.go:8:14: cannot use big (untyped int constant 1267650600228229401496703205376) as int value in variable declaration (overflows)
1
```

A mensagem imprime a constante inteira, todos os 31 dígitos, e diz no que ela estava sendo
transformada: um `int`, que é pequeno demais. A lição 7 trata dos tamanhos dos tipos inteiros. A
diferença a guardar desta lição é quando a verificação acontece. **Uma constante que não cabe é
erro de compilação, então nunca chega a um programa rodando.** Uma variável comum que passa do seu
tamanho em tempo de execução é outra história, também da lição 7.
