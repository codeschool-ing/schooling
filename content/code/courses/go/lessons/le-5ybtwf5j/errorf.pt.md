---
title: fmt.Errorf, contexto e o verbo que embrulha
version: 1
---

O `fmt.Errorf` é um `Printf` que devolve um `error` em vez de imprimir: a mesma string de formato,
os mesmos verbos, e o resultado é um erro cuja mensagem é o texto formatado. A seção 04 o usa para
`age -4 is negative`, uma mensagem com um valor dentro. O trabalho maior dele é o assunto desta
seção: **acrescentar contexto a um erro no caminho para cima**.

A lição 32 repassava os erros do jeito que chegavam, e para uma chamada isso basta. Num programa de
qualquer tamanho, não. O `os.ReadFile` informa `open settings.json: no such file or directory` e
mais nada, porque não tem como saber quem pediu: se o servidor estava subindo, se um teste
carregava um arquivo de exemplo ou se um usuário tinha digitado o nome. **Cada função que devolve
um erro sabe uma coisa que o erro não sabe, o que ela estava fazendo**, e acrescenta isso antes de
devolver.

## %v e %w: o mesmo texto, dois valores diferentes

Há dois verbos para pôr um erro dentro de uma mensagem nova. O `%v` é o verbo que o `Printf` já usa
para qualquer valor. O `%w` só existe no `fmt.Errorf`. Em `~/wrap-verbs`, as mesmas palavras
acrescentadas dos dois jeitos:

```go
// Command verbs adds the same words to an error with %v and with %w.
package main

import (
	"fmt"
	"os"
)

func main() {
	_, err := os.ReadFile("settings.json")
	v := fmt.Errorf("read config: %v", err)
	w := fmt.Errorf("read config: %w", err)
	fmt.Println(v)
	fmt.Println(w)
	fmt.Printf("%T\n%T\n", v, w)
}
```

```
ana@vm:~/wrap-verbs$ go run .
read config: open settings.json: no such file or directory
read config: open settings.json: no such file or directory
*errors.errorString
*fmt.wrapError
```

As duas mensagens são idênticas byte a byte; os dois tipos, não. Com `%v`, o `fmt.Errorf`
transformou tudo em texto e devolveu o `*errors.errorString` da seção 02, a mesma coisa que o
`errors.New` teria montado com aquele texto. Com `%w` ele devolveu um `*fmt.wrapError`. O
código-fonte do `fmt.Errorf` diz qual é a diferença:

```
ana@vm:~/wrap-verbs$ sed -n '44,50p;70,73p' /usr/local/go/src/fmt/errors.go
	switch len(p.wrappedErrs) {
	case 0:
		err = errors.New(s)
	case 1:
		w := &wrapError{msg: s}
		w.err, _ = a[p.wrappedErrs[0]].(error)
		err = w
type wrapError struct {
	msg string
	err error
}
```

Sem `%w` no formato, `case 0`, e o resultado é o `errors.New` do texto. Com um `%w`, `case 1`, e o
resultado é uma struct com dois campos: a mensagem e `err`, **o erro original, guardado inteiro
dentro do novo**. É isso que embrulhar quer dizer. O `%v` copia as palavras do erro antigo e
descarta o erro; o `%w` copia as palavras e guarda o erro. Um código que queira olhar dentro de um
erro embrulhado, para perguntar se faltava um arquivo ou qual caminho falhou, alcança o
`*fs.PathError` em `w` e não tem nada a alcançar em `v`. A lição 34 faz esse alcance.

## Três camadas, uma mensagem

