---
title: Interfaces pequenas, declaradas onde são usadas
version: 1
---

Quem está acostumado a hierarquias de classes costuma projetar uma interface do jeito que
projetaria uma classe base: tudo o que um tipo de objeto sabe fazer, uma dúzia de métodos, escrita
ao lado do tipo que os implementa. A biblioteca padrão de Go vai pelo outro caminho, e o pacote
`io` é o lugar mais claro para ver isso. Este programa pergunta ao verificador de tipos,
`go/types`, quantos métodos tem cada interface de `io`. Você não precisa acompanhar como ele
funciona, só o que ele imprime:

```go
package main

import (
	"fmt"
	"go/importer"
	"go/token"
	"go/types"
)

func main() {
	pkg, err := importer.ForCompiler(token.NewFileSet(), "source", nil).Import("io")
	if err != nil {
		fmt.Println(err)
		return
	}
	byCount := map[int][]string{}
	for _, name := range pkg.Scope().Names() {
		t := pkg.Scope().Lookup(name).Type()
		if t.String() != "io."+name || !types.IsInterface(t) {
			continue
		}
		n := types.NewMethodSet(t).Len()
		byCount[n] = append(byCount[n], name)
	}
	for n := 1; n <= 3; n++ {
		fmt.Println(n, len(byCount[n]), byCount[n])
	}
}
```

```
ana@vm:~/ifaces-count$ go run .
1 12 [ByteReader ByteWriter Closer Reader ReaderAt ReaderFrom RuneReader Seeker StringWriter Writer WriterAt WriterTo]
2 7 [ByteScanner ReadCloser ReadSeeker ReadWriter RuneScanner WriteCloser WriteSeeker]
3 3 [ReadSeekCloser ReadWriteCloser ReadWriteSeeker]
```

Vinte e duas interfaces, e **doze delas têm exatamente um método**. Nenhuma tem mais de três, e as
maiores são as pequenas juntas: um `ReadWriter` é um `Reader` e um `Writer`, e a lição 29 mostra
como isso se escreve. O conjunto de métodos da lição 26 é o que o programa contou.

## Por que um método é o tamanho útil

Cada método que uma interface acrescenta é mais uma coisa que um tipo precisa ter antes de se
encaixar. Uma interface com dez métodos é satisfeita pelos poucos tipos escritos para ela; uma
interface com um é satisfeita por todo tipo que por acaso faça essa única coisa. `io.Reader` é a
outra metade de `io.Writer`:

```
ana@vm:~/ifaces-count$ go doc io.Reader | head -5
package io // import "io"

type Reader interface {
	Read(p []byte) (n int, err error)
}
```

Uma função que precisa ler e nada mais deve pedir exatamente isso. Esta conta as palavras do que
receber:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
)

func countWords(r io.Reader) (int, error) {
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	n := 0
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

func main() {
	n, err := countWords(strings.NewReader("one function, three readers"))
	fmt.Println("string:", n, err)

	f, err := os.Open("notes.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	n, err = countWords(f)
	f.Close()
	fmt.Println("file:  ", n, err)

	n, err = countWords(os.Stdin)
	fmt.Println("stdin: ", n, err)
}
```

```
ana@vm:~/ifaces-reader$ printf 'typed into a pipe\n' | go run .
string: 4 <nil>
file:   12 <nil>
stdin:  4 <nil>
```

O `bufio.Scanner` lê de qualquer `io.Reader` e devolve uma palavra por `Scan`; `<nil>` é como um
erro ausente aparece impresso, e a lição 32 trata de erros. A mesma função contou uma string na
memória, as duas linhas de `notes.txt` e o que o shell mandou pelo pipe para o programa. Se ela
pedisse um `*os.File`, aceitaria o arquivo e o `os.Stdin`, que também é um `*os.File`, e a string
teria de ser gravada em disco antes. **Pedir a menor interface que resolve é o que deixa uma
função servir a quem chama de jeitos que o autor dela nunca imaginou.**

## Aceite interfaces, devolva tipos concretos

A outra metade do hábito está na saída. As funções que criam leitores não devolvem um
`io.Reader`. Devolvem o próprio tipo:

```
ana@vm:~/ifaces-reader$ go doc strings.NewReader
package strings // import "strings"

func NewReader(s string) *Reader
    NewReader returns a new Reader reading from s. It is similar to
    bytes.NewBufferString but more efficient and non-writable.

ana@vm:~/ifaces-reader$ go doc os.Open | head -3
package os // import "os"

func Open(name string) (*File, error)
```

`os.Open` devolve um `*os.File`, com todos os métodos dele: `Read`, mas também `Close`, de que o
programa acima precisou, e `Write`, `Stat` e o resto. Se devolvesse um `io.Reader`, quem chama
perderia o `Close` e não teria como recuperá-lo sem as asserções de tipo da lição 29. Um resultado
concreto não custa nada a quem chama, porque ele ainda pode ser passado onde quer que se peça uma
interface, como `f` foi. **Aceite a menor interface de que precisa, e devolva o tipo concreto que
tem.**

## Declare a interface perto do código que precisa dela

Como nada precisa nomear uma interface para satisfazê-la, a interface não precisa morar com os
tipos. Ela pode morar com a função que a usa, até num programa que não é dono de nenhum dos tipos:

```go
package main

import (
	"fmt"
	"time"
)

type labeler interface {
	String() string
}

func show(items ...labeler) {
	for _, it := range items {
		fmt.Printf("%-15T %s\n", it, it.String())
	}
}

func main() {
	show(90*time.Minute, time.Saturday, time.August)
}
```

```
ana@vm:~/ifaces-local$ go run .
time.Duration   1h30m0s
time.Weekday    Saturday
time.Month      August
```

`labeler` foi escrita para este programa, com nome minúsculo para que nenhum outro pacote a veja
(lição 39). `time.Duration`, `time.Weekday` e `time.Month` são da biblioteca padrão, e cada um tem
um método `String`: é por causa dele que `time.Saturday` apareceu como `Saturday` com `%v` na
lição 6. Os três satisfazem uma interface que não existia até este arquivo ser escrito. Numa
linguagem em que um tipo lista as interfaces que implementa, `show` precisaria antes de uma
mudança no pacote `time`.

É esse o motivo do conselho de definir uma interface onde ela é usada, e não onde é implementada.
A função sabe quais métodos chama, então é ela quem pode dizer quão pequena a interface pode ser, e
**os tipos que ela aceita nunca precisam mudar para caber nela**.
