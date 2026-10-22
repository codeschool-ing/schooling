---
title: Instalando o sqlc
version: 1
---

O sqlc é um programa Go, e o jeito Go de instalar um programa Go é o `go install`, que baixa o código,
compila e põe o binário em `~/go/bin`, o diretório que a seção 02 da aula 1 pôs no seu `PATH`. **Ele
precisa de uma coisa a mais do que a maioria das ferramentas Go: um compilador C.** O sqlc entende o SQL
do PostgreSQL usando o próprio parser do PostgreSQL, escrito em C e compilado dentro do sqlc por meio do
cgo, a ponte do Go para o C. É por isso que a aula 1 citou o compilador entre as coisas de que este
curso precisa.

## Três jeitos de obtê-lo

| caminho | o que custa | para este curso |
|---|---|---|
| **`go install`** (recomendado) | o gcc do repositório do Ubuntu, uns 80 MB, e um minuto ou mais de compilação | o binário que toda transcrição usou |
| **um binário de release** da página do sqlc no GitHub | um download, nenhum compilador | o mesmo programa, se você pegar a mesma versão |
| **a imagem de container `sqlc/sqlc`** | um motor de containers, que a aula 16 instala | funciona, com o projeto montado dentro do container |

O compilador C vale a pena de qualquer jeito: o detector de corrida da aula 15 também precisa dele. No
Ubuntu é um pacote só, e é o mesmo que o `go-concurrency` instalou para o detector de corrida na aula 1:

```sh
sudo apt install -y gcc
```

Depois o próprio sqlc, na versão com que esta aula foi escrita:

```
ana@vm:~$ go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
ana@vm:~$ sqlc version; command -v sqlc
v1.31.1
/home/ana/go/bin/sqlc
```

O `go install` acima não imprimiu nada porque o laboratório já tinha compilado esta versão uma vez, o que
levou pouco mais de um minuto de compilação em quatro núcleos; na primeira vez, ele imprime uma lista de
downloads e depois trabalha em silêncio por um tempo. **Fixe a versão, `@v1.31.1`, em vez de
`@latest`**: o código gerado carrega a versão que o produziu, e dois desenvolvedores em duas versões
ficam regerando os arquivos um do outro, num vaivém.

## Quando falta o compilador

Numa máquina sem compilador C, o build para no primeiro pacote que precisa de um:

```
ana@vm:~$ CC=gcc-missing go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
# runtime/cgo
cgo: C compiler "gcc-missing" not found: exec: "gcc-missing": executable file not found in $PATH
ana@vm:~$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
```

O laboratório tem gcc, então esta falha foi produzida apontando o `CC`, a variável que o cgo lê para
achar o compilador, para um que não existe; **sem o gcc instalado, a mensagem é a mesma com `gcc` nela.**
O `runtime/cgo` é o primeiro pacote que precisa de C. O conserto é o `apt install` acima, e o segundo
comando mostra o que um compilador funcionando responde.
