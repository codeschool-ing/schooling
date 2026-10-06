---
title: Um arquivo para copiar
version: 1
---

Para rodar um programa Python num servidor, você instala Python no servidor antes; um programa Java
precisa de um runtime Java, e um programa Node precisa de Node. É fácil supor que toda linguagem
funciona assim. Go não funciona. **O comando go compila um programa para código de máquina de um
sistema operacional e de um processador, e o resultado é um único arquivo que não precisa de mais
nada instalado.** Esta seção gera um, olha o que ele pede da máquina e o gera de novo para máquinas
que este laboratório não é.

O programa diz para qual sistema foi compilado:

```go
// Command why says which system it was compiled for.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled for", runtime.GOOS+"/"+runtime.GOARCH, "by", runtime.Version())
}
```

`runtime.GOOS` e `runtime.GOARCH` são fixados quando o programa é compilado, então informam o
sistema **para** o qual o binário foi gerado, seja qual for a máquina em que ele rode depois. Isso
facilita distinguir os builds cruzados do fim desta seção.

```
ana@vm:~/why$ go clean -cache
ana@vm:~/why$ time go build

real	0m4.738s
user	0m10.803s
sys	0m1.688s
ana@vm:~/why$ ./why
compiled for linux/amd64 by go1.27.1
ana@vm:~/why$ wc -c main.go why
    201 main.go
2342001 why
2342202 total
```

O cache foi esvaziado antes, então a maior parte dos 4,738 segundos foi gasta compilando as partes
da biblioteca padrão que o programa usa, exatamente como na lição 4. Os 201 bytes de código-fonte
viraram 2.342.001 bytes de programa, e a diferença é o runtime de Go, que todo programa Go carrega:
o gerenciador de memória, o escalonador, o código que imprime um stack trace.

## O que o arquivo pede da máquina

Três comandos respondem à pergunta por três lados:

```
ana@vm:~/why$ file why
why: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=WwBw_hKHsHbVuataMSov/IzDaYBoww3uTpwLKqiZV/2TCEAa5I9bA-iMoBjqc5/jV7AQI73pmBUDpWB8c01, BuildID[sha1]=68ce336aee68663de8c691b0449381323b0488e6, with debug_info, not stripped
ana@vm:~/why$ ldd why
	not a dynamic executable
ana@vm:~/why$ readelf -d why

There is no dynamic section in this file.
ana@vm:~/why$ readelf -d /bin/ls | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libselinux.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
```

O `file` diz `statically linked`. O `ldd`, que lista as bibliotecas compartilhadas que um programa
carrega, não tem nenhuma para listar. O `readelf -d` imprime a seção dinâmica de um binário, a parte
onde essas bibliotecas seriam nomeadas, e `why` não tem essa seção. O `/bin/ls`, um programa em C,
nomeia duas: `libselinux.so.1` e `libc.so.6` precisam já estar na máquina, numa versão que sirva,
ou o `ls` não inicia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois programas e o que cada um precisa da máquina. À esquerda, /bin/ls, um programa em C: o arquivo tem o código dele e aponta para duas bibliotecas compartilhadas, libselinux.so.1 e libc.so.6, que precisam já estar na máquina e são carregadas quando ele inicia, antes de chegar ao kernel Linux. À direita, why, um programa Go: um arquivo de 2.342.001 bytes que contém o seu código, os pacotes que ele importa e o runtime de Go, e fala direto com o kernel.\"><defs><marker id=\"l1bin-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l1bin-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"160\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um programa em C</text><rect x=\"40\" y=\"48\" width=\"140\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/bin/ls</text><text x=\"110\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o código dele</text><rect x=\"222\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"292\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libselinux.so.1</text><rect x=\"222\" y=\"92\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"292\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libc.so.6</text><path d=\"M180 66 L220 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-phosphor)\"></path><path d=\"M180 102 L220 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-phosphor)\"></path><text x=\"300\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">achadas na máquina</text><text x=\"300\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quando ele inicia</text><path d=\"M110 120 L110 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><path d=\"M292 124 L292 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><text x=\"550\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um programa Go</text><rect x=\"420\" y=\"40\" width=\"260\" height=\"156\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"550\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">why</text><rect x=\"440\" y=\"74\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o seu código</text><rect x=\"440\" y=\"112\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os pacotes que ele importa</text><rect x=\"440\" y=\"150\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o runtime de Go</text><text x=\"500\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.342.001 bytes, um arquivo</text><path d=\"M640 196 L640 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><rect x=\"40\" y=\"228\" width=\"640\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o kernel Linux</text></svg>", "caption": "O que cada programa precisa quando inicia. /bin/ls cita duas bibliotecas compartilhadas que já precisam estar na máquina; why leva os pacotes e o runtime de Go dentro do arquivo e só pede o kernel."}
```

**Copie `why` para qualquer máquina Linux com processador x86-64 e ele roda**, sem Go instalado e
sem biblioteca para casar. É essa a troca que Go faz: um arquivo maior, em troca de nada para
instalar ao lado dele. A lição 4 volta a ela quando gera seu primeiro programa.

## A exceção: um compilador C na máquina

Um arquivo só é o padrão, não uma lei. Este programa pede ao sistema operacional o endereço de
`localhost`:

```go
// Command lookup resolves a host name.
package main

