---
title: Onde um valor mora: a pilha e o heap
version: 1
---

Quem chega de C traz uma regra consigo. Uma variável local mora na pilha e morre quando a função
retorna, `malloc` põe um valor no heap, e devolver o endereço de uma variável local é um bug que
derruba o programa um pouco depois. **Em Go você nunca escolhe onde um valor mora. O compilador
escolhe, e devolver o endereço de uma variável local é seguro porque o compilador antes tira essa
variável do caminho.** A lição 23 devolveu um ponteiro assim e disse que era seguro; esta seção
mostra o compilador decidindo.

Vale dar nome aos dois lugares antes do programa:

- A **pilha** (stack) guarda as variáveis das chamadas de função que ainda estão rodando. Cada
  chamada ganha um quadro, e o quadro inteiro é devolvido de uma vez quando a chamada retorna.
  Ninguém precisa encontrar esses valores depois, então liberá-los não custa nada.
- O **heap** guarda os valores que podem viver mais que a chamada que os criou. Um valor fica lá
  até o coletor de lixo, na seção 03, descobrir que nada aponta mais para ele.

**A regra do compilador é a análise de escape:** se ele consegue provar que um valor não é usado
depois que a função retorna, o valor vai para o quadro; se não consegue provar, o valor **escapa**
para o heap. Cinco funções pequenas em `~/memory`, cada uma fazendo uma coisa diferente com o que
cria:

```schooling-example
{
  "language": "go",
  "file": "funcs.go",
  "parts": [
    {
      "code": "package main\n\ntype point struct{ x, y int }\n",
      "note": "Uma struct de dois `int`, 16 bytes, da lição 15."
    },
    {
      "code": "\nfunc sum() int {\n\tnums := [4]int{1, 2, 3, 4}\n\ttotal := 0\n\tfor _, n := range nums {\n\t\ttotal += n\n\t}\n\treturn total\n}\n",
      "note": "**Nada criado aqui vive mais que a chamada.** O array é lido e a função devolve a cópia de um número, então o array mora no quadro de `sum`. O compilador não imprime linha nenhuma sobre ele."
    },
    {
      "code": "\nfunc newPoint() *point {\n\tp := point{1, 2}\n\treturn &p\n}\n",
      "note": "O endereço de `p` sai no resultado, então `p` não pode morrer junto com o quadro. O compilador diz `moved to heap: p`, e o ponteiro de quem chamou continua válido enquanto alguém o guardar."
    },
    {
      "code": "\nfunc squares(n int) []int {\n\ts := make([]int, n)\n\tfor i := range s {\n\t\ts[i] = i * i\n\t}\n\treturn s\n}\n",
      "note": "A slice é devolvida, e junto com ela o array para o qual aponta. `make([]int, n) escapes to heap`. A slice em si, um ponteiro, um comprimento e uma capacidade, volta por valor como qualquer resultado."
    },
    {
      "code": "\nfunc count() int {\n\tbuf := make([]int, 0, 8)\n\tbuf = append(buf, 1, 2, 3)\n\treturn len(buf)\n}\n",
      "note": "O mesmo `make`, outro destino: só um comprimento sai desta função. `make([]int, 0, 8) does not escape`, nem o `append` dentro dele, então o array de 64 bytes fica no quadro."
    },
    {
      "code": "\nfunc large() int {\n\tvar table [200_000]int\n\ttable[7] = 7\n\treturn table[7]\n}\n",
      "note": "Aqui também nada escapa, e mesmo assim o compilador diz `moved to heap: table`. 200.000 `int` são 1,6 MB, e **um quadro tem limite de tamanho**: uma variável acima dele vai para o heap, seja qual for o resultado da análise de escape."
    }
  ]
}
```

`-gcflags` passa flags ao compilador. As duas usadas aqui, como a própria ajuda do compilador as
descreve:

```
ana@vm:~/memory$ go tool compile -help 2>&1 | grep -E "^  -(l|m)\b"
  -l	disable inlining
  -m	print optimization decisions
```

