---
title: O protoc e os dois plugins de Go
version: 1
---

Transformar um arquivo `.proto` em Go exige três programas. **O `protoc`**, o compilador de Protocol
Buffers, lê o arquivo e o entende; para cada linguagem, ele entrega o resultado a um **plugin**, um
programa separado chamado `protoc-gen-<alguma-coisa>`, que escreve o código. O Go precisa de dois:
**o `protoc-gen-go`** escreve os tipos das mensagens, e **o `protoc-gen-go-grpc`** escreve o cliente e o
servidor.

## Três jeitos de conseguir o protoc

| caminho | o que custa | para este curso |
|---|---|---|
| **o pacote do Ubuntu**, `protobuf-compiler` (recomendado) | uns 5 MB com as duas bibliotecas dele, do repositório que você já usa | a versão 3.21.12, a que toda transcrição usou |
| **um arquivo de release** da página do projeto protobuf no GitHub | um download, descompactado num diretório do seu `PATH` | uma versão mais nova; o Go gerado é o mesmo para este arquivo |
| **o `buf`**, uma ferramenta à parte que substitui o `protoc` | mais um programa para aprender, com arquivo de configuração próprio | uma boa escolha para uma equipe; não é usado aqui |

```sh
sudo apt install -y protobuf-compiler
```

Os plugins são programas Go, instalados com `go install` em versões fixadas, como o sqlc na aula 8:

```
ana@vm:~$ protoc --version
libprotoc 3.21.12
ana@vm:~$ go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12
ana@vm:~$ go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2
ana@vm:~$ protoc-gen-go --version; protoc-gen-go-grpc --version
protoc-gen-go v1.36.12
protoc-gen-go-grpc 1.6.2
```

**protoc 3.21.12, protoc-gen-go v1.36.12 e protoc-gen-go-grpc 1.6.2.** Os arquivos gerados registram as
versões que os fizeram, então uma equipe fixa as três, como fixa o sqlc.

## Quando um plugin não é encontrado

O protoc encontra um plugin pelo nome no seu `PATH`, e os plugins moram em `~/go/bin`. Um shell cujo
`PATH` não tem esse diretório, o erro mais comum numa máquina nova, recebe isto:

```
ana@vm:~/boxoffice$ PATH=/usr/bin:/bin protoc --go_out=. --go_opt=module=example.com/boxoffice proto/seats.proto
protoc-gen-go: program not found or is not executable
Please specify a program using absolute path or make sure the program is available in your PATH system variable
--go_out: protoc-gen-go: Plugin failed with status code 1.
```

**`program not found or is not executable` é sobre o `PATH`, não sobre o protoc.** O conserto é a
segunda linha da seção 02 da aula 1 no `~/.profile`, `export PATH=$PATH:$HOME/go/bin`, e um novo login.
Se o próprio protoc estiver faltando, o shell diz `command not found` antes de o protoc entrar na
história.