import (
	"fmt"
	"net"
)

func main() {
	addrs, err := net.LookupHost("localhost")
	fmt.Println(addrs, err)
}
```

```
ana@vm:~/why-net$ go env CGO_ENABLED
1
ana@vm:~/why-net$ go build && ./lookup
[127.0.0.1] <nil>
ana@vm:~/why-net$ file lookup
lookup: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=Xxy7vpsJBpPu2GZgP08g/vrk3hxOuiD6NpMAG-oXk/Z7wh7g3Am7uWtKGyjlO5/KUIGafK3cqceQw2ti98l, BuildID[sha1]=7efe1b9bfe64020edae1653574ab38d94bb4a972, with debug_info, not stripped
ana@vm:~/why-net$ readelf -d lookup | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
ana@vm:~/why-net$ CGO_ENABLED=0 go build && file lookup
lookup: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=OteiPLfIk6JdDu5DYCYC/e8Xk6ckEUUe3G3QF1_Y2/_dx7mW5qgQVmWz9Em7A9/jNDDMJFqKt1CTNcrcMW8, BuildID[sha1]=110866a3acf76909aee5b8259ee664d3c8274124, with debug_info, not stripped
```

Desta vez o binário é `dynamically linked` e precisa de `libc.so.6`. O `go doc net` explica o porquê
em *Name Resolution*: o pacote `net` pode resolver nomes sozinho ou por rotinas da biblioteca C,
como `getaddrinfo`, e mantém o caminho do C disponível quando pode. **Esse caminho é o cgo, a parte
do comando go que deixa Go chamar C**, e o `go env` mostra que ele está ligado. O `go doc cmd/cgo`
diz quando: ele fica ligado em builds nativos numa máquina onde um compilador C é encontrado no
`PATH`, e este laboratório tem um, porque o `gcc` está instalado. Com `CGO_ENABLED=0` o mesmo
código-fonte volta a gerar um binário estático.

Então um programa Go é um arquivo autossuficiente a menos que algo nele use C, e você vê em qual
caso está com o `file` antes de entregá-lo.

## Gerando para outra máquina

`GOOS` e `GOARCH` escolhem o sistema para o qual um build é feito. Defina-os na linha de comando e o
comando go compila para aquele sistema em vez deste:

```
ana@vm:~/why$ time GOOS=windows GOARCH=amd64 go build -o why.exe

real	0m4.752s
user	0m10.981s
sys	0m1.885s
ana@vm:~/why$ GOOS=darwin GOARCH=arm64 go build -o why-mac
ana@vm:~/why$ GOOS=linux GOARCH=arm64 go build -o why-arm64
ana@vm:~/why$ file why.exe why-mac why-arm64
why.exe:   PE32+ executable (console) x86-64, for MS Windows, 16 sections
why-mac:   Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
why-arm64: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, Go BuildID=1fHCSRqENJHPXzkxYIb4/t2KOm_kz4tkhJ0DbG5_X/u2ch0QQcx8ZxIhccHute/GZbPcB6-dbDgaKdq3Xz2, BuildID[sha1]=b89614b04ff4a62c60f300afc43fbf27518891c1, with debug_info, not stripped
ana@vm:~/why$ ./why-arm64
bash: line 1: ./why-arm64: cannot execute binary file: Exec format error
```

Três binários para três sistemas, a partir de uma máquina Linux, e **nada foi instalado para
gerá-los**: o toolchain de Go traz o compilador de cada alvo que suporta. O build para Windows levou
4,752 segundos porque o cache tinha a biblioteca padrão compilada para Linux e não para Windows; os
builds para Mac e para ARM vieram depois e não foram cronometrados.

A última linha é a prova de que o binário ARM é mesmo para outro processador. Esta máquina é
x86-64, então o kernel se recusa a executar código para ARM. Copiado para um servidor ARM com Linux
de 64 bits, ele imprimiria `compiled for linux/arm64`.

O binário de Mac traz `DYLDLINK` porque no macOS o runtime de Go fala com o sistema pela biblioteca
da própria Apple, `/usr/lib/libSystem.B.dylib`, e não direto com o kernel; o
`src/runtime/sys_darwin.go` do código-fonte de Go a nomeia em cada importação. Todo Mac tem essa
biblioteca, então continua sendo um arquivo para copiar. Nenhum desses três binários foi executado
no laboratório, porque não há nele máquina Windows, Mac ou ARM.

Para quantos sistemas um Go consegue gerar? O comando go lista:

```
ana@vm:~/why$ go tool dist list | wc -l
47
ana@vm:~/why$ go tool dist list | grep linux
linux/386
linux/amd64
linux/arm
linux/arm64
linux/loong64
linux/mips
linux/mips64
linux/mips64le
linux/mipsle
linux/ppc64
linux/ppc64le
linux/riscv64
linux/s390x
```

Quarenta e sete pares de sistema operacional e processador, treze deles Linux. Cada um é um valor
que você pode pôr em `GOOS` e `GOARCH`.
