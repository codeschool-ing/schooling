---
title: Do que o binário abre mão
version: 1
---

A imagem comum do cgo é a de que ele muda como uma chamada é feita e deixa o resto do programa em
paz. **Ele muda o binário, o build e o que toda máquina que compila ou roda o programa precisa
ter.** As lições 16 e 18 mostraram esses efeitos num pacote padrão que por acaso usa C. Esta seção
os mede em programas que chamam C de propósito, cada um com um gêmeo que faz o mesmo trabalho em Go
puro.

## O gêmeo em Go puro

O `gzgo` conta as linhas de um arquivo gzip como o `gzlines` da seção 03, com o `compress/gzip` da
biblioteca padrão no lugar da zlib. `gzgo/main.go`:

```go
// Command gzgo counts the lines of a gzip-compressed file, like gzlines,
// with the standard library's compress/gzip and no C at all.
package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"os"
)

func main() {
	for _, name := range os.Args[1:] {
		n, err := count(name)
		if err != nil {
			fmt.Fprintln(os.Stderr, "gzgo:", err)
			os.Exit(1)
		}
		fmt.Println(n, name)
	}
}

// count reads name through a gzip reader and counts the newlines.
func count(name string) (int, error) {
	f, err := os.Open(name)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	zr, err := gzip.NewReader(f)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", name, err)
	}
	buf := make([]byte, 64*1024)
	lines := 0
	for {
		n, err := zr.Read(buf)
		lines += bytes.Count(buf[:n], []byte{'\n'})
		if err == io.EOF {
			return lines, nil
		}
		if err != nil {
			return lines, fmt.Errorf("%s: %w", name, err)
		}
	}
}
```

## Ligação dinâmica

```
ana@vm:~/cgo$ go build -o bin/ ./gzgo && file bin/gzlines bin/gzgo | cut -d, -f1,4
bin/gzlines: ELF 64-bit LSB executable, dynamically linked
bin/gzgo:    ELF 64-bit LSB executable, statically linked
ana@vm:~/cgo$ ldd bin/gzlines | awk '{print $1}'
linux-vdso.so.1
libz.so.1
libc.so.6
/lib64/ld-linux-x86-64.so.2
ana@vm:~/cgo$ bin/gzgo access.log.gz cut.gz; echo $?
20000 access.log.gz
gzgo: cut.gz: unexpected EOF
1
```

**O `gzlines` tem ligação dinâmica e o `gzgo` é estático.** O `ldd` lista o que o carregador
precisa achar antes que o `gzlines` possa começar: `libz.so.1`, a biblioteca C `libc.so.6` e o
próprio carregador; `linux-vdso.so.1` é fornecido pelo kernel e nunca é um arquivo. Toda máquina
que roda o `gzlines` precisa de uma zlib compatível instalada, e a lição 18 mostrou o que um binário
dinâmico faz numa imagem que nem tem carregador. O `gzgo` carrega tudo o que executa, e aponta o
arquivo cortado nos termos do próprio Go, como `unexpected EOF` vindo do leitor, sem uma segunda
chamada para perguntar se o fim era mesmo o fim dos dados.

Um binário estático com C dentro é possível quando cada biblioteca tem um arquivo estático. O
`zlib1g-dev` do Ubuntu traz `libz.a` ao lado de `libz.so`, e `-extldflags=-static` pede ao `gcc`,
o ligador externo, que use só arquivos estáticos:

```
ana@vm:~/cgo$ go build -ldflags=-extldflags=-static -o bin/gzlines-static ./gzlines && file bin/gzlines-static | cut -d, -f1,4 && bin/gzlines-static access.log.gz
bin/gzlines-static: ELF 64-bit LSB executable, statically linked
zlib 1.3
20000 access.log.gz
ana@vm:~/cgo$ stat -c "%s bytes  %n" bin/gzlines bin/gzlines-static bin/gzgo
2374888 bytes  bin/gzlines
3491192 bytes  bin/gzlines-static
2521628 bytes  bin/gzgo
```

**Estático, e 1,1 MB maior**, porque a zlib e as partes da biblioteca C que ela usa agora são
copiadas para dentro do arquivo. Também foi preciso uma flag que quem lê o build tem de entender, e
ela depende de um arquivo estático que nem toda biblioteca C traz; o gêmeo em Go puro ficou estático
sem fazer nada.

## A compilação cruzada para de funcionar

A lição 16 mostrou o que um build cruzado faz com um arquivo que importa `"C"`. Aqui está no
`gzlines`. O segundo comando liga o cgo e indica em `CC` um compilador C para ARM, que é como a
documentação do cgo diz que um build cruzado precisa ser feito:

