---
title: Memória dos dois lados da linha
version: 1
---

O Go libera memória quando nada mais aponta para ela; o C a libera quando alguém chama `free`. Uma
chamada de um para o outro cruza entre esses dois mundos, e **os defeitos pelos quais o cgo é
conhecido são quase todos sobre qual lado é dono de um pedaço de memória**. Uma string C que
ninguém libera vaza enquanto o processo viver. Um ponteiro Go que o C guarda depois que a chamada
retorna aponta, mais cedo ou mais tarde, para memória que o coletor moveu ou reaproveitou. Nenhum
dos dois aparece num teste que roda por um segundo.

As regras são curtas, e a documentação do cgo as enuncia numa seção chamada "Passing pointers".
Esta seção as encontra numa biblioteca C de verdade, e não numa função escrita num comentário: a
zlib, a biblioteca que lê e escreve o formato gzip.

## Uma biblioteca de verdade: contando as linhas de um arquivo gzip

O `gzlines` abre um log comprimido com a zlib, lê em pedaços de 64 KiB e conta as quebras de linha.
Cada chamada ao C nele passa memória pela linha numa direção ou na outra, e as notas dizem qual.
`gzlines/main.go`:

```schooling-example
{
  "language": "go",
  "file": "gzlines/main.go",
  "parts": [
    {
      "code": "// Command gzlines counts the lines of a gzip-compressed file, reading it\n// through zlib, the C library behind gzip.\npackage main\n",
      "note": "A zlib é a biblioteca C por trás do `gzip` e de muito mais. Compilar com ela exige os arquivos de desenvolvimento, o cabeçalho e a biblioteca para ligar, que o Ubuntu empacota como `zlib1g-dev`: `sudo apt install zlib1g-dev`. A máquina do laboratório já os tinha."
    },
    {
      "code": "/*\n#cgo LDFLAGS: -lz\n#include <stdlib.h>\n#include <zlib.h>\n*/\nimport \"C\"\n",
      "note": "`-lz` liga a zlib, do jeito que `-lm` ligou a biblioteca matemática na seção 02. O `stdlib.h` está ali por causa do `free`: **`C.free` só existe quando o preâmbulo inclui o cabeçalho que o declara.**"
    },
    {
      "code": "import (\n\t\"bytes\"\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n\t\"unsafe\"\n)\n"
    },
    {
      "code": "func main() {\n\tfmt.Println(\"zlib\", C.GoString(C.zlibVersion()))\n\tfor _, name := range os.Args[1:] {\n\t\tn, err := count(name)\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"gzlines:\", err)\n\t\t\tos.Exit(1)\n\t\t}\n\t\tfmt.Println(n, name)\n\t}\n}\n",
      "note": "`zlibVersion` devolve um `const char *` que aponta para a memória da própria zlib. `C.GoString` copia os bytes até o zero que termina uma string C para uma string Go nova. O ponteiro em si nunca é liberado, porque é da zlib."
    },
    {
      "code": "// count opens name with zlib and counts the newlines in what it reads.\nfunc count(name string) (int, error) {\n\tcname := C.CString(name)\n\tdefer C.free(unsafe.Pointer(cname))\n\tmode := C.CString(\"rb\")\n\tdefer C.free(unsafe.Pointer(mode))\n",
      "note": "**`C.CString` copia uma string Go para memória vinda do `malloc` do C**, com o byte zero que o C espera no fim. O coletor de lixo não sabe que essa memória existe, então liberá-la é trabalho desta função, e o `defer` faz isso em todo retorno."
    },
    {
      "code": "\tf, err := C.gzopen(cname, mode)\n\tif f == nil {\n\t\treturn 0, fmt.Errorf(\"%s: %w\", name, err)\n\t}\n\tdefer C.gzclose(f)\n",
      "note": "Qualquer função C pode ser chamada pedindo dois resultados, e o segundo é o `errno` do C como erro Go. O `errno` pode ter sobrado de uma chamada anterior mesmo quando esta deu certo, então o código confere `f == nil`, o sinal de falha da própria zlib, antes de confiar em `err`."
    },
    {
      "code": "\tbuf := make([]byte, 64*1024)\n\tlines := 0\n\tfor {\n\t\tn := C.gzread(f, C.voidp(unsafe.Pointer(&buf[0])), C.uint(len(buf)))",
      "note": "**Memória Go emprestada ao C por uma chamada.** `&buf[0]` aponta para dentro de uma fatia Go, e as regras permitem passá-lo porque os bytes não guardam ponteiros Go. O C pode ler e escrever neles até o `gzread` retornar e não pode guardar o endereço depois. `unsafe.Pointer` é como qualquer ponteiro Go vira o `void *` do C, que a zlib chama de `voidp`."
    },
    {
      "code": "\t\tif n <= 0 {\n\t\t\tvar code C.int\n\t\t\tmsg := C.gzerror(f, &code)\n\t\t\tif code != C.Z_OK {\n\t\t\t\treturn lines, errors.New(C.GoString(msg))\n\t\t\t}\n\t\t\treturn lines, nil\n\t\t}",
      "note": "O `gzread` devolve 0 tanto no fim de um arquivo inteiro quanto no fim de um cortado; o cabeçalho da zlib diz que ele \"does not return -1 in the event of an incomplete gzip stream\". O `gzerror` distingue os dois. A mensagem dele também é da zlib, então é copiada e nunca liberada."
    },
    {
      "code": "\t\tlines += bytes.Count(buf[:n], []byte{'\\n'})\n\t}\n}"
    }
  ]
}
```

