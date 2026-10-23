---
title: Duas variáveis escolhem a máquina
version: 1
---

Um programador C que quer um binário para um Raspberry Pi num notebook Intel precisa de um segundo
compilador: um GCC feito para gerar código ARM, com uma cópia da biblioteca C e dos cabeçalhos do
alvo ao lado. **O Go precisa de duas variáveis de ambiente.** `GOOS` diz o sistema operacional em
que o binário vai rodar e `GOARCH` diz o processador, e o mesmo `go build` que gera um binário para
esta máquina gera um para qualquer par que o conjunto de ferramentas conheça. Nada mais é instalado.

Esta lição trabalha com o `hits` exatamente como a lição 1 o deixou: o pacote `tally`, o `main.go`,
o `main_test.go` e o `genlog`, num diretório novo, `~/cross`, com o `access.log` de 20.000 linhas
que `go run ./tools/genlog -n 20000` escreve. Nada no programa muda nesta lição; só muda a máquina
para a qual ele é compilado.

## O que o conjunto de ferramentas conhece

Sem valor definido, as duas variáveis assumem os valores da máquina em que o comando go está
rodando, e o `go env` os imprime. `go tool dist list` imprime cada par para o qual o Go instalado
sabe compilar:

```
ana@vm:~/cross$ go env GOOS GOARCH
linux
amd64
ana@vm:~/cross$ go tool dist list | wc -l
47
ana@vm:~/cross$ go tool dist list | grep -E "^(linux|darwin|windows)/"
darwin/amd64
darwin/arm64
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
windows/386
windows/amd64
windows/arm64
ana@vm:~/cross$ go tool dist list -json | grep -c '"FirstClass": true'
8
```

**O Go 1.27.1 compila para 47 pares**, dezoito deles nos três sistemas para os quais a maioria das
pessoas distribui. `darwin` é o macOS, e `amd64` é o conjunto de instruções de 64 bits da Intel e da
AMD, seja qual for o nome que o fabricante usa. A forma `-json` acrescenta dois campos por par; oito
têm `"FirstClass": true`, os ports que a equipe do Go trata como principais, e os outros 39 são
mantidos por quem cuida deles. Todo par para o qual você provavelmente vai distribuir o `hits` está
entre os oito, e o Linux ARM de 64 bits de um Raspberry Pi 4 ou de um servidor ARM na nuvem também.

## Quatro builds no mesmo diretório

Defina as duas variáveis para um comando só, do jeito que o shell define qualquer variável para um
comando, e compile. A primeira linha é o build nativo comum, para comparar:

```
ana@vm:~/cross$ go build -o hits .
ana@vm:~/cross$ GOOS=linux GOARCH=arm64 go build -o hits-arm64 .
ana@vm:~/cross$ GOOS=darwin GOARCH=arm64 go build -o hits-mac .
ana@vm:~/cross$ GOOS=windows GOARCH=amd64 go build .
ana@vm:~/cross$ ls
access.log
go.mod
hits
hits-arm64
hits-mac
hits.exe
internal
main.go
main_test.go
tools
```

O último build não teve `-o`, e **o comando go chamou a saída de `hits.exe` por conta própria**,
porque um programa de Windows precisa da extensão para ser executado pelo nome. Nenhum dos quatro
imprimiu nada, que é a cara do sucesso no `go build`. O comando `file` lê os primeiros bytes de cada
um e diz que tipo de executável é. O `cut` guarda os campos que importam aqui e descarta os
identificadores de build:

```
ana@vm:~/cross$ file hits hits-arm64 hits-mac hits.exe | cut -d, -f1,2,4
hits:       ELF 64-bit LSB executable, x86-64, statically linked
hits-arm64: ELF 64-bit LSB executable, ARM aarch64, statically linked
hits-mac:   Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
hits.exe:   PE32+ executable (console) x86-64, for MS Windows
ana@vm:~/cross$ stat -c "%s bytes  %n" hits hits-arm64 hits-mac hits.exe
4031935 bytes  hits
3831466 bytes  hits-arm64
3909762 bytes  hits-mac
4217344 bytes  hits.exe
ana@vm:~/cross$ strings hits-mac | grep libSystem
/usr/lib/libSystem.B.dylib
```

