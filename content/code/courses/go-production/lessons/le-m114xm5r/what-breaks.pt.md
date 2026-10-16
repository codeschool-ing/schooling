---
title: O que muda com o alvo
version: 1
---

O `hits` foi compilado para outras máquinas sem uma palavra de reclamação, e é tentador concluir que
qualquer programa Go seria. **Três coisas num build dependem do alvo.** Cada uma pode transformar um
programa que compila aqui num que não compila para outra máquina, ou que compila em outra coisa: o
cgo, os arquivos que um pacote escolhe por sistema operacional e processador, e o processador mais
antigo que o código pode supor.

## O cgo fica desligado a menos que você o ligue

A seção do laboratório da lição 1 mostrou `CGO_ENABLED` caindo para `0` numa máquina sem compilador
C. Builds cruzados também o derrubam, numa máquina que tem um:

```
ana@vm:~/cross$ go env CGO_ENABLED; GOARCH=arm64 go env CGO_ENABLED; GOOS=windows go env CGO_ENABLED
1
0
0
```

**O `gcc` da máquina gera código para a máquina**, então o comando go não lhe entrega um build
cruzado. A documentação do cgo diz isso numa frase: o cgo "is disabled by default when
cross-compiling". O custo depende do programa, e há dois casos que valem a pena ver.

### Um pacote com duas implementações

Alguns pacotes padrão fazem o seu trabalho ou pela biblioteca C ou em Go puro, e escolhem conforme o
cgo esteja ligado. O `os/user`, que consulta contas, é um deles. Um programa que pergunta a ele quem
está rodando, `who/main.go`:

```go
// Command who prints the user running it and their home directory.
package main

import (
	"fmt"
	"os/user"
)

func main() {
	u, err := user.Current()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(u.Username, u.HomeDir)
}
```

Ele fica num módulo próprio, `~/cross/who`, criado com `go mod init example.com/who`. Compilado para
esta máquina e para `arm64`:

```
ana@vm:~/cross/who$ go build -o who . && GOARCH=arm64 go build -o who-arm64 .
ana@vm:~/cross/who$ file who who-arm64 | cut -d, -f1,2,4
who:       ELF 64-bit LSB executable, x86-64, dynamically linked
who-arm64: ELF 64-bit LSB executable, ARM aarch64, statically linked
ana@vm:~/cross/who$ ./who; qemu-aarch64-static ./who-arm64
ana /home/ana
ana /home/ana
ana@vm:~/cross/who$ go list -f '{{.CgoFiles}}' os/user; GOARCH=arm64 go list -f '{{.CgoFiles}}' os/user
[cgo_lookup_cgo.go getgrouplist_unix.go]
[]
```

**O build nativo sai `dynamically linked` e o cruzado sai `statically linked`**, das mesmas
dezesseis linhas. `go list -f '{{.CgoFiles}}'` lista os arquivos de um pacote que usam cgo, e a
resposta depende do alvo. No nativo o pacote compila dois arquivos cgo que chamam as funções de
conta da biblioteca C, e para `arm64` não compila nenhum e usa a outra implementação, que lê
`/etc/passwd` e `/etc/group` por conta própria. Aqui as duas acharam Ana. Numa máquina em que as
contas vêm de um diretório da empresa que a biblioteca C está configurada para consultar, a versão
em Go puro só enxerga o que `/etc/passwd` lista, e os dois builds podem discordar sobre um usuário.
O `net` tem a mesma divisão para resolver nomes de máquinas.

### Um pacote que precisa de C

Um programa que chama C ele mesmo não tem segunda implementação para onde recuar. Aqui está o menor
possível, num módulo próprio em `~/cross/twice`. A lição 23 trata do que o comentário acima de
`import "C"` faz; aqui basta saber que o `gcc` compila a função C que está nele. `twice/main.go`:

```go
// Command twice asks a C function to double a number.
package main

// int twice(int x) { return 2 * x; }
import "C"

import "fmt"

func main() {
	fmt.Println(C.twice(21))
}
```