```
ana@vm:~/cgo$ GOARCH=arm64 go build -o bin/gzlines-arm64 ./gzlines; echo $?
package example.com/cgo/gzlines: build constraints exclude all Go files in /home/ana/cgo/gzlines
1
ana@vm:~/cgo$ CGO_ENABLED=1 GOARCH=arm64 CC=aarch64-linux-gnu-gcc go build -o bin/gzlines-arm64 ./gzlines; echo $?
# runtime/cgo
cgo: C compiler "aarch64-linux-gnu-gcc" not found: exec: "aarch64-linux-gnu-gcc": executable file not found in $PATH
1
ana@vm:~/cgo$ GOARCH=arm64 go build -o bin/gzgo-arm64 ./gzgo && qemu-aarch64-static bin/gzgo-arm64 access.log.gz
20000 access.log.gz
```

**Com o cgo desligado, o `gzlines` fica sem arquivos para compilar; com ele ligado, não há
compilador para compilá-los.** `aarch64-linux-gnu-gcc` é o compilador cruzado do Ubuntu para ARM de
64 bits, e esta lição não o instala. Instalá-lo também não encerraria o assunto. O build cruzado
precisa ainda dos cabeçalhos e das bibliotecas C para ARM, e de uma zlib compilada para ARM para
ligar, e cada biblioteca C que o programa usa multiplica isso. O `clang`, que gera código ARM com
`--target`, foi tentado no laboratório e parou no primeiro cabeçalho da biblioteca C, pelo mesmo
motivo. O `gzgo` atravessou num comando só, e o `qemu-aarch64-static`, o emulador que a lição 16
usou, o rodou.

## O build fica mais lento, às vezes muito mais

O `gzlines` pede ao `gcc` que compile só as poucas linhas que o cgo gera em volta das chamadas,
porque a zlib chegou à máquina já compilada. Um pacote cgo que traz o C como código-fonte é outra
história. O mais conhecido é o `github.com/mattn/go-sqlite3`, um driver para o pacote
`database/sql` que compila o próprio SQLite. Um programa que só pergunta a versão dele,
`sq/main.go`:

```go
// Command sq asks SQLite, through the cgo driver go-sqlite3, which version
// of SQLite it is.
package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	log.SetFlags(0)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	var v string
	if err := db.QueryRow("select sqlite_version()").Scan(&v); err != nil {
		log.Fatal(err)
	}
	fmt.Println("sqlite", v)
}
```

```
ana@vm:~/cgo$ go get github.com/mattn/go-sqlite3@v1.14.52
go: added github.com/mattn/go-sqlite3 v1.14.52
ana@vm:~/cgo$ cd $(go env GOMODCACHE)/github.com/mattn/go-sqlite3@v1.14.52 && wc -l sqlite3-binding.c && head -4 sqlite3-binding.c | tail -2
269653 sqlite3-binding.c
** This file is an amalgamation of many separate C source files from SQLite
** version 3.53.4.  By combining all the individual C code files into this
```

A Ana já tinha baixado o módulo antes, então o comando go não imprimiu a linha `go: downloading`.
**O módulo carrega o SQLite como um único arquivo C de 269.653 linhas**, a amalgamação que o
próprio cabeçalho dele descreve, e o `gcc` compila tudo. O comando abaixo mede três builds com um
cache vazio em `/tmp/cgo-cold`: primeiro o `gzgo`, que enche esse cache com a biblioteca padrão,
depois o `sq`, depois o `sq` de novo:

```
ana@vm:~/cgo$ TIMEFORMAT="%R s"; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./gzgo; time GOCACHE=/tmp/cgo-cold go build -o bin/ ./sq; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./sq
4.623 s
32.722 s
0.634 s
```

**4,623 s para todo o `gzgo` e a biblioteca padrão por baixo dele; 32,722 s a mais para o `sq`**,
quase tudo o `gcc` compilando o SQLite; 0,634 s depois que o resultado está no cache. O cache
esconde isso num notebook que compila todo dia. Não esconde de um runner de CI que começa vazio, do
primeiro build depois de atualizar o Go, nem do `go test -race`, que compila um conjunto separado de
pacotes.

A outra coisa que o `sq` mostra é o que acontece sem cgo. O binário traz o SQLite dentro, então o
`ldd` lista só a biblioteca C e o carregador. Compilado com `CGO_ENABLED=0`, ele ainda compila:

```
ana@vm:~/cgo$ bin/sq; ldd bin/sq | awk "{print \$1}"
sqlite 3.53.4
linux-vdso.so.1
libc.so.6
/lib64/ld-linux-x86-64.so.2
ana@vm:~/cgo$ CGO_ENABLED=0 go build -o bin/sq-nocgo ./sq && bin/sq-nocgo; echo $?
Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work. This is a stub
1
```

**O build deu certo e o programa falhou quando rodou.** O go-sqlite3 traz um stub para builds sem
cgo, para que um pacote que depende dele continue compilando, e o primeiro ato do stub é recusar.
Um script de release que define `CGO_ENABLED=0`, como o da lição 16, produz um binário que passa em
todas as etapas do pipeline que não abrem um banco de dados.