O log é o que o `genlog` da lição 1 escreve, e o código dele, `tools/genlog/main.go`, entra neste
módulo sem mudança. Saem três arquivos: o log, uma cópia comprimida e uma cópia dessa cortada depois
de 3.000 bytes, como fica um download que morreu no meio:

```
ana@vm:~/cgo$ go run ./tools/genlog -n 20000 > access.log && gzip -k access.log && head -c 3000 access.log.gz > cut.gz
ana@vm:~/cgo$ go build -o bin/ ./gzlines && bin/gzlines access.log.gz
zlib 1.3
20000 access.log.gz
ana@vm:~/cgo$ bin/gzlines cut.gz; echo $?
zlib 1.3
gzlines: cut.gz: unexpected end of file
1
ana@vm:~/cgo$ bin/gzlines nope.gz; echo $?
zlib 1.3
gzlines: nope.gz: no such file or directory
1
ana@vm:~/cgo$ bin/gzlines access.log
zlib 1.3
20000 access.log
```

As 20.000 linhas estão todas lá, e as duas falhas dizem o que falhou. `unexpected end of file` veio
do `gzerror`, e perguntar a ele é o único motivo de o arquivo cortado ser apontado. Uma versão de
`count` que retornava em `n == 0` sem perguntar imprimiu uma contagem e status 0 para um arquivo
sem a maior parte das linhas. `no such file or directory` é o `errno`, trazido pela chamada de dois
resultados. O último comando mostra um costume da zlib que vale conhecer: diante de um arquivo sem
cabeçalho gzip, o `gzopen` o lê como está, então o `gzlines` contou também o log puro. **Cada um
desses comportamentos é uma convenção de uma biblioteca C**, escrita no cabeçalho dela, e um
invólucro cgo herda todas. O `compress/gzip` do próprio Go tem outras, e a seção 05 as mostra.

## Quem libera o quê

Quatro tipos de memória cruzaram a linha no `gzlines`, e cada um tem um dono:

| valor | alocado por | liberado por | no `gzlines` |
|---|---|---|---|
| `C.CString(s)` | o `malloc` do C, como cópia | você, com `C.free` | `cname` e `mode`, liberados por `defer` |
| `C.GoString(p)` | o Go, como cópia | o coletor de lixo | a versão e a mensagem de erro |
| um ponteiro que uma biblioteca C devolve | a biblioteca | a biblioteca, ou a função que ela documenta | `zlibVersion()`, `gzerror(...)` e `f`, liberado pelo `gzclose` |
| `&buf[0]`, memória Go passada ao C | o Go | o coletor de lixo | emprestado ao `gzread` pelo tempo de uma chamada |

**Toda conversão entre uma string Go e uma string C é uma cópia**, nas duas direções, porque as
duas discordam sobre o que é uma string: a do Go carrega o comprimento e pode conter bytes zero, a
do C termina no primeiro zero. Copiar custa um `malloc` e um laço, e é o que deixa a posse simples:
depois que o `C.CString` retorna, a string Go e a string C não têm mais nada uma com a outra.

## A regra que o runtime confere

Emprestar `&buf[0]` funcionou porque os bytes de `buf` são só bytes. A regra da documentação é que
**o Go só pode passar ao C um ponteiro para memória Go se essa memória não guardar ponteiros para
outra memória Go não fixada**, e que o C não pode guardar uma cópia depois que a chamada retorna. O
motivo é o coletor de lixo: ele enxerga ponteiros Go em memória Go e mantém vivos os alvos deles, e
não enxerga dentro do C. Uma struct C que guarda um ponteiro para dentro de uma fatia Go é o formato
que quebra a regra sem parecer errado. `rules/main.go`:

```go
// Command rules hands C a struct that points into Go memory, which the
// pointer-passing rules forbid, and lets the runtime notice.
package main

/*
#include <stddef.h>

typedef struct {
	const char *data;
	size_t len;
} span;

static size_t span_len(span *s) { return s->len; }
*/
import "C"

import (
	"fmt"
	"unsafe"
)

func main() {
	line := []byte("GET /login")
	s := C.span{data: (*C.char)(unsafe.Pointer(&line[0])), len: C.size_t(len(line))}
	fmt.Println(C.span_len(&s))
}
```

```
ana@vm:~/cgo$ go vet ./rules && go build -o bin/ ./rules && bin/rules; echo $?
panic: runtime error: argument of cgo function has Go pointer to unpinned Go pointer

goroutine 1 [running]:
main.main.func1(...)
	/home/ana/cgo/rules/main.go:25
main.main()
	/home/ana/cgo/rules/main.go:25 +0xa5
2
```

`s` é uma variável Go, então `&s` é um ponteiro Go, e o campo `data` dela aponta para `line`, que
também é memória Go. **O `go vet` deixou passar e o compilador compilou; o runtime pegou na
chamada**, com uma checagem que a documentação descreve como "reasonably cheap", ligada por padrão
como `GODEBUG=cgocheck=1`. Desligar a checagem não torna o programa certo:

```
ana@vm:~/cgo$ GODEBUG=cgocheck=0 bin/rules; echo $?
10
0
```

Ele imprimiu a resposta certa, porque o `span_len` lê o comprimento e retorna antes que o coletor
tenha qualquer motivo para mexer em `line`. Esse é o perigo numa linha: **uma violação que a
checagem não barra funciona até o coletor rodar na hora errada.** A correção é dizer ao runtime que
`line` precisa ficar onde está enquanto o C puder vê-la. O `runtime.Pinner` faz isso, e o
`pinned/main.go` é o mesmo programa com três linhas a mais:

```go
// Command pinned hands C the same struct as rules, with the memory it
// points to pinned for as long as C can see it.
package main

/*
#include <stddef.h>

typedef struct {
	const char *data;
	size_t len;
} span;

static size_t span_len(span *s) { return s->len; }
*/
import "C"

import (
	"fmt"
	"runtime"
	"unsafe"
)

func main() {
	line := []byte("GET /login")
	var pin runtime.Pinner
	pin.Pin(&line[0])
	defer pin.Unpin()
	s := C.span{data: (*C.char)(unsafe.Pointer(&line[0])), len: C.size_t(len(line))}
	fmt.Println(C.span_len(&s))
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./pinned && bin/pinned
10
```

O `Pin` fixa o objeto no lugar até o `Unpin`, e a checagem fica satisfeita porque o ponteiro dentro
de `s` agora aponta para memória fixada. Há duas outras correções. O `C.CBytes` aloca os bytes do
lado C, copiando como o `C.CString`, e eles são liberados do mesmo jeito. Ou o ponteiro e o
comprimento vão ao C como dois argumentos, para que nenhuma memória Go que o C recebe contenha
ponteiro algum.

## Valores Go que o C precisa carregar: `cgo.Handle`

Uma biblioteca C que chama você de volta costuma receber um `void *` ou um inteiro de "dados do
usuário" e entregá-lo a cada callback. Você não pode passar a ela um mapa Go, um canal ou um
ponteiro para uma struct cheia de fatias: todos contêm ponteiros Go, e o C os estaria guardando.
**`runtime/cgo.Handle` transforma qualquer valor Go num inteiro** que não significa nada para o C e
que o Go consegue transformar de volta no valor. Uma função C que divide um log em linhas e chama o
Go uma vez por linha mostra isso. O C fica em dois arquivos ao lado do arquivo Go, que o comando go
compila porque o pacote importa `"C"`. `each/each.h`:

```
#include <stddef.h>
#include <stdint.h>

// each_line calls the Go function goLine once for every line in buf,
// passing h through untouched.
void each_line(const char *buf, size_t n, uintptr_t h);
```

`each/each.c`:

```
#include "each.h"
#include "_cgo_export.h"

void each_line(const char *buf, size_t n, uintptr_t h) {
	size_t start = 0;
	for (size_t i = 0; i < n; i++) {
		if (buf[i] == '\n') {
			goLine(h, (char *)buf + start, (int)(i - start));
			start = i + 1;
		}
	}
}
```

`each/main.go`:

