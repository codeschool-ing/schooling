---
title: Um comentário que nomeia um comando
version: 1
---

O `go generate` é o único comando go que não tem trabalho próprio. **Ele procura nos arquivos `.go`
comentários na forma `//go:generate comando argumentos` e roda cada comando, em ordem, no diretório
do pacote que o contém.** O comando pode ser qualquer programa da sua máquina. A intenção, nas
palavras do `go help generate`, é "criar ou atualizar arquivos-fonte Go": um método `String` para um
conjunto de constantes, uma tabela de consulta, o código que a definição de um protocolo descreve. O
programa que escreve se chama gerador, e o comentário que o nomeia é uma diretiva.

A crença comum é que o `go build` roda as diretivas antes, como o `make` roda uma regra antes de
compilar. **Ele nunca roda.** O texto de ajuda diz isso em duas frases: "Go generate is never run
automatically by go build, go test, and so on. It must be run explicitly." Todo o resto sobre código
gerado em Go decorre dessa decisão, e a seção 05 trata de conviver com ela.

## Quatro diretivas e um comentário

Para ver o que o comando go faz com uma diretiva, sem um gerador no meio, crie um módulo à parte em
`~/gen-try` com `go mod init example.com/try` e dê a ele um pacote que só contém diretivas. Salve
como `internal/demo/demo.go`:

```go
// Package demo holds nothing but directives, to show what go generate does
// with each one.
package demo

//go:generate echo file=$GOFILE package=$GOPACKAGE line=$GOLINE arch=$GOARCH
//go:generate pwd
//go:generate printf [%s]\n "two words" two words
//go:generate touch made-by-generate
// go:generate echo this line has a space after the slashes
```

A sintaxe é curta. **A linha começa com `//go:generate` na primeira coluna, sem espaço depois das
barras**, e o resto é um comando e seus argumentos, separados nos espaços. Uma string entre aspas
duplas é um argumento só, interpretada como o Go interpreta uma string literal. `$GOFILE`,
`$GOPACKAGE`, `$GOLINE` e `$GOARCH` são definidas pelo go generate, qualquer outra `$NOME` vem do
ambiente, e nada mais é expandido: não há shell, então um `*` ou um `|` é só um caractere. A última
linha tem um espaço depois das barras, o que a torna um comentário comum.

Primeiro o build, depois a geração:

```
ana@vm:~/gen-try$ go build ./... && ls internal/demo
demo.go
ana@vm:~/gen-try$ go generate ./...
file=demo.go package=demo line=5 arch=amd64
/home/ana/gen-try/internal/demo
[two words]
[two]
[words]
ana@vm:~/gen-try$ ls internal/demo
demo.go
made-by-generate
```

O `go build` compilou o pacote e não rodou nada: o diretório continuou só com o `demo.go`. O
`go generate ./...` rodou então quatro comandos, um por diretiva, de cima para baixo, e cada linha
da saída diz algo sobre as regras:

- `file=demo.go package=demo line=5` descreve a própria diretiva: o arquivo, o pacote e a linha. Um
  gerador lê o `$GOFILE` para saber que arquivo o chamou e o `$GOPACKAGE` para saber que cláusula
  `package` escrever.
- `/home/ana/gen-try/internal/demo` é onde o `pwd` rodou. **Uma diretiva roda no diretório do seu
  pacote**, seja onde for que você digitou `go generate`, então um caminho numa diretiva é relativo
  ao arquivo que a contém.
- `[two words]` saiu como um argumento, e `[two]` e `[words]` como dois. As aspas definiram a
  fronteira e sumiram antes de o `printf` começar.
- `made-by-generate` aparece na listagem porque o `touch` rodou. O que um gerador escreve é um
  arquivo comum, e ele fica.
- Nada veio da última linha. O espaço fez dela um comentário, e o go generate a ignora sem dizer
  nada.

## Lendo os comandos antes de rodá-los

Rodar uma diretiva que você não leu é rodar um programa que você não escolheu, então o go generate
tem flags para olhar primeiro. **O `-n` imprime cada comando e não roda nenhum; o `-x` imprime cada
comando enquanto o roda.** O `-run` recebe uma expressão regular e fica só com as diretivas cuja
linha inteira casa com ela, o `-skip` descarta as que casam, e o `-v` cita cada arquivo conforme o
lê:

```
ana@vm:~/gen-try$ go generate -n ./...
echo file=demo.go package=demo line=5 arch=amd64
pwd
printf [%s]\n two words two words
touch made-by-generate
ana@vm:~/gen-try$ GOARCH=arm64 go generate -x -run echo ./...
echo file=demo.go package=demo line=5 arch=arm64
file=demo.go package=demo line=5 arch=arm64
ana@vm:~/gen-try$ go generate -v -skip "touch|printf" ./...
internal/demo/demo.go
file=demo.go package=demo line=5 arch=amd64
/home/ana/gen-try/internal/demo
```

O `-n` mostra os argumentos depois de as variáveis e as aspas terem sido tratadas, e por isso
`two words` aparece sem aspas: continua sendo um argumento só, e a listagem já não consegue dizer
isso. **O `$GOARCH` é a arquitetura para a qual se compila, não a da máquina.** Definido como `arm64`
nesta máquina amd64, ele disse `arm64`, e um gerador que escreve código por plataforma o lê
exatamente para isso; a lição 16 define o `GOARCH` para valer. O `-run echo` ficou com uma diretiva,
porque a expressão é comparada com a linha inteira da diretiva, `//go:generate echo file=…`, e o
comentário do fim nem é diretiva.

O `go generate` aceita os mesmos padrões de pacote que o `go build`, então `./...` é todo pacote do
módulo. **Dentro de um pacote os arquivos vão em ordem de nome, e dentro de um arquivo as diretivas
vão de cima para baixo.** Se um comando sair com algo diferente de 0, o go generate pula o resto
daquele pacote e relata a falha; a seção 04 mostra isso com um gerador recusando a entrada.

## O passo de quem escreve, não de quem compila

Há um motivo para manter a geração fora do build. Uma diretiva roda qualquer programa, então um
`go build` que rodasse diretivas rodaria o que o código de uma dependência pedisse, em toda máquina
que o compilasse, e exigiria todos os geradores instalados em toda parte. **Em vez disso, gerar é um
passo de quem muda o código**: essa pessoa roda o `go generate`, e os arquivos que ele escreve são
commitados ao lado do código que os pediu. Quem acrescenta o seu módulo ao dele baixa os arquivos
gerados junto com o resto e nunca roda, nem precisa, do seu gerador.

O custo é que o código e os arquivos gerados podem discordar. Nada no `go build` percebe um arquivo
que ninguém regenerou, e as seções 03 e 05 mostram dois jeitos de descobrir.
