---
title: O laboratório em que este curso roda
version: 1
---

Toda lição deste curso pede que você digite algo e leia o que volta, então ela precisa de uma
máquina em que dê para digitar. **A plataforma não fornece nenhuma.** Você monta a sua, e já tem
quase tudo se fez os dois cursos anteriores. Este curso roda no mesmo laboratório, nas mesmas
versões, e só acrescenta algo onde uma lição precisa de coisa nova.

| o quê | qual | montado por completo em |
|---|---|---|
| o toolchain do Go | **Go 1.27.1**, o arquivo oficial em `/usr/local/go` | `go`, lição 3 |
| dois diretórios no `PATH` | `/usr/local/go/bin` e `~/go/bin` | `go`, lição 3 |
| um compilador C | `gcc` do repositório do Ubuntu 24.04 | `go-concurrency`, lição 1, para o detector de corrida da lição 16 |
| um runtime de containers | Podman do repositório do Ubuntu 24.04 | este curso, lição 17, antes de a lição 18 usá-lo |

O compilador C só entra na lição 15, onde o detector de corrida precisa dele, e na lição 23, onde o
Go chama C. As ferramentas que as lições instalam com `go install`, como o gerador do Cobra ou os
linters da lição 8, são baixadas pelo comando go quando a lição pede, e vão para `~/go/bin`.

## Os passos, em resumo

No Ubuntu 24.04 o caminho é este. As duas primeiras linhas desempacotam o arquivo baixado de
go.dev/dl, depois de você conferir o SHA-256 dele com o que aparece ao lado. As duas seguintes
colocam os dois diretórios no seu `PATH` a partir do próximo login, e a última instala o compilador:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
sudo apt install gcc
```

**As duas primeiras linhas não foram executadas neste laboratório**, porque esta máquina não
alcança go.dev. O laboratório pegou a mesma versão pelo proxy de módulos do Go, que é o caminho que
a lição 3 do curso `go` mostra e confere, e o `gcc` já estava instalado. Todo o resto deste curso
foi digitado como você vê.

## Quatro conferências antes de a lição 1 seguir

Saia e entre de novo, ou abra um terminal novo, para o `~/.profile` ser lido. Depois peça a cada
ferramenta que responda. Ana, a aluna de todas as transcrições do curso, trabalha em `~/hits`, o
diretório onde fica o programa desta lição:

```
ana@vm:~/hits$ go version
go version go1.27.1 linux/amd64
ana@vm:~/hits$ command -v go gofmt gcc
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
/usr/bin/gcc
ana@vm:~/hits$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
ana@vm:~/hits$ go env GOROOT GOPATH CGO_ENABLED
/usr/local/go
/home/ana/go
1
ana@vm:~/hits$ echo $PATH | tr : "\n" | grep go
/usr/local/go/bin
/home/ana/go/bin
```

**O `go version` precisa dizer 1.27.1**, porque todas as transcrições do curso foram gravadas com
ele e algumas lições citam o que o compilador imprimiu. O `command -v` mostra o arquivo que o shell
rodaria para cada palavra, e três arquivos querem dizer três ferramentas encontradas.
`CGO_ENABLED=1` é o comando go dizendo que achou um compilador C e vai usá-lo quando pedirem. A
última linha mostra os dois diretórios `bin` no caminho.

## Três maneiras de ter a máquina

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Go e `gcc` no seu próprio Linux ou macOS | cerca de 250 MB para o Go, cerca de 160 MB para o compilador e as bibliotecas que ele traz, e caches que crescem conforme você compila | batem no Ubuntu 24.04; no macOS os comandos batem e algumas saídas mudam |
| **uma máquina virtual** | Ubuntu 24.04 numa VM, com os passos acima lá dentro | o disco de um sistema operacional inteiro, e a memória que você der a ela enquanto roda | batem byte a byte |
| **online** | o Go Playground em go.dev/play | nada | quase nenhuma: não há terminal |

**Este é o curso em que o caminho online deixa de servir.** O Playground compila um arquivo e
mostra o que ele imprimiu. Este curso trata de tudo o que fica em volta desse arquivo: a linha de
comando, o build, os linters, o profiler, um binário para outra máquina. Nada disso tem onde rodar
numa página web. Guarde o Playground para testar um trecho da reflexão da lição 21 no ônibus.

No Windows, a máquina virtual é a escolha certa. O WSL, o Linux que o Windows roda para você, é
uma, e o Multipass ou o VirtualBox dão um Ubuntu 24.04 completo em poucos cliques. Dê a ela 2 GB de
memória e 20 GB de disco; as lições 12 a 14 perfilam um programa que lê cem megabytes, e as imagens
de container da lição 18 querem espaço.

## Quando a instalação falha

Duas falhas respondem por quase todo mundo que trava aqui. A primeira é um shell que não acha o
`go`. Para ver como isso aparece, tire os dois diretórios do `PATH` por um comando:

```
ana@vm:~/hits$ PATH=/usr/bin:/bin; go version; echo $?
bash: line 1: go: command not found
127
```

**O status de saída 127 é o código do próprio shell para "comando inexistente"**, e quer dizer que
o programa nem rodou. O arquivo pode estar perfeitamente desempacotado; o shell apenas não procura
em `/usr/local/go/bin`. Confira se as duas linhas `export` estão no fim do `~/.profile` e entre de
novo: um terminal aberto antes de você acrescentá-las mantém o `PATH` antigo até ser fechado.

A segunda só aparece na lição 15, e por isso vale vê-la agora. Sem compilador C no caminho, o
comando go desliga o cgo em silêncio, e o detector de corrida se recusa a compilar. Aqui está ela
num `PATH` que tem tudo de `/usr/bin` menos o `gcc`:

```
ana@vm:~/race$ PATH=/usr/local/go/bin:$HOME/nogcc; go env CGO_ENABLED; go build -race; echo $?
0
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
ana@vm:~/race$ go build -race && echo built
built
```

A mensagem sugere ligar `CGO_ENABLED=1`, o que é metade da resposta: o cgo ainda precisa de um
compilador para rodar. **Um `CGO_ENABLED` que imprime `0` numa máquina em que você não mexeu nele
quer dizer que o comando go procurou o `gcc` e não achou.** `sudo apt install gcc` resolve, e o
segundo comando, de volta ao `PATH` normal, compila.
