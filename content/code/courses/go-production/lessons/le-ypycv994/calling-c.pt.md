---
title: Uma função C num arquivo Go
version: 1
---

Muita gente imagina o cgo como uma chamada a função estrangeira que o Go faz em tempo de execução,
do jeito que o `ctypes` do Python abre uma biblioteca e procura um símbolo pelo nome. **É uma etapa
do build.** Um arquivo Go que importa o pseudopacote `"C"` passa por uma ferramenta chamada `cgo`
antes que o compilador o veja. O `cgo` escreve arquivos Go e C a partir dele, o `gcc` compila a
metade C e o ligador junta as duas num binário só. Quando o programa roda, uma chamada ao C é uma
chamada comum a código de máquina que foi ligado ao binário, com a ponte entre as duas linguagens
na frente.

A lição 16 montou um programa de três linhas que fazia isso e seguiu adiante. Esta seção desmonta
o mesmo mecanismo: onde o C fica, como os tipos dele encontram os do Go, como indicar uma
biblioteca C e o que o comando go roda para tudo funcionar.

## O preâmbulo

Todos os programas desta lição moram num módulo só, `~/cgo`, criado com
`go mod init example.com/cgo`, um diretório por programa. O primeiro, `first/main.go`:

```go
// Command first calls two C functions: one written in the comment above
// import "C", and one from the C maths library.
package main

/*
#cgo LDFLAGS: -lm
#include <math.h>

// mean divides in floating point, which C's integer division would not.
static double mean(long total, int n) {
	return (double)total / n;
}
*/
import "C"

import "fmt"

func main() {
	total, n := 7, 2
	m := C.mean(C.long(total), C.int(n))
	fmt.Printf("%T %v\n", m, m)
	fmt.Printf("%.4f\n", float64(C.cbrt(m)))
	fmt.Println(C.sizeof_long, C.sizeof_int, C.sizeof_double)
}
```

**O comentário logo acima de `import "C"` é código C**, e a documentação do cgo o chama de
preâmbulo. Ele é compilado como o cabeçalho da metade C do pacote, então tudo o que é declarado
nele pode ser chamado do Go como membro de `C`. Aqui, isso é `mean`, uma função escrita ali mesmo,
e `cbrt`, a raiz cúbica, que o `math.h` declara e a biblioteca matemática do C define. "Logo acima"
é literal. A regra da documentação é que o comentário preceda o import imediatamente, então uma
linha em branco entre os dois transforma o preâmbulo num comentário comum e cada nome `C.` num
erro. É por isso que, por convenção, o `import "C"` fica numa linha só dele, separado dos outros
imports, com o preâmbulo encostado em cima.

Uma linha do preâmbulo não é C. **`#cgo LDFLAGS: -lm` é uma diretiva para o cgo**, lida e removida
antes que o `gcc` veja o resto, e diz ao build para passar `-lm`, "ligue a biblioteca matemática",
ao ligador. `#cgo CFLAGS:` faz o mesmo para o compilador, e `#cgo pkg-config: zlib` pede as duas
coisas ao `pkg-config`. As flags que uma diretiva pode levar são limitadas, sobretudo a `-D`, `-U`,
`-I` e `-l`, porque o código de uma dependência não deveria poder entregar ao seu compilador a
opção que quiser. As variáveis `CGO_CFLAGS` e `CGO_LDFLAGS` passam o resto, vindo do seu ambiente
e não do código de outra pessoa.

## Tipos que não se misturam

O cgo vem ligado por padrão onde quer que o comando go encontre um compilador C, e ele diz qual
vai usar:

```
ana@vm:~/cgo$ go env CC CXX CGO_ENABLED
gcc
g++
1
```

Compilado e executado, o `first` imprime um tipo, uma raiz cúbica e três tamanhos. O build aparece
por inteiro mais abaixo; isto é o que o programa disse:

```
ana@vm:~/cgo$ GOCACHE=/tmp/cgo-cold go build -x -o bin/ ./first 2> build.log && bin/first
main._Ctype_double 3.5
1.5183
8 4 8
```

**Todo tipo C tem um gêmeo Go com nome próprio.** `C.double` é o tipo Go `main._Ctype_double`, e o
mesmo vale para `C.int`, `C.long`, `C.size_t` e `C.char`. Eles são diferentes de `float64` e `int`
do Go mesmo quando os bits coincidem. Também pertencem ao pacote que escreveu `import "C"`, então
um `C.int` de um pacote é um tipo diferente de um `C.int` de outro, e é por isso que a documentação
recomenda nunca pôr tipos C na API exportada de um pacote. A última linha mostra por que os nomes
ficam separados. `C.sizeof_long` é 8 e `C.sizeof_int` é 4 nesta máquina, enquanto o `int` do Go
tem 8: um `int` do C e um `int` do Go não têm o mesmo tamanho, e no Windows de 64 bits um `long`
do C tem 4 bytes, e não 8.