**Três formatos de executável saíram de um compilador só**: ELF para Linux, Mach-O para macOS e
PE32+ para Windows. `aarch64` é o nome que o `file` dá ao processador que o Go chama de `arm64`. Os
tamanhos variam alguns por cento porque as instruções mudam e a contabilidade de cada formato
também, e os quatro ficam perto dos **4.031.935 bytes** do build nativo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Um módulo, main.go e internal/tally, passa por um único go build, guiado por GOOS e GOARCH, e sai como quatro binários: linux/amd64, um ELF de 4.031.935 bytes, feito para a máquina onde o build rodou; e, abaixo de uma linha em que CGO_ENABLED cai de 1 para 0, linux/arm64 como ELF de 3.831.466 bytes, darwin/arm64 como Mach-O de 3.909.762 bytes que cita a libSystem, e windows/amd64 como PE32+ chamado hits.exe, de 4.217.344 bytes.\"><defs><marker id=\"cx-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um módulo</text><rect x=\"36\" y=\"104\" width=\"138\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.go</text><text x=\"105\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">internal/tally/</text><text x=\"105\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mais a biblioteca padrão,</text><text x=\"105\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">compilada do código-fonte</text><text x=\"105\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para cada alvo</text><rect x=\"225\" y=\"115\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">go build</text><text x=\"290\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GOOS  GOARCH</text><path d=\"M190 145 H221\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"20\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linux/amd64</text><text x=\"412\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ELF, ligado estaticamente, 4.031.935 bytes</text><path d=\"M355 145 C378 145 374 40 396 40\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"100\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linux/arm64</text><text x=\"412\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ELF, ligado estaticamente, 3.831.466 bytes</text><path d=\"M355 145 C378 145 374 120 396 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"152\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">darwin/arm64</text><text x=\"412\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Mach-O, cita a libSystem, 3.909.762 bytes</text><path d=\"M355 145 C378 145 374 172 396 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"204\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">windows/amd64</text><text x=\"412\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PE32+, chamado hits.exe, 4.217.344 bytes</text><path d=\"M355 145 C378 145 374 224 396 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><text x=\"668\" y=\"33\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a própria máquina do build</text><path d=\"M370 86 H690\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"690\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">CGO_ENABLED vale 1 acima da linha e 0 abaixo</text></svg>", "caption": "Uma árvore de código e um compilador, quatro binários. Tudo abaixo da linha tracejada é build cruzado, e o comando go desliga o cgo nele.", "same": []}
```

## Por que não há conjunto de ferramentas cruzado para instalar

**O compilador, o assembler e o linker do Go são programas em Go, e a biblioteca padrão também**,
exceto por pequenos arquivos de assembly escritos para cada processador, que vêm em
`/usr/local/go/src` para todas as arquiteturas de uma vez. Nada em `/usr/local/go/pkg` é uma
biblioteca padrão pré-compilada: o comando go compila do código-fonte os pacotes de que um build
precisa, para o alvo pedido, e guarda o resultado no cache de build. Um build para `arm64` não
precisa, portanto, de nada que um build para `amd64` não precise, e o segundo build para o mesmo
alvo reaproveita o cache.

A outra metade é aquilo de que o binário depende quando roda. **No Linux, um programa Go faz as
próprias chamadas de sistema**, sem a biblioteca C, e é por isso que os dois ELF dizem `statically
linked`: podem ser copiados para qualquer Linux naquele processador e iniciados. O macOS é
diferente: a Apple não mantém estáveis as suas chamadas de sistema e só dá suporte a programas que
passam pela biblioteca do sistema, então o Mach-O é `DYLDLINK` e cita `/usr/lib/libSystem.B.dylib`.
Essa referência foi escrita pelo próprio linker do Go. Não há ferramenta da Apple nem cabeçalho de
macOS nesta máquina, e nada disso fez falta, porque a biblioteca só é procurada quando o programa
inicia num Mac.

A única parte de um build que não é Go é o cgo, a ponte para C, e a seção 04 trata do que acontece
com ele quando o alvo muda.
