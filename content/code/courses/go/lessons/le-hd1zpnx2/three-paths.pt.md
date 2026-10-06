---
title: Três jeitos de ter um Go
version: 1
---

Toda lição a partir da 4 pede que você digite alguma coisa e leia o que volta, então você precisa
de um toolchain de Go em algum lugar onde dê para digitar. Um toolchain de Go é um diretório: o
comando `go`, o compilador que ele aciona e o código-fonte da biblioteca padrão. **Há três lugares
para colocá-lo, e o curso recomenda o primeiro**: instalado no seu próprio computador.

| caminho | o que você ganha | o que custa ao seu computador | as transcrições do curso |
|---|---|---|---|
| **instalado** (recomendado) | o arquivo oficial descompactado em `/usr/local/go` | um download, cerca de um quarto de gigabyte em disco e caches que crescem conforme você compila | rodam como impressas no Linux, e quase assim no macOS |
| **uma máquina virtual ou um contêiner** | um sistema Linux com Go dentro, separado do seu | o disco de um sistema operacional inteiro, e memória reservada enquanto ele roda | rodam como impressas, byte a byte, numa máquina Ubuntu |
| **online** | uma página em go.dev/play onde você digita um programa e aperta Run | nada | quase todas indisponíveis: não há terminal |

## Instalado: o caminho recomendado

O caminho oficial é um arquivo compactado de **go.dev/dl**, um por sistema operacional e
processador, com o SHA-256 de cada arquivo impresso ao lado para você conferir o download antes de
confiar nele. No Linux as instruções são dois comandos e uma linha num arquivo. Isso **não foi
executado neste laboratório**, porque esta máquina não alcança go.dev:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
```

A primeira linha importa tanto quanto a segunda. Descompactar uma versão nova por cima de um
`/usr/local/go` antigo deixa arquivos das duas para trás, e um toolchain que é metade de uma versão
e metade de outra falha de jeitos que nenhuma mensagem explica. **Atualizar é apagar e
descompactar, nunca mesclar.** No macOS e no Windows a mesma página oferece um instalador que faz
os dois passos por você.

O laboratório pegou a mesma versão por outra estrada. O comando go consegue baixar um toolchain
inteiro do **proxy de módulos**, o servidor que também entrega todo módulo Go público, e a lição 2
mostra o comando go fazendo exatamente isso sozinho. O proxy publica quando cada versão foi
gerada e o tamanho do que entrega:

```
ana@vm:~/setup$ curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.info; echo
{"Version":"v0.0.1-go1.27.1.linux-amd64","Time":"2026-08-28T16:20:06Z"}
ana@vm:~/setup$ curl -sL https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.27.1.linux-amd64.zip | wc -c
75704807
```

Cerca de 76 MB para baixar, portanto. Descompactado, é o diretório com que toda transcrição deste
curso foi gravada:

```
ana@vm:~/setup$ go version
go version go1.27.1 linux/amd64
ana@vm:~/setup$ cat /usr/local/go/VERSION
go1.27.1
time 2026-08-28T16:20:06Z
ana@vm:~/setup$ ls /usr/local/go
CONTRIBUTING.md
LICENSE
PATENTS
README.md
SECURITY.md
VERSION
bin
codereview.cfg
go.env
lib
pkg
src
ana@vm:~/setup$ ls /usr/local/go/bin
go
gofmt
ana@vm:~/setup$ du -sh /usr/local/go
253M	/usr/local/go
```

Dois programas em `bin`, e 253 MB no total, a maior parte em `src`: o código-fonte da biblioteca
padrão, que é o que o `go doc` lê na lição 4 sem rede. O arquivo `VERSION` traz o mesmo horário
de build que o proxy informou, então o Go do laboratório e o que go.dev distribui são uma versão
só.

**Nada fora desse diretório pertence ao toolchain.** Apagar `/usr/local/go` desinstala o Go por
completo; as únicas outras coisas em que ele mexeu são os caches que a seção 03 aponta, e esses
são seus.

## Uma máquina virtual ou um contêiner

Uma máquina virtual é um segundo computador inteiro dentro do seu. Instale o Ubuntu 24.04 numa,
siga dentro dela o caminho instalado, e toda transcrição deste curso bate com o que você vê, prompt
e tudo. Isso vale alguma coisa no Windows, onde alguns comandos que cercam o Go nestas lições, como
`file` e `du`, não existem no shell comum. O WSL, o Linux que o Windows sabe rodar, é uma máquina
dessas. O preço é o disco de um sistema operacional inteiro e a memória que a máquina virtual
segura enquanto roda, o que um notebook mais velho sente.

Um contêiner é mais leve. A imagem oficial `golang` traz a versão como `golang:1.27.1` no Docker
Hub, e um comando como o de baixo abre um shell nela com o seu diretório atual montado dentro.
Ele também **não foi executado neste laboratório**:

```sh
docker run --rm -it -v "$PWD":/work -w /work golang:1.27.1 bash
```

O `--rm` joga o contêiner fora quando você sai do shell, então tudo o que você não salvou em
`/work` vai junto, inclusive os módulos baixados da lição 38. O próprio Docker precisa ser
instalado antes, o que no macOS e no Windows significa rodar uma máquina virtual de qualquer jeito.

## Online

O **Go Playground**, em go.dev/play, compila e roda um programa num servidor e mostra o que ele
imprimiu. Não custa nada ao seu computador e é um bom lugar para testar um trecho das lições 5 a
10. Ele não foi usado neste curso, porque o que falta nele é tudo o que cerca o programa. Não há
terminal, então não há `go build`, `go install`, `go mod`, `go doc`, nem arquivos seus de uma visita
para a outra. Da lição 4 em diante, quase tudo o que este curso digita não tem para onde ir ali.

Então: **instale se puder, use uma máquina virtual Linux se quiser as transcrições exatas, e deixe
o Playground para o ônibus.**
