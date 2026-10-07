---
title: run, build e install
version: 1
---

`go run` parece um interpretador: você entrega o código-fonte e a saída do programa volta. **Não
é.** Go não tem interpretador. O `go run` compila o programa num binário, executa o binário e o
guarda no **cache de build** do comando go, caso você peça de novo. O cache fica fácil de ver
quando é esvaziado antes:

```
ana@vm:~/hello$ go clean -cache
ana@vm:~/hello$ time go run .
Hello, Go

real	0m4.493s
user	0m10.340s
sys	0m1.611s
ana@vm:~/hello$ time go run .
Hello, Go

real	0m0.044s
user	0m0.060s
sys	0m0.032s
```

A primeira execução levou quatro segundos e meio, e quase nada disso foi a saudação: com o cache
vazio, o comando go recompilou as partes da biblioteca padrão que este programa usa antes de
compilar o próprio programa. A segunda levou 44 milissegundos, porque nada tinha mudado e o binário
já estava lá. Mude um caractere de `hello.go` e só este pacote é compilado de novo; a biblioteca
padrão continua no cache.

O que o `go run` não faz é deixar um arquivo que você encontre. O binário fica dentro do cache, que
o comando go administra e ninguém navega. Isso serve enquanto você experimenta e não serve para
nada que você queira guardar.

## go build: um arquivo que você entrega a alguém

O `go build` compila o pacote do diretório atual e deixa o binário ao lado do código-fonte, com o
nome do último elemento do caminho do módulo:

```
ana@vm:~/hello$ go build
ana@vm:~/hello$ wc -c go.mod hello.go hello
     36 go.mod
    106 hello.go
2342465 hello
2342607 total
ana@vm:~/hello$ ./hello
Hello, Go
ana@vm:~/hello$ file hello
hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=TSzTWGWavtvuaa9Lv40Z/FyHeT0PVUvKjCUEZRLRW/hreRnSolAyQtmBmaupMF/MGfJ8Lr9sq7zDRhl_sZI, BuildID[sha1]=75793a032d6b4283f7e1db392dc303cf4d6c468d, with debug_info, not stripped
```

**106 bytes de código-fonte viraram 2.342.465 bytes de programa**, e o `go build` não imprimiu
nada, que é o jeito de o comando go dizer que deu certo. O tamanho não é a saudação. É o
**runtime** de Go, que todo programa Go carrega dentro de si: o coletor de lixo da lição 24, o
escalonador, o código que imprime um stack trace quando algo entra em pânico. Um programa escrito em
C pega emprestado quase tudo isso de bibliotecas que já estão na máquina; um programa Go traz o seu.

É isso que `statically linked` quer dizer na linha do `file`, e é a troca que a lição 1 descreveu.
O binário pede à máquina um kernel e mais nada, então você pode copiar este único arquivo para
outra máquina Linux da mesma arquitetura e executá-lo lá. Não há runtime para instalar antes nem
versão de biblioteca para casar.

O `-o` dá outro nome à saída, que é como você compila sem se importar com o nome do módulo:

```
ana@vm:~/hello$ go build -o greet .
ana@vm:~/hello$ ./greet
Hello, Go
```

## go install: no seu PATH

O `go install` gera o mesmo binário e o coloca no diretório que o comando go usa para programas,
`~/go/bin`, a menos que você defina `GOBIN`. A lição 3 pôs esse diretório no `PATH` do laboratório,
então o programa passa a rodar pelo nome, de qualquer lugar:

```
ana@vm:~/hello$ go install
ana@vm:~/hello$ ls ~/go/bin
hello
ana@vm:~/hello$ cd ~ && hello
Hello, Go
```

Os três comandos, então, compilam do mesmo jeito e diferem em **onde o binário vai parar**:

| comando | compila | o binário vai para | use para |
|---|---|---|---|
| `go run .` | sim, sem informação para depurador | o cache de build, e ele o executa | experimentar |
| `go build` | sim | o diretório atual | um arquivo para copiar para outro lugar |
| `go install` | sim | `~/go/bin` (ou `GOBIN`) | uma ferramenta que você quer chamar pelo nome |

Os três compartilham o cache de build do início desta seção, então compilar depois de executar
quase não custa nada: o que foi compilado para um é reaproveitado pelos outros.
