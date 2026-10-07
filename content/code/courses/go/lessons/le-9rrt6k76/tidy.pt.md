---
title: Uma dependência, go mod tidy e go.sum
version: 1
---

A lição 8 deixou um problema em aberto: `café` pode ser digitado com um `é` pré-composto, ou como
`cafe` seguido de um acento combinante, e as duas strings não são iguais. A biblioteca padrão não
tem função que resolva isso. O pacote que resolve, `golang.org/x/text/unicode/norm`, é mantido pelo
projeto Go num módulo próprio, fora da biblioteca padrão. Aqui está o programa que o usa, em
`~/mods-accents`:

```go
// Command accents compares two spellings of one word.
package main

import (
	"fmt"

	"golang.org/x/text/unicode/norm"
)

func main() {
	typed := "cafe\u0301" // e, then a combining accent
	stored := "caf\u00e9" // one precomposed letter
	fmt.Printf("%+q is %d bytes\n", typed, len(typed))
	fmt.Printf("%+q is %d bytes\n", stored, len(stored))
	fmt.Println("equal as typed:  ", typed == stored)
	fmt.Println("equal after NFC: ", norm.NFC.String(typed) == stored)
}
```

O import se escreve exatamente como `"fmt"`, só que mais comprido. A linha em branco entre os dois é
uma convenção: a biblioteca padrão primeiro e todo o resto depois. Uma linguagem com gerenciador de
pacotes costuma pedir que você declare a dependência num manifesto primeiro e a importe depois.
**Em Go, a linha de import é a declaração.** Nada mais no módulo menciona a dependência ainda, e o
comando go avisa:

```
ana@vm:~/mods-accents$ go run .; echo $?
main.go:7:2: no required module provides package golang.org/x/text/unicode/norm; to add it:
	go get golang.org/x/text/unicode/norm
1
```

O `go get` sugerido funciona, e a lição 40 o usa para escolher versões. O comando que lê todos os
imports do módulo de uma vez e ajusta o `go.mod` para combinar com eles é o `go mod tidy`.

## O tidy, numa máquina que nunca viu o módulo

O cache de módulos do laboratório já tinha `golang.org/x/text`, porque outras lições o usaram. Para
ver o que um primeiro download imprime, o comando abaixo aponta `GOMODCACHE`, a variável que a lição
3 listou, para um diretório vazio só nesta execução:

```
ana@vm:~/mods-accents$ GOMODCACHE=~/mods-cache go mod tidy
go: finding module for package golang.org/x/text/unicode/norm
go: downloading golang.org/x/text v0.42.0
go: found golang.org/x/text/unicode/norm in golang.org/x/text v0.42.0
ana@vm:~/mods-accents$ cat go.mod
module example.com/accents

go 1.27.1

require golang.org/x/text v0.42.0
ana@vm:~/mods-accents$ cat go.sum
golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=
ana@vm:~/mods-accents$ go run .
"cafe\u0301" is 6 bytes
"caf\u00e9" is 5 bytes
equal as typed:   false
equal after NFC:  true
```

As três linhas `go:` são o trabalho, em ordem. O caminho de importação nomeava um pacote, não um
módulo, então o comando go perguntou ao proxy que módulo o fornece, pegou a versão mais nova, baixou
e escreveu a resposta no `go.mod` como uma linha `require`. NFC é a forma do Unicode que junta um
`e` e o seu acento numa letra só, então depois de `norm.NFC.String` os seis bytes viraram os cinco
guardados e a comparação deu verdadeiro. O `%+q` imprimiu as duas strings com todo caractere não
ASCII escapado, que é o único jeito de distingui-las na tela.

O download foi para onde o cache sempre guarda um, descompactado num diretório com a versão no nome,
e **deixado só para leitura**, como a lição 3 disse que seria:

```
ana@vm:~/mods-accents$ ls ~/mods-cache/golang.org/x
text@v0.42.0
ana@vm:~/mods-accents$ ls ~/mods-cache/golang.org/x/text@v0.42.0 | head -5
CONTRIBUTING.md
LICENSE
PATENTS
README.md
cases
ana@vm:~/mods-accents$ stat -c "%A %n" ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
-r--r--r-- /home/ana/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
ana@vm:~/mods-accents$ echo "// mine" >> ~/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go
bash: line 1: /home/ana/mods-cache/golang.org/x/text@v0.42.0/unicode/norm/normalize.go: Permission denied
```

Todo módulo da Ana que pede `golang.org/x/text v0.42.0` lê este mesmo diretório, então uma edição
ali mudaria programas que você nem está olhando. O comando go dificulta fazer isso sem querer.

