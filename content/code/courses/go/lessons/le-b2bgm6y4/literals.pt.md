---
title: Dois tipos de literal de string
version: 1
---

Um literal de string parece ser o texto entre as aspas, e em Go isso é só meia verdade. **Go tem
dois tipos de literal de string: o interpretado, entre aspas duplas, em que uma barra invertida
começa um escape, e o bruto, entre crases, em que cada caractere significa ele mesmo.** O programa
em `~/strings-lit` põe os dois lado a lado:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"tab:\\tend\")\n",
      "note": "Entre aspas duplas `\\t` é um caractere só, uma tabulação, e a saída tem uma tabulação de verdade entre `tab:` e `end`."
    },
    {
      "code": "\tfmt.Println(\"quote: \\\" backslash: \\\\\")\n",
      "note": "Uma aspa dupla ou uma barra invertida dentro de aspas duplas precisa de uma barra na frente, senão a primeira terminaria a string e a segunda começaria um escape."
    },
    {
      "code": "\tfmt.Println(\"euro: \\u20ac, A: \\x41, \\101\")\n",
      "note": "**Um escape pode indicar um caractere pelo número.** `\\u20ac` é o símbolo do euro pelo code point, e `\\x41` e `\\101` são o byte 65, `A`, em hexadecimal e em octal."
    },
    {
      "code": "\tfmt.Println(`tab:\\tend`)\n",
      "note": "Entre crases nada é escape: `\\t` continua sendo uma barra invertida e um `t`."
    },
    {
      "code": "\tfmt.Println(len(\"\\n\"), len(`\\n`))\n}\n",
      "note": "A diferença medida: `\"\\n\"` tem um byte e `` `\\n` `` tem dois."
    }
  ],
  "output": "tab:\tend\nquote: \" backslash: \\\neuro: €, A: A, A\ntab:\\tend\n1 2"
}
```

Os escapes que você mais vai encontrar, todos só dentro de aspas duplas:

| escape | o que ele põe na string |
|---|---|
| `\n`, `\t` | uma quebra de linha, uma tabulação |
| `\"`, `\\` | uma aspa dupla, uma barra invertida |
| `\x41` | um byte, dado em dois dígitos hexadecimais |
| `\101` | um byte, dado em três dígitos octais |
| `\u20ac`, `\U0001F642` | um code point em quatro ou oito dígitos hexadecimais, guardado como seus bytes UTF-8 |

## O que um literal interpretado recusa, e o que não recusa

Um literal interpretado precisa caber numa linha. Uma mensagem de uso digitada em duas linhas
impede o build:

```go
package main

import "fmt"

func main() {
	usage := "usage: greet [-n name]
  -n name   who to greet"
	fmt.Println(usage)
}
```

```
ana@vm:~/strings-newline$ go run .
# example.com/newline
./main.go:6:34: newline in string
./main.go:7:6: syntax error: unexpected name name at end of statement
./main.go:7:26: newline in string
```

A primeira linha é a que importa. As outras duas decorrem dela: como a string terminou cedo, o
parser lê a segunda linha como código e encontra `name` onde um comando não pode tê-lo.

Uma barra invertida seguida de uma letra que não é escape também é recusada. Uma expressão regular
para "um ou mais dígitos" é `\d+`, e entre aspas duplas o `\d` não quer dizer nada:

```go
package main

import "fmt"

func main() {
	pattern := "\d+"
	fmt.Println(pattern)
}
```

```
ana@vm:~/strings-escape$ go run .
# example.com/escape
./main.go:6:15: unknown escape
```

Esses dois falham alto, e esse é o caso bom. O caso ruim é uma barra invertida seguida de uma letra
que **é** um escape. Um caminho do Windows tem barras invertidas, e duas das pastas abaixo começam
com `n` e com `t`:

```go
package main

import "fmt"

func main() {
	path := "C:\new\table"
	fmt.Println(path)
	fmt.Printf("%q\n", path)
	fmt.Println(`C:\new\table`)
}
```

```
ana@vm:~/strings-path$ go vet; echo $?
0
ana@vm:~/strings-path$ go run .
C:
ew	able
"C:\new\table"
C:\new\table
```

**O compilador aceitou o caminho e o `go vet` não achou nada**, porque `\n` e `\t` são escapes
válidos e a string de fato contém uma quebra de linha e uma tabulação. A primeira linha da saída é
a prova, e o `%q`, que põe a string entre aspas do jeito que o código Go a escreveria, mostra os
dois escapes com clareza. A última linha é o mesmo texto como literal bruto, e ela imprime o que foi
digitado.

## Literais brutos: o que você digitou, quebras de linha incluídas

Um literal bruto só termina na próxima crase, então pode ocupar várias linhas, e nada nele é escape.
Isso faz dele a forma certa para texto com barras invertidas ou quebras de linha:

```go
package main

import "fmt"

func main() {
	usage := `usage: greet [-n name]

  -n name   who to greet, default "world"`
	pattern := `\d+\.\d+`
	fmt.Println(usage)
	fmt.Println(pattern, len(pattern))
}
```

```
ana@vm:~/strings-raw$ go run .
usage: greet [-n name]

  -n name   who to greet, default "world"
\d+\.\d+ 8
```

O texto de uso manteve a linha em branco, o recuo de dois espaços e as aspas duplas, sem escape
nenhum. `len(pattern)` dá 8 porque cada barra invertida é um caractere da string, que é o que uma
biblioteca de expressões regulares quer receber. **O único caractere que um literal bruto não
consegue guardar é a crase**, porque ela encerra o literal; uma string que precise de uma é escrita
entre aspas duplas.

Use aspas duplas por padrão, já que a maioria das strings é curta e algumas precisam de um `\n`.
Recorra às crases quando o texto tiver barras invertidas, ocupar várias linhas ou for um bloco de
outra coisa — uma expressão regular, uma consulta SQL, um JSON de exemplo num teste.
