---
title: Quando vale pagar
version: 1
---

As seções 04 e 05 deram preço ao cgo em nanossegundos, threads, segundos de build e um binário que
só roda onde estão as bibliotecas dele. Mais dois custos não são números, e depois vem a pergunta a
que a lição inteira leva: **quando vale a pena?** A resposta curta é quando existe uma biblioteca C
de que você precisa e nenhum jeito de substituí-la. A resposta longa é uma lista de lugares onde
procurar antes.

## O C da própria biblioteca padrão

Dois pacotes usam C no Linux sem você pedir: `net`, para resolver nomes de host, e `os/user`, para
contas. A lição 16 mostrou as metades em Go puro deles assumindo quando o cgo está desligado.
**Duas tags de build escolhem as metades em Go puro com o cgo ainda ligado**, o que importa quando
um programa tem C próprio e não pode desligar o cgo. O `lookup/main.go` faz uma pergunta a cada
pacote:

```go
// Command lookup asks two standard packages that can use the C library
// who is running it and what localhost resolves to.
package main

import (
	"fmt"
	"net"
	"os/user"
)

func main() {
	u, err := user.Current()
	fmt.Println(u.Username, err)
	addrs, err := net.LookupHost("localhost")
	fmt.Println(addrs, err)
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./lookup && file bin/lookup | cut -d, -f1,4 && bin/lookup
bin/lookup: ELF 64-bit LSB executable, dynamically linked
ana <nil>
[127.0.0.1] <nil>
ana@vm:~/cgo$ go build -tags netgo,osusergo -o bin/lookup-pure ./lookup && file bin/lookup-pure | cut -d, -f1,4 && bin/lookup-pure
bin/lookup-pure: ELF 64-bit LSB executable, statically linked
ana <nil>
[127.0.0.1] <nil>
ana@vm:~/cgo$ go list -f "{{.ImportPath}} {{.CgoFiles}}" net os/user
net [cgo_linux.go cgo_resnew.go cgo_socknew.go cgo_unix_cgo.go cgo_unix_cgo_res.go]
os/user [cgo_lookup_cgo.go getgrouplist_unix.go]
ana@vm:~/cgo$ go list -tags netgo,osusergo -f "{{.ImportPath}} {{.CgoFiles}}" net os/user
net []
os/user []
```

`go list -f '{{.CgoFiles}}'` lista os arquivos de um pacote que importam `"C"`. **`netgo` e
`osusergo` esvaziam as duas listas, e o binário sai estático** com as mesmas duas respostas. Em
outras máquinas as respostas podem diferir: a biblioteca C pode estar configurada para perguntar
contas a um diretório da empresa, ou para resolver nomes de jeitos que o resolvedor do Go não
implementa, enquanto as metades em Go puro leem só `/etc/passwd` e `/etc/resolv.conf`. As tags não
removem o C que você escreveu: um programa que importa a zlib continua dinâmico, com quaisquer tags.

## Uma falha no C é uma falha do programa

No Go, desreferenciar um ponteiro nil é um pânico, e um `recover` adiado consegue impedir que ele
encerre o programa. **No C, o mesmo erro é um sinal que o runtime do Go não transforma em pânico**:
ele não tem como saber em que estado o código C deixou as coisas, então para tudo. O
`crash/main.go` comete o erro duas vezes, sob o mesmo `recover`:

```go
// Command crash reads through a null pointer twice: once in Go, where
// recover catches it, and once in C, where nothing can.
package main

/*
static int first(const int *p) { return p[0]; }
*/
import "C"

import "fmt"

func try(name string, f func() int) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(name, "recovered:", r)
		}
	}()
	fmt.Println(name, "returned", f())
}

func main() {
	var p *int
	try("go", func() int { return *p })
	try("c", func() int { return int(C.first(nil)) })
	fmt.Println("still running")
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./crash && bin/crash 2>&1 | head -4; echo ${PIPESTATUS[0]}
go recovered: runtime error: invalid memory address or nil pointer dereference
SIGSEGV: segmentation violation
PC=0x49c096 m=0 sigcode=1 addr=0x0
signal arrived during cgo execution
2
```

A metade Go foi recuperada e o programa seguiu. A metade C o matou com status 2 no meio do `try`, e
`still running` nunca foi impresso. `signal arrived during cgo execution` é o runtime dizendo onde
estava; as quatro linhas são o começo de um despejo de todas as goroutines, que o `head` cortou.
Uma biblioteca C com um defeito vira um defeito que leva o processo inteiro junto, com todas as
goroutines. O detector de corrida da lição 15 é um custo no sentido contrário: ele é construído
sobre o cgo, então um pipeline que desliga o cgo para ter binários estáticos fica sem ele.

## Onde procurar antes de escrever `import "C"`

| do que você abre mão | medido nesta lição |
|---|---|
| uma chamada barata | 28,70 ns por chamada contra 0,7894 ns, seção 04 |
| uma goroutine barata | 104 threads para 100 goroutines dormindo no C, contra 6 |
| um binário estático | `libz.so.1`, `libc.so.6` e o carregador, exigidos na execução |
| compilação cruzada | nenhum `aarch64-linux-gnu-gcc`, e nenhuma zlib de ARM para ligar |
| um build frio rápido | 32,722 s para compilar o C do SQLite |
| os erros e as falhas do Go | um arquivo truncado apontado só se você perguntar ao `gzerror`; uma falha do C que o `recover` não pega |

**O cgo vale essa conta quando uma biblioteca C faz algo de que você precisa e que não se obtém de
outro jeito**: um motor de banco de dados, um codec, o SDK de um fabricante para um dispositivo,
uma interface do sistema operacional que o Go não embrulha. Antes de pagar, os lugares onde procurar
são, nesta ordem:

1. **A biblioteca padrão.** `compress/gzip` e `hash/crc32` substituíram os dois usos da zlib nesta
   lição, e o `hash/crc32` foi 9 vezes mais rápido que ela. `crypto`, `image`, `archive` e
   `compress` fazem em Go o que outras linguagens muitas vezes entregam a uma biblioteca C.
2. **Um porte em Go puro.** O trabalho da biblioteca C reescrito ou traduzido para Go: o
   `modernc.org/sqlite` se descreve como "a CGo-free port of the C SQLite3 library", o que, por essa
   descrição, dispensa compilador C no build, para qualquer alvo.
3. **Um processo separado.** Se o C existe como ferramenta de linha de comando, o `os/exec` a roda
   como programa à parte. Uma falha fica naquele processo e o build não muda. O custo por chamada é
   iniciar um processo, o que serve para trabalho feito uma vez por arquivo e é péssimo para
   trabalho feito uma vez por linha.

Quando nada disso serve, **ponha o cgo num pacote pequeno**, como fazem o `cost` e o `gzlines`.
Mantenha tipos C fora da API exportada dele, dê a cada `C.CString` o seu `defer C.free`, ponha os
laços do lado C e respeite as regras de ponteiros em vez de desligá-las. Sem cgo, um pacote assim
falha no build, como o `gzlines` falhou para ARM, que é a falha que você quer: o stub do go-sqlite3
falhou na execução.