`-m` pede as decisões do compilador, e `-l` desliga o inlining, o que mantém o veredito de cada
função numa linha só, em vez de repetido dentro de cada função que a chama. O `grep` fica com as
linhas sobre `funcs.go`; as outras falam de `main.go`, o programa que mede, mais abaixo:

```
ana@vm:~/memory$ go build -gcflags="-m -l" . 2>&1 | grep funcs.go
./funcs.go:15:2: moved to heap: p
./funcs.go:20:11: make([]int, n) escapes to heap
./funcs.go:28:13: make([]int, 0, 8) does not escape
./funcs.go:29:14: append does not escape
./funcs.go:34:6: moved to heap: table
```

O limite de tamanho da última nota está escrito no código-fonte do compilador, e para uma variável
que você declara ele é de 128 KiB:

```
ana@vm:~/memory$ sed -n 8,11p /usr/local/go/src/cmd/compile/internal/ir/cfg.go
	// MaxStackVarSize is the maximum size variable which we will allocate on the stack.
	// This limit is for explicit variable declarations like "var x T" or "x := ...".
	// Note: the flag smallframes can update this value.
	MaxStackVarSize = int64(128 * 1024)
```

## O que escapar custa

Um valor no heap é uma **alocação**: o runtime precisa achar espaço para ele agora, e o coletor
precisa encontrá-lo de novo depois. `testing.AllocsPerRun` chama uma função muitas vezes e informa
a média de alocações por chamada. Ela pertence ao pacote `testing`, mas é uma função comum e o
`main` pode chamá-la:

```go
package main

import (
	"fmt"
	"testing"
)

var (
	keptPoint *point
	keptInts  []int
	n         int
)

func main() {
	fmt.Println("sum      ", testing.AllocsPerRun(100, func() { n = sum() }))
	fmt.Println("newPoint ", testing.AllocsPerRun(100, func() { keptPoint = newPoint() }))
	fmt.Println("squares  ", testing.AllocsPerRun(100, func() { keptInts = squares(100) }))
	fmt.Println("count    ", testing.AllocsPerRun(100, func() { n = count() }))
	fmt.Println("large    ", testing.AllocsPerRun(100, func() { n = large() }))
}
```

```
ana@vm:~/memory$ go run .
sum       0
newPoint  1
squares   1
count     0
large     1
```

Os números batem um a um com as linhas do compilador: as três funções que ele citou põem um valor
no heap por chamada, e as duas sobre as quais ele não disse nada, ou disse `does not escape`, não
põem nenhum. Os resultados vão para variáveis de pacote para que o compilador não conclua que as
chamadas são inúteis e as descarte.

**Nada disso muda o que o programa significa**, só o que ele custa. `newPoint` está correta de
qualquer jeito, e o mesmo código-fonte pode ser julgado de outra forma pela próxima versão do
compilador. A maior parte do código deve ser escrita para quem lê e medida antes que alguém a
reorganize para evitar uma alocação. O valor do `-m` é que a medição vem com um motivo ao lado.

## Os quatro primeiros elementos da lição 12

A seção 03 da lição 12 notou que uma slice que cresce com `append` começava com capacidade 4, e
com 1 quando a slice ficava guardada numa variável de pacote. Os dois programas dela, copiados sem
mudança para `~/memory-grow` e `~/memory-grow-kept`, dão o motivo:

```
ana@vm:~/memory-grow$ go build -gcflags="-m -l" . 2>&1 | grep append
./main.go:9:13: append does not escape
ana@vm:~/memory-grow-kept$ go build -gcflags="-m -l" . 2>&1 | grep append
./main.go:11:13: append escapes to heap
ana@vm:~/memory-grow$ grep -n "VariableMakeThreshold = " /usr/local/go/src/cmd/compile/internal/base/flag.go
190:	Debug.VariableMakeThreshold = 32 // 32 byte default for stack allocated make results
```

Quando a slice nunca escapa, o compilador dá ao primeiro array dela um espaço de 32 bytes no
quadro, que cabe quatro `int`, e o heap só é chamado quando a slice passa disso. Quando a slice é
guardada, nada dela pode ficar no quadro, e o crescimento começa no heap, em 1.
