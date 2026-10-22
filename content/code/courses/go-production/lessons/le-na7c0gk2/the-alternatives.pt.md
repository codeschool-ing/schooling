---
title: Dois outros jeitos de acrescentar um reporter
version: 1
---

Um plugin resolve dois problemas de uma vez: acrescentar um reporter sem mexer no código do
hospedeiro, e acrescentá-lo sem recompilar o hospedeiro. A seção 03 mostrou que a segunda
metade vale pouco: um plugin precisa ser recompilado sempre que um pacote em comum muda, a partir do
mesmo código e com o mesmo toolchain, então hospedeiro e plugins acabam compilados juntos de
qualquer jeito. **As duas alternativas abrem mão de uma metade cada e ficam com a outra.** Um
reporter que é um programa separado fica com "sem recompilar o hospedeiro" e paga com um processo
por chamada. Um reporter compilado dentro do binário fica com "sem mexer no código do hospedeiro" e
paga com uma recompilação.

## Um reporter que é um programa

O sistema de plugins mais antigo do Unix é o pipe. O hospedeiro inicia o reporter como processo
filho, escreve o resumo na entrada padrão dele como JSON e copia o que ele escrever na saída padrão.
**Os dois programas não compartilham memória nem pacotes, só um acordo sobre os bytes.** O reporter
da média, como programa próprio, `exec/mean/main.go`:

```go
// Command mean-exec is the mean-duration reporter as a program of its own.
// It reads one message from standard input and writes its report to
// standard output.
package main

import (
	"encoding/json"
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"example.com/hits/reporters/mean"
)

type message struct {
	Protocol int           `json:"protocol"`
	Summary  tally.Summary `json:"summary"`
}

func main() {
	var m message
	if err := json.NewDecoder(os.Stdin).Decode(&m); err != nil {
		fmt.Fprintln(os.Stderr, "mean-exec:", err)
		os.Exit(1)
	}
	if m.Protocol != 1 {
		fmt.Fprintf(os.Stderr, "mean-exec: protocol %d, and this reporter speaks 1\n", m.Protocol)
		os.Exit(1)
	}
	if err := (mean.Reporter{}).Report(m.Summary, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "mean-exec:", err)
		os.Exit(1)
	}
}
```

Ele reaproveita o `reporters/mean` porque é escrito em Go e mora no mesmo módulo, mas nada exige
nenhuma das duas coisas. Um reporter em Python lê a mesma mensagem, `exec/top.py`:

```python
#!/usr/bin/env python3
# A reporter in another language: the busiest path, from the same message.
import json, sys

msg = json.load(sys.stdin)
if msg["protocol"] != 1:
    sys.exit(f"top.py: protocol {msg['protocol']}, and this reporter speaks 1")
paths = msg["summary"]["ByPath"]
if not paths:
    print("busiest path: none, the log is empty")
else:
    busiest = min(paths, key=lambda p: (-paths[p], p))
    print(f"busiest path: {busiest} ({paths[busiest]} requests)")
```