## O go.sum, e quem confere

O `go.sum` guarda duas linhas por versão de módulo. A primeira é um hash dos arquivos do módulo; a
segunda, um hash só do `go.mod` dele. `h1:` dá nome ao método: o código-fonte do comando go, no
pacote `dirhash`, o descreve como o SHA-256 em base64 de uma lista com o SHA-256 e o nome de cada
arquivo. **Um hash no `go.sum` é uma promessa sobre bytes**: quem compilar este módulo depois, em
qualquer máquina, tem de receber exatamente estes arquivos ou nada.

Isso ainda deixa o primeiro download de fora. Se o proxy tivesse servido arquivos alterados no dia
em que o `tidy` rodou, o `go.sum` teria registrado o hash alterado. Por isso, antes de escrever um
hash que nunca viu, o comando go pergunta a um segundo serviço, independente, o **banco de
checksums**: um log público dos hashes de versões de módulos, que o pacote que o implementa,
`sumdb/tlog`, chama de "tamper-evident", à prova de adulteração silenciosa. O `go env` diz qual é,
e você mesmo pode perguntar a ele:

```
ana@vm:~/mods-accents$ go env GOSUMDB
sum.golang.org
ana@vm:~/mods-accents$ curl -s https://sum.golang.org/lookup/golang.org/x/text@v0.42.0 | head -3
62562259
golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=
```

A primeira linha é o número do registro no log; as duas seguintes são as linhas do `go.sum`,
caractere por caractere. O comando go de todo mundo confere no mesmo log, então um proxy que
servisse a uma pessoa bytes diferentes dos de todo mundo seria pego pelo hash. No código-fonte,
`modfetch/fetch.go` só consulta o banco quando o hash ainda não está no `go.sum`: dali em diante, a
referência é o `go.sum`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O que o go mod tidy fez da primeira vez. Um: leu main.go e achou um import que nenhum módulo fornece. Dois: perguntou ao proxy.golang.org que módulo fornece o pacote e pegou a versão mais nova, v0.42.0, com o .mod e o .zip. Três: calculou o hash dos arquivos, h1:JbOZ. Quatro: perguntou ao sum.golang.org se o log público tem o mesmo hash, o que só acontece com um hash que o go.sum ainda não tem. Cinco: escreveu a linha require e o go.sum, e deixou os arquivos no cache de módulos, só leitura. Todo build seguinte compara o cache com o go.sum e não pergunta a ninguém.\"><defs><marker id=\"tdy-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"tdy-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o primeiro go mod tidy</text><rect x=\"10\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"72.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 lê os imports</text><text x=\"72.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">main.go</text><text x=\"72.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um import que nenhum</text><text x=\"72.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">módulo fornece</text><path d=\"M134 92 L150 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"152\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"214.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 pergunta ao proxy</text><text x=\"214.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">proxy.golang.org</text><text x=\"214.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a versão mais nova,</text><text x=\"214.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">v0.42.0 .mod .zip</text><path d=\"M276 92 L292 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"294\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 calcula o hash</text><text x=\"356.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">h1:JbOZ...</text><text x=\"356.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SHA-256 sobre</text><text x=\"356.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada arquivo</text><path d=\"M418 92 L434 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"436\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 pergunta ao log</text><text x=\"498.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sum.golang.org</text><text x=\"498.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mesmo hash?</text><text x=\"498.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só da primeira vez</text><path d=\"M560 92 L576 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tdy-phosphor)\"></path><rect x=\"578\" y=\"40\" width=\"124\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5 anota</text><text x=\"640.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">go.mod  go.sum</text><text x=\"640.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arquivos guardados no</text><text x=\"640.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cache, só leitura</text><rect x=\"156\" y=\"180\" width=\"554\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"433\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">todo build seguinte</text><text x=\"433\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compara os arquivos do cache com o go.sum, e não pergunta a ninguém</text><path d=\"M640.0 144 L640.0 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#tdy-wire)\"></path></svg>", "caption": "Na primeira vez que uma versão de módulo é baixada, dois serviços são consultados. Depois disso, a referência é o go.sum."}
```

O jeito de ver o `go.sum` trabalhando é fazê-lo discordar do cache. Troque um caractere do primeiro
hash, `Z` por `Y`, e compile:

```
ana@vm:~/mods-accents$ sed -i "s/h1:JbOZ/h1:JbOY/" go.sum
ana@vm:~/mods-accents$ go build; echo $?
verifying golang.org/x/text@v0.42.0: checksum mismatch
	downloaded: h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
	go.sum:     h1:JbOYXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=