```
ana@vm:~/cross/twice$ go build -o twice . && ./twice
42
ana@vm:~/cross/twice$ GOARCH=arm64 go build -o twice-arm64 .; echo $?
package example.com/twice: build constraints exclude all Go files in /home/ana/cross/twice
1
ana@vm:~/cross/twice$ CGO_ENABLED=1 GOARCH=arm64 go build -o twice-arm64 . 2>&1 | head -4
# runtime/cgo
gcc_arm64.S: Assembler messages:
gcc_arm64.S:30: Error: no such instruction: `stp x29,x30,[sp,'
gcc_arm64.S:34: Error: operand size mismatch for `mov'
```

No nativo ele imprime 42. Para `arm64` o build falha com uma mensagem que nem menciona o cgo. **Um
arquivo que importa `"C"` só é compilado com o cgo ligado**, então com o cgo desligado o comando go
deixou o `main.go` de fora, e um pacote sem nenhum arquivo é o erro que ele relata. Ligar o cgo à
mão vai mais longe e falha pior. O comando go entregou ao `gcc` da máquina o assembly ARM do próprio
runtime, e um assembler de instruções Intel nunca ouviu falar de `stp x29,x30`. Um programa com cgo
para outro processador precisa de um compilador C para aquele processador, indicado na variável
`CC`; a lição 23 volta a isso, e esta lição não instala nenhum.

## Arquivos escolhidos pelo alvo

A resposta do `os/user` acima veio da seleção de arquivos. O `cgo_lookup_cgo.go` só é compilado com
o cgo ligado, o `lookup_unix.go` só em sistemas do tipo Unix, e um pacote pode ter um arquivo por
sistema operacional ou por processador. **O build lê um conjunto diferente de arquivos para cada
alvo**, então um pacote pode compilar para `linux` e falhar para `windows` porque o arquivo que
define uma função para Windows nunca foi escrito. As regras, escritas como um nome de arquivo do
tipo `x_windows.go` ou uma linha `//go:build` no topo de um arquivo, são assunto da lição 11. O que
importa aqui é reconhecer o sintoma: a mensagem acima que diz *build constraints exclude all Go
files*, ou um erro `undefined:` que aparece para um alvo só.

O `hits` não tem nada disso. Ele não importa nada que precise de C e não tem arquivo para um sistema
só, e é por isso que os quatro builds da seção 02 só precisaram das duas variáveis.

## Mesma arquitetura, processador mais antigo

`GOARCH` indica um conjunto de instruções, e todo conjunto de instruções cresceu com os anos. Mais
quatro variáveis escolhem quanto desse crescimento o compilador pode usar: `GOARM` para ARM de 32
bits, `GOARM64` para ARM de 64 bits, `GOAMD64` para Intel e AMD, e `GO386` para Intel de 32 bits. O
`go help environment` lista os valores de cada uma. O ARM de 32 bits é onde a escolha aparece com
mais frequência, porque placas antigas continuam em serviço:

```
ana@vm:~/cross$ GOARCH=arm go env GOARM
7
ana@vm:~/cross$ GOARCH=arm GOARM=6 go build -o hits-armv6 . && file hits-armv6 | cut -d, -f1,2
hits-armv6: ELF 32-bit LSB executable, ARM
ana@vm:~/cross$ qemu-arm-static ./hits-armv6 top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
```

**O padrão de um build cruzado para `arm` é ARMv7**, e o primeiro Raspberry Pi e o Pi Zero têm
processadores ARMv6, que não têm algumas das instruções que código ARMv7 usa. `GOARM=6` compila para
eles, e o `qemu-arm-static`, o emulador de ARM de 32 bits, rodou o resultado e imprimiu as mesmas
duas linhas que todos os outros builds desta lição.

Na Intel e na AMD os níveis se chamam `v1` a `v4`. O `v1` é o conjunto de instruções de 64 bits de
2003 e é o padrão; o `v3` acrescenta, entre outras, as instruções AVX2, BMI e FMA dos processadores
Intel de 2013 em diante. Um build `v3` deixa o compilador usá-las, e o runtime confere na partida se
o processador realmente as tem. O QEMU consegue fingir ser um processador mais antigo com `-cpu`, e
`Nehalem` é um projeto da Intel de 2008:

```
ana@vm:~/cross$ go env GOAMD64
v1
ana@vm:~/cross$ GOAMD64=v3 go build -o hits-v3 . && go version -m hits-v3 | grep GOAMD64
	build	GOAMD64=v3
ana@vm:~/cross$ ./hits-v3 top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cross$ qemu-x86_64-static -cpu Nehalem ./hits-v3 top -n 2 access.log; echo $?
This program can only be run on AMD64 processors with v3 microarchitecture support.
1
ana@vm:~/cross$ qemu-x86_64-static -cpu Nehalem ./hits top -n 2 access.log; echo $?
path         requests
/login       2576
/api/orders  2542
0
```

**O binário `v3` se recusou a iniciar no processador mais antigo**, com uma mensagem de uma linha e
status 1, antes de o `main` rodar; o binário `v1` da seção 02 rodou nele sem mudança. Essa recusa é
o custo de subir o nível, e a checagem existe para que ele seja claro, e não uma falha na primeira
instrução AVX2 no meio de uma execução. Se o nível compra alguma coisa para um programa é pergunta
para um benchmark, do tipo que a lição 29 do `go-concurrency` escreve. Até um benchmark dizer que
sim, **distribua `v1`**, que todo processador Intel e AMD de 64 bits roda.
