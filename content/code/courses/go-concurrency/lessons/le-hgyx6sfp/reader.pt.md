---
title: O Reader, e o contrato por trás de um método
version: 1
---

Esta lição abre a segunda metade do curso. As lições 1 a 16 foram sobre rodar muitas coisas ao
mesmo tempo; as lições 17 a 30 são sobre a biblioteca padrão de que essas coisas são feitas, e
sobre como testá-las. **Ela começa por duas interfaces, porque quase toda a biblioteca padrão lê
por uma e escreve pela outra.** Um arquivo, uma conexão de rede, o corpo de uma resposta HTTP, um
fluxo comprimido, uma string na memória: cada um é um `io.Reader`, e código escrito contra
`io.Reader` funciona em todos eles sem saber qual recebeu.

O trabalho desta lição mora em `~/rw`, criado com `go mod init example.com/rw`. O `go doc` imprime
a interface a partir do próprio código da biblioteca padrão:

```
ana@vm:~/rw$ go doc io.Reader | head -12
package io // import "io"

type Reader interface {
	Read(p []byte) (n int, err error)
}
    Reader is the interface that wraps the basic Read method.

    Read reads up to len(p) bytes into p. It returns the number of bytes read (0
    <= n <= len(p)) and any error encountered. Even if Read returns n < len(p),
    it may use all of p as scratch space during the call. If some data is
    available but not len(p) bytes, Read conventionally returns what is
    available instead of waiting for more.
```

**Um método.** `Read` enche o quanto puder de `p`, diz em `n` quantos bytes pôs ali e informa em
`err` qualquer coisa que deu errado, inclusive o fim dos dados, que é o valor de erro `io.EOF`. O
parágrafo embaixo dele é o contrato, e o resto de `go doc io.Reader` segue no mesmo tom; as partes
que importam na prática estão nesta seção.

## Chamando à mão

Ninguém chama `Read` à mão em código de verdade, e é exatamente por isso que vale fazer uma vez. Um
`strings.Reader` lê de uma string, oito bytes por vez, salvo como `reader.go`:

```go
// Command reader calls Read by hand, eight bytes at a time.
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	r := strings.NewReader("concurrency is not parallelism")
	buf := make([]byte, 8)
	for {
		n, err := r.Read(buf)
		fmt.Printf("n=%d err=%v %q\n", n, err, buf[:n])
		if err == io.EOF {
			break
		}
	}
}
```

```
ana@vm:~/rw$ go run reader.go
n=8 err=<nil> "concurre"
n=8 err=<nil> "ncy is n"
n=8 err=<nil> "ot paral"
n=6 err=<nil> "lelism"
n=0 err=EOF ""
```

Trinta bytes saíram como 8, 8, 8 e 6, e depois veio uma chamada que não devolveu nada e `EOF`. **Quem
chama usa `buf[:n]` e nunca `buf`**: a quarta chamada encheu só seis bytes, e os dois últimos bytes
de `buf` ainda guardavam `al` da terceira. Imprimir `buf` inteiro teria mostrado dados velhos como se
fossem novos.

## Escrevendo um

Qualquer tipo com esse método é um Reader. Este produz o alfabeto, salvo como `alphabet.go`:

```go
// Command alphabet is a Reader of its own: the letters a to z, then the end.
package main

import (
	"fmt"
	"io"
	"os"
)

type alphabet struct {
	next byte
}

func (a *alphabet) Read(p []byte) (int, error) {
	if a.next == 0 {
		a.next = 'a'
	}
	n := 0
	for n < len(p) && a.next <= 'z' {
		p[n] = a.next
		n++
		a.next++
	}
	if a.next > 'z' {
		return n, io.EOF
	}
	return n, nil
}

func main() {
	a := &alphabet{}
	buf := make([]byte, 10)
	for {
		n, err := a.Read(buf)
		fmt.Printf("n=%d err=%v %q\n", n, err, buf[:n])
		if err == io.EOF {
			break
		}
	}

	all, err := io.ReadAll(&alphabet{})
	fmt.Printf("ReadAll: %s %v\n", all, err)

	io.Copy(os.Stdout, io.LimitReader(&alphabet{}, 5))
	fmt.Println()
}
```

```
ana@vm:~/rw$ go run alphabet.go
n=10 err=<nil> "abcdefghij"
n=10 err=<nil> "klmnopqrst"
n=6 err=EOF "uvwxyz"
ReadAll: abcdefghijklmnopqrstuvwxyz <nil>
abcde
```

**A última chamada devolveu seis letras e `EOF` juntos**, o que o contrato permite e o
`strings.Reader` por acaso não fez. Então a regra para quem chama é a da documentação: **use os `n`
bytes primeiro, depois olhe o `err`.** Um laço que conferisse `err` primeiro e saísse no `EOF` teria
perdido `uvwxyz`.

As duas últimas linhas são o retorno de ter uma interface. `io.ReadAll` não sabe nada de
alfabetos, lê até o `EOF` e não informa erro, porque chegar ao fim é o que pediram a ele.
`io.LimitReader` embrulha qualquer Reader num que para depois de cinco bytes, e `io.Copy` move o que
lê para a saída padrão. Nenhuma dessas funções foi escrita para este tipo, e as duas funcionam com
ele, que é a base da seção 04 desta lição.