SECURITY ERROR
This download does NOT match an earlier download recorded in go.sum.
The bits may have been replaced on the origin server, or an attacker may
have intercepted the download attempt.

For more information, see 'go help module-auth'.
1
ana@vm:~/mods-accents$ sed -i "s/h1:JbOY/h1:JbOZ/" go.sum && go build && echo built
built
ana@vm:~/mods-accents$ go mod verify
all modules verified
```

O comando go não sabe distinguir um `go.sum` errado de um download errado, então recusa os dois, e
nada é compilado. É por isso que **o `go.sum` vai para o repositório junto com o `go.mod`**: sem ele,
o primeiro build da próxima pessoa é um primeiro download, confiando no que a rede servir naquele
dia. O `go mod verify` é a conferência na outra direção: que nada no cache foi mudado desde o
download.

## O grafo inteiro, e qual versão vence

O `go.mod` lista um requisito. O grafo de módulos por trás dele é maior, porque `golang.org/x/text`
tem um `go.mod` próprio:

```
ana@vm:~/mods-accents$ go list -m all
example.com/accents
golang.org/x/mod v0.41.0
golang.org/x/sync v0.23.0
golang.org/x/text v0.42.0
golang.org/x/tools v0.49.0
ana@vm:~/mods-accents$ go mod graph
example.com/accents go@1.27.1
example.com/accents golang.org/x/text@v0.42.0
go@1.27.1 toolchain@go1.27.1
golang.org/x/text@v0.42.0 golang.org/x/tools@v0.49.0
golang.org/x/text@v0.42.0 golang.org/x/mod@v0.41.0
golang.org/x/text@v0.42.0 golang.org/x/sync@v0.23.0
golang.org/x/text@v0.42.0 go@1.26.0
ana@vm:~/mods-accents$ go list -m golang.org/x/tools@latest
golang.org/x/tools v0.51.0
```

O `go mod graph` imprime uma aresta por linha: um módulo e algo de que ele precisa. O
`golang.org/x/text` pede mais três módulos e Go 1.26.0 ou mais novo. Esses três estão no grafo e
nunca foram baixados: o cache vazio do primeiro `tidy` recebeu o `x/text` e mais nada, e o `go.sum`
não tem linha para eles, porque nenhum pacote que este programa importa mora neles.

Agora as versões. O `x/tools` tem uma v0.51.0, e o grafo escolheu a v0.49.0. A regra se chama
**seleção de versão mínima** (minimal version selection): cada módulo declara a menor versão de cada
dependência com que funciona, e o comando go escolhe, para cada módulo do grafo, a maior dessas
mínimas declaradas e nunca algo mais novo. Assim um build não muda porque alguém publicou uma
release de madrugada; ele muda quando um `go.mod` muda, e a lição 40 faz isso de propósito com
`go get`.

## O tidy também remove

O `tidy` faz o `go.mod` combinar com os imports nas duas direções. Pegue o programa em
`~/mods-unused`, o mesmo módulo com a última linha de `main` e o import de `norm` apagados, e
pergunte ao `tidy` o que ele faria, sem deixá-lo fazer:

```
ana@vm:~/mods-unused$ go mod tidy -diff; echo $?
diff current/go.mod tidy/go.mod
--- current/go.mod
+++ tidy/go.mod
@@ -1,5 +1,3 @@
 module example.com/accents
 
 go 1.27.1
-
-require golang.org/x/text v0.42.0

diff current/go.sum tidy/go.sum
--- current/go.sum
+++ tidy/go.sum
@@ -1,2 +0,0 @@
-golang.org/x/text v0.42.0 h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI=
-golang.org/x/text v0.42.0/go.mod h1:ojzP1Z+2QtioaF8DTtO8K5q7JWVVYwZKenzujK0Zd0E=

1
ana@vm:~/mods-unused$ go mod tidy && cat go.mod && wc -c go.sum
module example.com/accents

go 1.27.1
0 go.sum
ana@vm:~/mods-unused$ go mod tidy -diff; echo $?
0
```

O `-diff` não muda nada, imprime o que o `tidy` mudaria e sai com 1 quando isso é qualquer coisa.
Esse status de saída é o que o torna útil numa verificação que roda antes de o código entrar: **um
`go.mod` que não combina com os imports reprova a verificação** em vez de ir se desviando até alguém
notar. Depois do `tidy` de verdade, o requisito sumiu e o `go.sum` está vazio.
