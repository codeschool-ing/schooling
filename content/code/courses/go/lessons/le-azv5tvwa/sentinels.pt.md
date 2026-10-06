---
title: Um erro que não é uma falha
version: 1
---

Todo erro até aqui queria dizer que algo deu errado: um arquivo que falta, um número inválido, um
valor fora da faixa. Isso torna natural ler `err != nil` como "falhou". **Só quer dizer que a função
tinha algo a dizer além do resultado puro**, e o caso mais simples em que isso não é falha é o fim
da entrada. Este programa lê uma string de quatro em quatro bytes:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"strings\"\n)\n\nfunc main() {\n\tr := strings.NewReader(\"Hello, Go\")\n",
      "note": "`strings.NewReader` transforma uma string em algo com um método `Read`, o mesmo método que um arquivo ou uma conexão de rede tem, então o laço abaixo leria qualquer um deles."
    },
    {
      "code": "\tbuf := make([]byte, 4)\n\tfor {\n\t\tn, err := r.Read(buf)\n\t\tfmt.Printf(\"%d %q %v\\n\", n, buf[:n], err)\n",
      "note": "**`Read` preenche o quanto puder de `buf` e diz quantos bytes pôs ali.** O laço imprime essa contagem, esses bytes e o erro antes de decidir qualquer coisa, porque os bytes vêm primeiro: um leitor pode entregar dados e um erro na mesma chamada."
    },
    {
      "code": "\t\tif err == io.EOF {\n\t\t\tbreak\n\t\t}\n",
      "note": "**`io.EOF` é o leitor dizendo que a entrada acabou.** É a saída esperada do laço, então o programa sai dele e segue em frente."
    },
    {
      "code": "\t\tif err != nil {\n\t\t\tfmt.Println(\"read failed:\", err)\n\t\t\treturn\n\t\t}\n\t}\n\tfmt.Println(\"done\")\n}\n",
      "note": "Qualquer outro erro é uma falha de verdade, e só esse é relatado como falha."
    }
  ],
  "output": "4 \"Hell\" <nil>\n4 \"o, G\" <nil>\n1 \"o\" <nil>\n0 \"\" EOF\ndone\n"
}
```

A terceira chamada devolveu o último byte e `nil`; a quarta não devolveu nada e `io.EOF`, e o
programa imprimiu `done`. Nada falhou. O leitor ficou sem entrada, e `io.EOF` é como todo método
`Read` em Go diz isso, de uma string como esta a um arquivo ou uma conexão de rede.

**`io.EOF` é um sentinela: um erro guardado numa variável para que quem chama o reconheça pela
identidade.** A lição 33 mostrou por que isso funciona. Dois erros criados por `errors.New` com as
mesmas palavras não são iguais, então um valor criado uma vez e devolvido toda vez casa com
exatamente uma coisa, a variável que o guarda, e nunca com um erro sem relação que por acaso tenha
a mesma mensagem.

## O único sentinela comparado com `==`

A lição 34 disse para usar `errors.Is` em vez de `==`, e o laço acima escreveu `err == io.EOF`. A
documentação de `io.EOF` é o motivo de isso valer aqui:

```
ana@vm:~/sentinel$ go doc io.EOF
package io // import "io"

var EOF = errors.New("EOF")
    EOF is the error returned by Read when no more input is available. (Read
    must return EOF itself, not an error wrapping EOF, because callers will test
    for EOF using ==.) Functions should return EOF only to signal a graceful
    end of input. If the EOF occurs unexpectedly in a structured data stream,
    the appropriate error is either ErrUnexpectedEOF or some other error giving
    more detail.

```

O parêntese é uma regra para quem escreve um método `Read`, e **é a regra que torna `== io.EOF`
seguro: um leitor promete nunca embrulhá-lo.** Um sentinela que vem sem essa promessa é conferido
com `errors.Is`, que encontra `io.EOF` do mesmo jeito.

As duas últimas frases traçam uma linha que vale guardar. O fim de um fluxo que podia terminar é
`io.EOF`. O fim de um fluxo no meio de alguma coisa, um arquivo cortado na metade de um registro, é
uma falha de verdade, e recebe outro erro, `io.ErrUnexpectedEOF` ou um com mais detalhe, para que os
dois nunca se confundam.

Uma função que lê até o fim por você nem repassa o sentinela:

```
ana@vm:~/sentinel$ go doc io.ReadAll
package io // import "io"

func ReadAll(r Reader) ([]byte, error)
    ReadAll reads from r until an error or EOF and returns the data it read.
    A successful call returns err == nil, not err == EOF. Because ReadAll is
    defined to read from src until EOF, it does not treat an EOF from Read as an
    error to be reported.

```

**Se um erro é falha ou não depende de quem perguntou.** Para o laço acima, o fim da entrada era a
saída. Para `io.ReadAll`, a quem pediram tudo, chegar ao fim é sucesso, e ela diz `nil`.

## O que a biblioteca padrão declara

`io` declara seis sentinelas, e o `go doc` os lista com o `errors.New` que criou cada um:

```
ana@vm:~/sentinel$ go doc io | grep '^var'
var EOF = errors.New("EOF")
var ErrClosedPipe = errors.New("io: read/write on closed pipe")
var ErrNoProgress = errors.New("multiple Read calls return no data or error")
var ErrShortBuffer = errors.New("short buffer")
var ErrShortWrite = errors.New("short write")
var ErrUnexpectedEOF = errors.New("unexpected EOF")
```

Cinco dos seis se chamam `Err` seguido do que aconteceu, e essa é a convenção: **o nome de um
sentinela começa com `Err`**, do jeito que os tipos de erro da lição 32 terminam com `Error`. `EOF` é
a exceção. A lição 34 encontrou `fs.ErrNotExist` e os vizinhos dele, a seção 04 usa `ErrSyntax` e
`ErrRange` de `strconv`, e a seção 03 declara um seu.