Então **todo valor atravessa com uma conversão explícita**, `C.long(total)` na ida e
`float64(...)` na volta. Deixar as conversões de fora é erro de compilação, e o jeito mais rápido
de ver isso é uma cópia do `first` sem elas, feita com `sed`:

```
ana@vm:~/cgo$ mkdir -p noconv && sed 's/C.long(total), C.int(n)/total, n/' first/main.go > noconv/main.go && go build -o bin/ ./noconv
# example.com/cgo/noconv
noconv/main.go:20:14: cannot use total (variable of type int) as C.long value in argument to (C.mean)
noconv/main.go:20:21: cannot use n (variable of type int) as C.int value in argument to (C.mean)
```

Esse rigor é do tipo útil. O compilador Go confere cada chamada ao C com a declaração do
preâmbulo, pelas mesmas regras que aplica ao código Go, então um número errado de argumentos ou um
ponteiro onde deveria haver um número falha aqui, e não em tempo de execução.

## Uma biblioteca que não foi ligada

O outro erro aparece um passo adiante, na ligação. Uma cópia sem a linha `LDFLAGS` compila, porque
o `math.h` continua declarando `cbrt`. Aí o ligador não tem a que juntar a chamada:

```
ana@vm:~/cgo$ mkdir -p nolm && grep -v LDFLAGS first/main.go > nolm/main.go && go build -o bin/ ./nolm 2>&1 | grep -E "running gcc|undefined"
/usr/local/go/pkg/tool/linux_amd64/link: running gcc failed: exit status 1
/tmp/go-build/main.cgo2.c:54:(.text+0x1a): undefined reference to `cbrt'
```

**Um cabeçalho diz ao compilador que uma função existe; só a biblioteca dá ao ligador o código
dela.** A mensagem completa é uma página de linha de comando do `gcc`, que o `grep` reduz às duas
linhas que importam: o ligador do Go rodou o `gcc` para terminar o serviço, e o `gcc` não achou
`cbrt` em nada do que recebeu. `undefined reference` num build com cgo quase sempre significa um
`-l` faltando em `LDFLAGS`, ou uma biblioteca cujo pacote de desenvolvimento não está instalado.

## O que o comando go rodou

A flag `-x` imprime cada comando que um build roda. O build acima usou um cache vazio em
`/tmp/cgo-cold`, para nada vir de uma execução anterior, e guardou a lista em `build.log`. Ela é
longa, quase toda ocupada pela compilação da biblioteca padrão, e o trabalho do pacote principal é
a parte sob `$WORK/b001`. O segundo comando fica com essas linhas e, de cada uma, com o programa
que ela rodou e os dois últimos argumentos:

```
ana@vm:~/cgo$ wc -l < build.log
859
ana@vm:~/cgo$ grep b001 build.log | grep -v '#' | grep -E '^([A-Z_]+=[^ ]* )*(gcc|[^ ]*/(cgo|compile|link)) ' | sed -E 's/^([A-Z_]+=[^ ]* )+//' | awk '{print $1, $(NF-1), $NF}'
/usr/local/go/pkg/tool/linux_amd64/cgo -g ./main.go
gcc -c _cgo_export.c
gcc -c main.cgo2.c
gcc -c _cgo_main.c
gcc -g -lm
/usr/local/go/pkg/tool/linux_amd64/cgo -dynout $WORK/b001/_cgo_import.go
/usr/local/go/pkg/tool/linux_amd64/compile $WORK/b001/main.cgo1.go $WORK/b001/_cgo_import.go
/usr/local/go/pkg/tool/linux_amd64/link -extld=gcc $WORK/b001/_pkg_.a
```

Lido de cima para baixo, é a sequência do primeiro parágrafo:

| passo | o que faz |
|---|---|
| `cgo ./main.go` | divide o arquivo: `main.cgo1.go`, a metade Go com cada `C.x` reescrito como chamada a código gerado, e `main.cgo2.c`, o preâmbulo mais um pequeno invólucro C para cada função chamada |
| `gcc -c` três vezes | compila a metade C e os arquivos que o cgo gerou em volta dela |
| `gcc -g -lm` | liga esses objetos uma vez com `-lm`, para descobrir quais símbolos vêm de bibliotecas compartilhadas |
| `cgo -dynout` | anota essa resposta como Go, em `_cgo_import.go` |
| `compile` | compila a metade Go, o mesmo compilador de sempre |
| `link -extld=gcc` | liga o programa e entrega o passo final ao `gcc` |

**Um build com cgo roda o `gcc` pelo menos cinco vezes para um preâmbulo de sete linhas**, e cada
execução é um ponto em que o ferramental C, os cabeçalhos e as bibliotecas dele precisam estar
presentes e certos. É isso que o `CGO_ENABLED=1` vinha informando o tempo todo, e é o fio que as
duas últimas seções desta lição puxam.
