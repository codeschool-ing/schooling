---
title: Do quadro branco ao go1.27.1
version: 1
---

O número de versão engana em duas direções ao mesmo tempo. Leia `go1.27.1` como uma versão 1 que
nunca chegou à 2, e a linguagem parece parada; leia cada versão como uma linguagem nova, e dezessete
anos de Go parecem uma pilha de reescritas. Nenhuma das duas leituras está certa. **Go 1 é uma
linguagem só, mantida compatível desde 2012, e o número depois dela conta as versões dessa
linguagem.** O seu toolchain diz qual é a dele:

```
ana@vm:~/history$ go version
go version go1.27.1 linux/amd64
ana@vm:~/history$ cat /usr/local/go/VERSION
go1.27.1
time 2026-08-28T16:20:06Z
ana@vm:~/history$ go list -f '{{context.ReleaseTags}}' runtime
[go1.1 go1.2 go1.3 go1.4 go1.5 go1.6 go1.7 go1.8 go1.9 go1.10 go1.11 go1.12 go1.13 go1.14 go1.15 go1.16 go1.17 go1.18 go1.19 go1.20 go1.21 go1.22 go1.23 go1.24 go1.25 go1.26 go1.27]
```

`/usr/local/go/VERSION` é um arquivo de duas linhas presente em toda instalação: a versão e o
momento em que ela foi gerada. A lista depois dele é o registro do próprio comando go das versões
com que ele é compatível, de `go1.1` a `go1.27`. Cada uma é uma **build tag**: um arquivo que começa
com `//go:build go1.21` só é compilado pelo Go 1.21 em diante, e é assim que um pacote usa algo novo
e ainda compila numa versão mais antiga. São vinte e sete versões desde o Go 1, e o `.1` no fim diz
que esta é a primeira versão de correção do 1.27, o que a seção 04 explica.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo de 2007 a 2026. 2007: a linguagem é rascunhada num quadro branco. 2009: pública, código aberto. 2012: go1, a promessa de compatibilidade. 2015: go1.5, compilador escrito em Go. 2018: go1.11, módulos. 2022: go1.18, generics. 2023: go1.21.0, troca de toolchain. 2024: go1.22.0, uma variável por volta do laço. 2026: go1.27.1, este laboratório. Seis anos separam go1.5 de go1.11 e go1.18, e os três últimos marcos cabem em três anos.\"><path d=\"M30 150 L700 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M44.0 147 L44.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M77.6 147 L77.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M111.2 147 L111.2 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M144.8 147 L144.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M178.4 147 L178.4 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M212.0 147 L212.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M245.60000000000002 147 L245.60000000000002 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M279.20000000000005 147 L279.20000000000005 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M312.8 147 L312.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M346.40000000000003 147 L346.40000000000003 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M380.0 147 L380.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M413.6 147 L413.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M447.20000000000005 147 L447.20000000000005 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M480.8 147 L480.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M514.4000000000001 147 L514.4000000000001 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M548.0 147 L548.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M581.6 147 L581.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M615.2 147 L615.2 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M648.8000000000001 147 L648.8000000000001 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M682.4 147 L682.4 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M44.0 144 L44.0 76\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"36.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rascunhada num quadro branco</text><rect x=\"40.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2007</text><path d=\"M111.2 156 L111.2 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"111.2\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pública, código aberto</text><rect x=\"107.2\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"111.2\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2009</text><path d=\"M212.0 144 L212.0 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"212.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1</text><text x=\"212.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a promessa de compatibilidade</text><rect x=\"208.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2012</text><path d=\"M312.8 156 L312.8 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"312.8\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">compilador escrito em Go</text><text x=\"312.8\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.5</text><rect x=\"308.8\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.8\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2015</text><path d=\"M413.6 144 L413.6 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"413.6\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.11</text><text x=\"413.6\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">módulos</text><rect x=\"409.6\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"413.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2018</text><path d=\"M548.0 156 L548.0 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"548.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">generics</text><text x=\"548.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.18</text><rect x=\"544.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2022</text><path d=\"M581.6 144 L581.6 76\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"581.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.21.0</text><text x=\"581.6\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">troca de toolchain</text><rect x=\"577.6\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"581.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2023</text><path d=\"M615.2 156 L615.2 222\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"615.2\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma variável por volta do laço</text><text x=\"615.2\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.22.0</text><rect x=\"611.2\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.2\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M682.4 144 L682.4 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"682.4\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.27.1</text><text x=\"682.4\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">este laboratório</text><rect x=\"678.4\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"682.4\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026</text></svg>", "caption": "As versões que esta lição cita, numa escala de anos. Tudo depois de go1 é uma versão da mesma linguagem, mantida compatível com ela.", "same": ["generics"]}
```

## As versões que mais mudaram as coisas

A lição 1 contou o começo: um quadro branco em setembro de 2007 e um projeto público, de código
aberto, em 10 de novembro de 2009. Todas as datas abaixo vêm do histórico de versões do projeto Go.

**Go 1, 28 de março de 2012**, é a linha a partir da qual o resto da linha do tempo é traçado. Antes
dele, Go saía em snapshots semanais, e o próprio Go 1 veio com uma ferramenta, `go fix`, para
atualizar programas escritos contra eles. O Go 1 congelou a especificação e prometeu que um programa
escrito para ela continuaria compilando, que é a seção 03.

**Go 1.5, 19 de agosto de 2015**, é quando Go passou a compilar a si mesmo. Os primeiros
compiladores eram escritos em C; do 1.5 em diante, o compilador e o runtime são Go, com um pouco de
assembly. A nota que explica como Go é gerado hoje ainda diz isso:

```
ana@vm:~/history$ sed -n 3,4p /usr/local/go/src/cmd/dist/README
As of Go 1.5, dist and other parts of the compiler toolchain are written
in Go, making bootstrapping a little more involved than in the past.
```

É por isso que a lição 1 conseguiu compilar o comando go a partir do código-fonte sem nada além de
Go instalado.

**Go 1.11, 24 de agosto de 2018**, trouxe os módulos: um arquivo `go.mod` que dá nome ao código e às
suas dependências. Antes dele, todo código Go morava numa única árvore de diretórios chamada
`GOPATH`, que a lição 3 mostra. A lição 4 escreveu um `go.mod`, e a lição 38 trata de módulos de
verdade.

**Go 1.18, 15 de março de 2022**, trouxe generics, funções e tipos que servem para vários tipos ao
mesmo tempo. As lições 30 e 31 os ensinam como a parte comum da linguagem que eles são hoje; a seção
03 mostra um `go.mod` mais antigo recusando-os.

**Go 1.21.0, 8 de agosto de 2023**, ensinou o comando go a baixar e executar outra versão de Go
quando um módulo pede, o que a seção 04 faz. Também mudou o nome das versões. A primeira versão de
uma série se chamava só `go1.20`; a partir do 1.21 ela é `go1.21.0`, então todo nome de versão
agora tem três números.

**Go 1.22.0, 6 de fevereiro de 2024**, mudou o que é a variável de um laço `for`: uma por volta do
laço, em vez de uma para o laço inteiro. É o caso mais claro da promessa da seção 03 em ação, porque
mudou o significado de código que já compilava, e a seção 03 o executa dos dois jeitos.

Depois vem a versão que este laboratório roda, go1.27.1, gerada em 28 de agosto de 2026 segundo o
seu arquivo `VERSION`. **Vinte e sete versões acrescentaram coisas à linguagem e à biblioteca, e
cada uma foi submetida à promessa do Go 1.** A que mudou o significado de código antigo, a 1.22, só
fez isso para os módulos que pedem, e como um módulo pede é a próxima seção.