E o hospedeiro que os roda, `cmd/hits-exec/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/hits-exec/main.go",
  "parts": [
    {
      "code": "// Command hits-exec counts a log and hands the summary to reporters that\n// are programs of their own, one process per reporter.\npackage main\n\nimport (\n\t\"bytes\"\n\t\"encoding/json\"\n\t\"fmt\"\n\t\"os\"\n\t\"os/exec\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Nenhum import de `plugin` e nenhum cgo: o `os/exec` inicia programas, e isso funciona em toda plataforma para a qual o Go compila."
    },
    {
      "code": "// message is the protocol: one JSON object on the reporter's standard\n// input. A reporter that does not know the number refuses.\ntype message struct {\n\tProtocol int           `json:\"protocol\"`\n\tSummary  tally.Summary `json:\"summary\"`\n}\n",
      "note": "**O protocolo é esta struct, e o número dentro dela é a versão.** Um reporter é qualquer coisa que leia uma destas e escreva texto. Quando a mensagem precisar mudar, o número sobe, e um reporter antigo a recusa com palavras em vez de interpretá-la errado."
    },
    {
      "code": "func main() {\n\tif len(os.Args) < 3 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: hits-exec <log> <program>...\")\n\t\tos.Exit(2)\n\t}\n\tf, err := os.Open(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}\n\ts, err := tally.Count(f)\n\tf.Close()\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}\n\tin, err := json.Marshal(message{Protocol: 1, Summary: s})\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}",
      "note": "A contagem é a da lição 1. O resumo é codificado uma vez, porque todo reporter recebe os mesmos bytes."
    },
    {
      "code": "\tcode := 0\n\tfor _, program := range os.Args[2:] {\n\t\tcmd := exec.Command(program)\n\t\tcmd.Stdin = bytes.NewReader(in)\n\t\tcmd.Stdout = os.Stdout\n\t\tcmd.Stderr = os.Stderr\n\t\tif err := cmd.Run(); err != nil {\n\t\t\tfmt.Fprintf(os.Stderr, \"hits-exec: %s: %v\\n\", program, err)\n\t\t\tcode = 1\n\t\t}\n\t}\n\tos.Exit(code)\n}",
      "note": "**Um processo por reporter, iniciado, alimentado e esperado.** A saída padrão e a saída de erro do reporter são as do hospedeiro, então o relatório cai no mesmo lugar em que cairia o de um reporter compilado dentro. Um reporter que falha custa o próprio relatório e um código de saída 1; o laço segue para o próximo."
    }
  ]
}
```

O arquivo Python precisa ser executável, já que o `exec.Command` o roda como programa:

```
ana@vm:~/plugins$ chmod +x exec/top.py
ana@vm:~/plugins$ go build -o mean-exec ./exec/mean && go build -o hits-exec ./cmd/hits-exec
ana@vm:~/plugins$ ./hits-exec access.log ./mean-exec exec/top.py
20000 requests, mean 200ms
busiest path: /login (2576 requests)
```

**Dois reporters em duas linguagens, compilados em momentos diferentes, e nenhum foi compilado
contra o `hits-exec`.** O `mean-exec` poderia ser recompilado amanhã com Go 1.27.2 ou com `-race`
e nada da seção 03 aconteceria, porque nenhum pacote é compartilhado em tempo de execução. O que
eles compartilham é a mensagem, e a mensagem leva a versão, então um desencontro vira uma frase em
vez de uma falha no fundo do runtime:

```
ana@vm:~/plugins$ echo '{"protocol":2}' | ./mean-exec; echo $?
mean-exec: protocol 2, and this reporter speaks 1
1
```

## Uma falha fica do lado de fora

O `mean` divide pelo número de linhas e nunca recebeu um log vazio. Os dois hospedeiros recebem um.
`GOTRACEBACK=none` mantém a primeira linha do pânico e descarta as pilhas das goroutines, cujos
endereços mudam a cada execução; o processo filho herda a variável:

```
ana@vm:~/plugins$ touch empty.log
ana@vm:~/plugins$ GOTRACEBACK=none ./hits-plugin empty.log csv.so mean.so; echo $?
status,requests
panic: runtime error: integer divide by zero
2
ana@vm:~/plugins$ GOTRACEBACK=none ./hits-exec empty.log ./mean-exec exec/top.py; echo $?
panic: runtime error: integer divide by zero
hits-exec: ./mean-exec: exit status 2
busiest path: none, the log is empty
1
```

O mesmo bug, dois desfechos. **No `hits-plugin` o pânico é um pânico do hospedeiro.** O reporter de
CSV tinha escrito o relatório, que para um log vazio é só o cabeçalho. Depois o processo inteiro
morreu com status de saída 2, e a linha do registro nunca veio. No `hits-exec` o pânico matou o
`mean-exec`, o hospedeiro informou `exit status 2` para aquele reporter, rodou o de Python e saiu
com 1. Um reporter que vaza memória, prende uma CPU ou chama `os.Exit` fica contido do mesmo jeito,
e o sistema operacional pode limitar a memória e o tempo dele de formas que não consegue aplicar a
uma biblioteca dentro do seu processo.

**O custo é iniciar um processo a cada chamada**, que a seção 05 mede, e um protocolo que agora é
uma interface pública que você versiona à mão. A biblioteca `go-plugin` da HashiCorp é esse desenho
generalizado: ela inicia cada plugin uma vez, o mantém rodando e o chama por RPC, então o início do
processo é pago uma vez em vez de a cada chamada. Os providers do Terraform funcionam assim. Outra
rota da mesma família é o WebAssembly. Um reporter é compilado para um módulo `.wasm` e rodado dentro
do hospedeiro por um runtime escrito em Go puro, como o `wazero`, que não precisa de cgo e confina o
módulo à memória que recebe. Nenhum dos dois é usado neste curso; os dois respondem à pergunta desta
seção com outra tabela de preços.

## Um reporter compilado dentro

O terceiro jeito é o que a biblioteca padrão usa. O `database/sql` não conhece banco nenhum, e o
`image.Decode` não conhece formato nenhum: um driver ou um codec se registra no `init`, e um
programa escolhe quais contém importando-os. `import _ "image/png"` é um import só pelo efeito
colateral, e o efeito colateral é `image.RegisterFormat("png", …)`. O `report` já tem o registro e
os dois reporters já se registram, então o hospedeiro é uma lista de imports.
`cmd/hits-static/main.go`:

```go
// Command hits-static counts a log and writes it out with a reporter
// compiled into the binary, chosen by name.
package main

import (
	"flag"
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"example.com/hits/report"

	_ "example.com/hits/reporters/csv"
	_ "example.com/hits/reporters/mean"
)

func main() {
	name := flag.String("r", "csv", "the reporter to use")
	flag.Parse()
	r, ok := report.Get(*name)
	if !ok {
		fmt.Fprintf(os.Stderr, "hits-static: no reporter %q; have %v\n", *name, report.Names())
		os.Exit(2)
	}
	s, err := tally.Count(os.Stdin)
	if err == nil {
		err = r.Report(s, os.Stdout)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "hits-static:", err)
		os.Exit(1)
	}
}
```

```
ana@vm:~/plugins$ go build -o hits-static ./cmd/hits-static
ana@vm:~/plugins$ ./hits-static -r mean < access.log
20000 requests, mean 200ms
ana@vm:~/plugins$ ./hits-static < access.log | head -3
status,requests
200,7554
201,1256
ana@vm:~/plugins$ ./hits-static -r xml < access.log; echo $?
hits-static: no reporter "xml"; have [csv mean]
2
```

**Os imports em branco são o sistema de plugins inteiro**: as mesmas funções `init` que rodaram
dentro do `plugin.Open` na seção 02 rodam aqui na inicialização, a partir de pacotes que o ligador
pôs no binário. Acrescentar um reporter é uma linha de import e uma recompilação. Essa recompilação
é o preço, e a seção 03 mostrou que os plugins também o cobram, de forma menos útil. O
`go doc plugin` termina a lista de avisos com o mesmo conselho. Se a aplicação e seus plugins são
compilados juntos de qualquer forma, pode ser mais simples gerar um arquivo Go que importe em branco
os plugins escolhidos e compilar um único executável estático. Uma equipe que queira a lista fora do
código pode gerar esse arquivo com `go generate`, o assunto da lição 10.
