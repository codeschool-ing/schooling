---
title: Sua máquina, como o go-concurrency a deixou
version: 1
---

Este curso escreve um servidor e conversa com ele pelo terminal, então antes da primeira linha de
código você precisa de duas coisas respondendo no seu próprio computador: **o Go 1.27.1 e o
`curl`**. Nenhuma das duas é novidade. O curso `go` montou este ambiente na aula 3, e o
`go-concurrency` o usou por trinta aulas; se você veio por eles, confira abaixo e siga em frente.
Se chegou aqui por outro caminho, os próximos parágrafos são a instalação em resumo, e a aula 3 do
`go` é a mesma instalação por inteiro.

A plataforma não te dá máquina nenhuma. Tudo neste curso é digitado num computador que você
controla, e **toda transcrição foi gravada no Ubuntu 24.04**, por um usuário chamado `ana` numa
máquina chamada `vm`, e é por isso que o prompt diz `ana@vm`.

## Três lugares para rodar

| caminho | o que custa ao seu computador | as transcrições |
|---|---|---|
| **instalado** (recomendado) | o diretório de 253 MB do Go, mais caches que crescem a cada módulo baixado | rodam como impressas no Linux, e quase isso no macOS |
| **uma máquina virtual** com Ubuntu 24.04 | o disco de um sistema operacional inteiro, e memória presa enquanto ela roda | rodam como impressas, byte a byte |
| **online**, no Go Playground | nada | quase inúteis: ele roda um programa e mostra a saída, sem terminal onde digitar `curl` |

**Instale se puder.** Uma máquina virtual compensa o custo no Windows, onde o `curl` se comporta
de outro jeito e alguns comandos destas aulas não existem; o WSL, o Linux que o Windows sabe rodar,
conta como uma. O Playground serve para conferir o que uma função devolve e não serve para um
servidor, que é o assunto inteiro aqui.

Aulas seguintes acrescentam mais duas coisas, cada uma instalada na aula que primeiro precisa
dela, com seus próprios caminhos e sua própria seção sobre o que falha: **o PostgreSQL 16 na aula 6
e um motor de containers na aula 16.** Uma terceira, o compilador C `gcc`, é a que a aula 1 do
`go-concurrency` instalou para o detector de corrida; a aula 8 também precisa dele, e diz como
consegui-lo se você não fez aquele curso.

## A instalação em resumo

No Linux, o Go é um arquivo compactado de go.dev/dl descompactado em `/usr/local/go`, depois de
apagar o que estivesse lá, e duas linhas no `~/.profile`. Estes são os comandos que a aula 3 do
`go` roda; eles não foram rodados de novo para este curso:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
```

Saia da sessão e entre de novo, para o shell ler o arquivo. O `curl` vem com a maioria das
instalações do Ubuntu; se a conferência abaixo disser que ele não existe, `sudo apt install curl`
resolve.

## A conferência

```
ana@vm:~/boxoffice$ go version
go version go1.27.1 linux/amd64
ana@vm:~/boxoffice$ go env GOROOT GOPATH GOTOOLCHAIN
/usr/local/go
/home/ana/go
local
ana@vm:~/boxoffice$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
```

Três respostas para ler. **A versão é a 1.27.1**, aquela com que toda transcrição foi gravada; uma
1.27 mais nova se comporta igual, e uma versão mais antiga pode não ter algo que uma aula seguinte
usa. `GOROOT` é o diretório que você descompactou. `GOTOOLCHAIN=local` é escolha do laboratório, e
faz o comando go recusar um módulo que peça um Go mais novo em vez de baixar um; na sua máquina
provavelmente aparece `auto`, e os dois servem.

O projeto mora num diretório próprio, e o módulo dele precisa de um nome. Qualquer nome serve para
um programa que ninguém importa; este segue o costume de um domínio que você controla:

```
ana@vm:~/boxoffice$ go mod init example.com/boxoffice
go: creating new go.mod: module example.com/boxoffice
ana@vm:~/boxoffice$ cat go.mod
module example.com/boxoffice

go 1.27.1
```

## Quando ele não responde

**`go: command not found` é o shell, não o Go**: as duas linhas faltam no `~/.profile`, ou este
terminal foi aberto antes de elas estarem lá. **Um `go version` mais antigo do que o que você
instalou** quer dizer que outro `go` está antes no `PATH`, e `command -v go` diz qual. A aula 3 do
`go`, seção 05, desmonta cada um desses com a mensagem exata, e também um proxy que não responde.

Mais um, que este curso encontra e o curso `go` não encontrou. **Um servidor precisa de uma porta,
e só um programa por vez pode escutar nela.** A próxima seção mostra a mensagem que aparece quando
outra coisa já está segurando a porta 8080, e o que fazer.