```go
// Command each hands a log to a C function that splits it into lines, and
// counts the methods in the lines C hands back.
package main

/*
#include "each.h"
*/
import "C"

import (
	"fmt"
	"os"
	"runtime/cgo"
	"strings"
	"unsafe"
)

//export goLine
func goLine(h C.uintptr_t, line *C.char, n C.int) {
	counts := cgo.Handle(h).Value().(map[string]int)
	fields := strings.Fields(C.GoStringN(line, n))
	counts[fields[1]]++
}

func main() {
	data, err := os.ReadFile(os.Args[1])
	if err != nil || len(data) == 0 {
		fmt.Fprintln(os.Stderr, "each: need a log that is not empty:", err)
		os.Exit(1)
	}
	counts := map[string]int{}
	h := cgo.NewHandle(counts)
	defer h.Delete()
	C.each_line((*C.char)(unsafe.Pointer(&data[0])), C.size_t(len(data)), C.uintptr_t(h))
	fmt.Println(counts)
}
```

```
ana@vm:~/cgo$ ls each && go build -o bin/ ./each && bin/each access.log
each.c
each.h
main.go
map[GET:15065 POST:4935]
```

O `//export goLine` torna a função Go chamável do C, e o cgo a declara em `_cgo_export.h`, que é
por isso que o `each.c` inclui esse cabeçalho. O mapa nunca sai do Go: `cgo.NewHandle(counts)` o
guarda numa tabela e devolve o número dele, o C passa o número de volta 20.000 vezes, e
`cgo.Handle(h).Value()` encontra o mapa de novo. Cada linha chega como um ponteiro e um comprimento,
sem byte zero depois, então o `C.GoStringN` copia exatamente essa quantidade de bytes. `h.Delete()`
remove a entrada, e **um handle que
nunca é apagado mantém o valor vivo para sempre**, o mesmo vazamento de uma string C que ninguém
libera, visto do outro lado. A metade C mora em arquivos `.c` e `.h`, e não no preâmbulo, por um
motivo que a documentação dá. Um arquivo que usa `//export` só pode ter declarações no preâmbulo,
porque o preâmbulo é copiado para dois arquivos C gerados, e uma definição ali seria definida duas
vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Quatro coisas cruzam entre a memória do Go, liberada pelo coletor de lixo, e a memória do C, liberada por free. C.CString(name) copia uma string Go para a memória do C, que você precisa liberar com C.free. &amp;buf[0] empresta uma fatia Go ao gzread por uma chamada, e o C não pode guardá-la. C.GoString(p) copia a string que zlibVersion devolve para uma string Go nova, e a zlib fica com a dela. cgo.NewHandle(counts) deixa o mapa Go no Go e passa ao C só um inteiro.\"><defs><marker id=\"m3p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"m3a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"250\" height=\"345\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"20\" width=\"250\" height=\"345\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Memória do Go</text><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o coletor de lixo libera</text><text x=\"575\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Memória do C</text><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free() libera</text><rect x=\"38\" y=\"85\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><text x=\"145\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma string Go</text><rect x=\"468\" y=\"85\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cname</text><text x=\"575\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sua para liberar: C.free</text><path d=\"M256 111 L464 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C.CString(name)</text><text x=\"360\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copiada para a memória do C</text><rect x=\"38\" y=\"155\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">buf</text><text x=\"145\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma fatia Go de 64 KiB</text><rect x=\"468\" y=\"155\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">gzread(f, &amp;buf[0], n)</text><text x=\"575\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">usa até retornar</text><path d=\"M256 181 L464 181\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#m3a)\" marker-start=\"url(#m3a)\"></path><text x=\"360\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&amp;buf[0]</text><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">emprestada por uma chamada</text><rect x=\"38\" y=\"225\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;1.3&quot;</text><text x=\"145\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma string Go nova</text><rect x=\"468\" y=\"225\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">zlibVersion()</text><text x=\"575\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">da zlib, nunca liberada</text><path d=\"M464 251 L256 251\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C.GoString(p)</text><text x=\"360\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copiada para a memória do Go</text><rect x=\"38\" y=\"295\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counts</text><text x=\"145\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um mapa Go, que fica aqui</text><rect x=\"468\" y=\"295\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uintptr_t h</text><text x=\"575\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um número que o C devolve</text><path d=\"M256 321 L464 321\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"309\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cgo.NewHandle(counts)</text><text x=\"360\" y=\"335\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só um inteiro atravessa</text></svg>", "caption": "Toda travessia é uma cópia, um empréstimo pelo tempo de uma chamada, ou um número que representa um valor Go."}
```