Um programa de verdade embrulha em cada camada que tem algo a acrescentar. `~/wrap-context` é um
servidor que não encontra a própria configuração:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command server fails to start, and says why.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n)\n\nfunc readConfig(path string) ([]byte, error) {\n\tdata, err := os.ReadFile(path)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"read config: %w\", err)\n\t}\n\treturn data, nil\n}\n",
      "note": "**A camada mais baixa diz o que estava fazendo quando a chamada falhou**, `read config`, e embrulha o erro que o `os.ReadFile` devolveu. Ela não repete o nome do arquivo: o `*fs.PathError` por baixo já o carrega."
    },
    {
      "code": "\nfunc start() error {\n\tif _, err := readConfig(\"settings.json\"); err != nil {\n\t\treturn fmt.Errorf(\"start server: %w\", err)\n\t}\n\treturn nil\n}\n",
      "note": "**A camada de cima faz o mesmo com o próprio passo**, `start server`. Ela não sabe nada de arquivos; sabe que estava iniciando um servidor e que ler a configuração fazia parte disso. O `if` com inicializador é o da lição 19."
    },
    {
      "code": "\nfunc main() {\n\tif err := start(); err != nil {\n\t\tfmt.Println(err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "O `main` não acrescenta nada e imprime o que chegou. Ele é o topo do programa, o único lugar que relata em vez de devolver."
    }
  ]
}
```

```
ana@vm:~/wrap-context$ go run .
start server: read config: open settings.json: no such file or directory
exit status 1
```

`exit status 1` é o `go run` relatando o status de saída do próprio programa, o `os.Exit(1)` do
`main`. A linha acima é uma mensagem só, e três funções a escreveram:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"A mensagem start server: read config: open settings.json: no such file or directory, dividida nas três partes que três funções escreveram. O os.ReadFile escreveu primeiro a última parte: open settings.json: no such file or directory. Depois readConfig pôs read config: na frente dela, e start pôs start server: na frente disso. Escrita da causa para fora, a mensagem é lida da esquerda para a direita: o que o programa fazia, depois o que isso exigia, depois por que falhou.\"><defs><marker id=\"ml-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ml-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"119\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">start server: </text><path d=\"M119 62 L119 68 L204.8 68 L204.8 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M161.9 34 L161.9 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"161.9\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. start acrescenta</text><text x=\"211.39999999999998\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">read config: </text><path d=\"M211.39999999999998 62 L211.39999999999998 68 L290.59999999999997 68 L290.59999999999997 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250.99999999999997\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. readConfig acrescenta</text><text x=\"297.2\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open settings.json: no such file or directory</text><path d=\"M297.2 62 L297.2 68 L594.2 68 L594.2 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"445.7\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1. os.ReadFile escreve</text><path d=\"M588.2 114 L125 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ml-wire)\"></path><text x=\"356.6\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escrita da causa para fora</text><path d=\"M125 154 L588.2 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ml-phosphor)\"></path><text x=\"356.6\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lida da esquerda para a direita: o que o programa fazia, até o motivo da falha</text></svg>", "caption": "Uma mensagem, escrita por três funções. Cada camada põe as próprias palavras na frente do erro que recebeu, então a causa fica por último e a mensagem se lê de fora para dentro."}
```

Cada camada escreveu suas palavras na frente do erro que recebeu, então a causa, escrita primeiro,
fica por último. **Uma mensagem embrulhada se lê da esquerda para a direita, do que o programa
fazia até o motivo da falha**, e cada dois-pontos é um passo mais fundo. Ninguém precisou planejar
a frase; ela saiu de cada função dizendo uma coisa.

## Minúscula, sem ponto final, sem "falhou"

Isso só funciona se cada camada escrever um fragmento que caiba no meio de uma frase. Aqui está
`~/wrap-style`, o mesmo programa com as duas chamadas escritas como frases completas:
`"Error: could not read config: %w."` em `readConfig` e `"Failed to start server: %w."` em `start`.

```
ana@vm:~/wrap-style$ go run .
Failed to start server: Error: could not read config: open settings.json: no such file or directory..
exit status 1
```

Uma letra maiúscula no meio da linha, `Error:` dizendo o que todo mundo já sabia, e dois pontos
finais no fim, onde duas camadas fecharam cada uma a sua frase. As convenções que evitam isso são
as que a biblioteca padrão segue: **uma mensagem começa com letra minúscula, termina sem pontuação
e diz o que estava sendo feito, e não que falhou.** Contando as chamadas a `errors.New` em
`/usr/local/go/src`, sem os testes:

```
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("' /usr/local/go/src | grep -vc -e _test.go -e testdata
2095
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("[A-Z]' /usr/local/go/src | grep -vc -e _test.go -e testdata
81
ana@vm:~/wrap$ grep -rE --include=*.go 'errors\.New\("[^"]*\."\)' /usr/local/go/src | grep -vc -e _test.go -e testdata
2
```

Das 2.095 mensagens, 81 começam com maiúscula, e quase todas essas começam com o nome de um tipo,
de uma função ou com uma sigla, `Time`, `Rat`, `P256`, `JSON`, que mantém a maiúscula onde quer
que esteja. Duas terminam com ponto final.

## O %w quer um erro

O `%w` recebe um erro e mais nada. Se receber uma string, o `fmt.Errorf` não recusa; ele imprime a
reclamação dentro da mensagem, como o `Printf` fez com o verbo errado na lição 4:

```go
package main

import "fmt"

func main() {
	reason := "disk full"
	err := fmt.Errorf("save notes: %w", reason)
	fmt.Println(err)
}
```

```
ana@vm:~/wrap-vet$ go run .
save notes: %!w(string=disk full)
ana@vm:~/wrap-vet$ go vet
main.go:7:33: fmt.Errorf format %w has arg reason of wrong type string
```

O compilador aceita, porque para ele o formato é uma string. O `go vet` lê o formato e os
argumentos juntos e pega o engano, o que é mais um motivo para rodá-lo antes que alguém leia o
código.
