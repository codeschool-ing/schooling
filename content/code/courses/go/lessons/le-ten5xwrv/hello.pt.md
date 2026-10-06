---
title: O programa, linha a linha
version: 1
---

O primeiro programa na maioria das linguagens tem uma linha. Em Go tem oito, e as sete a mais não
são cerimônia: **cada uma é uma regra da linguagem que você vai encontrar em todo arquivo que
escrever.** Aqui está ele inteiro, num diretório só dele, `~/hello`:

```schooling-example
{
  "language": "go",
  "file": "hello.go",
  "parts": [
    {
      "code": "// Command hello prints a greeting.\n",
      "note": "**Um comentário logo acima da cláusula `package` é a documentação do pacote.** Num programa ele começa, por convenção, com a palavra `Command` e o nome do programa, e o `go doc` o imprime (seção 04)."
    },
    {
      "code": "package main\n",
      "note": "**Todo arquivo Go começa dizendo a que pacote pertence.** `main` é o único nome especial: um pacote chamado `main` vira um programa que você executa, e qualquer outro nome vira uma biblioteca que alguém importa."
    },
    {
      "code": "\nimport \"fmt\"\n",
      "note": "**O que o arquivo usa de fora, pelo caminho de importação.** `fmt` é o pacote de formatação da biblioteca padrão. Importar algo que o arquivo não usa é erro de compilação, não aviso; a seção 05 mostra."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(\"Hello, Go\")\n}\n",
      "note": "**`main` no pacote `main` é onde o programa começa**, e não recebe argumentos nem devolve nada. `fmt.Println` é a função `Println` do pacote `fmt`: o P maiúsculo é o que deixa outro pacote chamá-la, e esse é o assunto da lição 39."
    }
  ]
}
```

A indentação dentro de `main` é uma tabulação, não espaços. Ninguém escolheu isso à mão: é o que o
`gofmt` escreve, e a seção 05 explica por que todo arquivo Go do mundo é diagramado pelo mesmo
programa.

## Executando

O jeito mais rápido de ver funcionar é `go run` com o nome do arquivo:

```
ana@vm:~/hello$ go run hello.go
Hello, Go
```

Isso funciona para um arquivo só e para de funcionar logo depois. Um programa de verdade é um
**módulo**, um diretório com um arquivo `go.mod` na raiz que diz como o código se chama e para qual
Go ele foi escrito. O `go mod init` cria um:

```
ana@vm:~/hello$ go mod init example.com/hello
go: creating new go.mod: module example.com/hello
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/hello$ cat go.mod
module example.com/hello

go 1.27.1
ana@vm:~/hello$ go run .
Hello, Go
```

Duas linhas, e as duas importam. `module example.com/hello` é o **caminho** do módulo, o nome pelo
qual outro programa o importaria; `example.com` é um domínio reservado para exemplos, então nada de
verdade responde ali. `go 1.27.1` é a versão da linguagem que este módulo espera, escrita a partir
do toolchain que executou o comando. A dica sobre `go mod tidy` trata de dependências, e este
programa não tem nenhuma; a lição 38 é onde ela passa a valer.

Com um `go.mod` no lugar, `go run .` quer dizer "o pacote deste diretório", seja qual for o nome
dos arquivos. É essa a forma que o resto do curso usa.

**Um programa Go não precisa de classe, de objeto nem de arquivo com nome de coisa alguma.** Precisa
de um pacote chamado `main` com uma função chamada `main` dentro. Todo o resto do arquivo acima é o
que esse programa por acaso faz.
