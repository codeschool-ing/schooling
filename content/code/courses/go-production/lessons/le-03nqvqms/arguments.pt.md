---
title: O que um programa recebe
version: 1
---

Um programa iniciado num terminal não recebe a linha que você digitou. **O shell lê a linha antes,
divide em palavras e entrega uma lista ao programa.** As aspas decidem onde uma palavra termina, um
`$NOME` é trocado antes de qualquer coisa começar, e um `*` vira os nomes de arquivo que ele casa.
Quando o `main` roda, tudo isso já aconteceu, e a lista está em `os.Args`.

O pacote flag lê essa lista, pega as palavras que parecem configurações e deixa o resto. A lição 21
do `go-concurrency` o apresentou num programa só. Esta seção olha para a fronteira que ele traça,
porque uma ferramenta de linha de comando vive nessa fronteira: quais palavras são flags, quais são
os argumentos da própria ferramenta, e o que acontece com uma palavra que não é nenhuma das duas.
Um programa que imprime os dois lados, em `~/args`, `main.go`:

```go
// Command args prints what it was given, before and after the flag package
// has read it.
package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	fmt.Printf("os.Args:   %q\n", os.Args)
	verbose := flag.Bool("v", false, "say more")
	n := flag.Int("n", 1, "how many")
	flag.Parse()
	fmt.Printf("flags:     -v=%t -n=%d\n", *verbose, *n)
	fmt.Printf("flag.Args: %q\n", flag.Args())
}
```

Compilado uma vez, e chamado com algumas linhas que diferem em uma coisa cada:

```
ana@vm:~/args$ go build -o args .
ana@vm:~/args$ ./args -v -n 3 jan.log feb.log
os.Args:   ["./args" "-v" "-n" "3" "jan.log" "feb.log"]
flags:     -v=true -n=3
flag.Args: ["jan.log" "feb.log"]
ana@vm:~/args$ ./args -n=3 "two words" feb.log
os.Args:   ["./args" "-n=3" "two words" "feb.log"]
flags:     -v=false -n=3
flag.Args: ["two words" "feb.log"]
```

`os.Args[0]` é o programa como foi chamado, e as palavras vêm em seguida, na ordem. **`flag.Args` é
o que sobra depois de tirar as flags**, e é a parte que uma ferramenta trata como entrada:
nomes de arquivo, quase sempre. `-n 3` e `-n=3` dão no mesmo. As aspas da segunda linha não chegam
ao programa; elas disseram ao shell que `two words` é uma palavra só, e o programa a recebeu
inteira.

## Onde as flags param

O pacote flag lê as flags a partir do começo da lista e **para na primeira palavra que não é
flag**. Tudo depois dela é argumento, mesmo uma palavra com cara de flag:

```
ana@vm:~/args$ ./args --n 3 jan.log -v
os.Args:   ["./args" "--n" "3" "jan.log" "-v"]
flags:     -v=false -n=3
flag.Args: ["jan.log" "-v"]
ana@vm:~/args$ ./args -- -v
os.Args:   ["./args" "--" "-v"]
flags:     -v=false -n=1
flag.Args: ["-v"]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A linha ./args --n 3 jan.log -v vira cinco palavras em os.Args. O pacote flag lê --n e 3 como a flag -n com valor 3 e para em jan.log, a primeira palavra que não é flag, então jan.log e -v ficam em flag.Args e -v continua falso.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que Ana digitou</text><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">$ ./args --n 3 jan.log -v</text><text x=\"40\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que o shell entrega ao programa</text><rect x=\"95\" y=\"112\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"./args\"</text><text x=\"150.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[0]</text><rect x=\"225\" y=\"112\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"--n\"</text><text x=\"265.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[1]</text><rect x=\"325\" y=\"112\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"3\"</text><text x=\"355.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[2]</text><rect x=\"405\" y=\"112\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"jan.log\"</text><text x=\"465.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[3]</text><rect x=\"545\" y=\"112\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"-v\"</text><text x=\"585.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[4]</text><path d=\"M395 92 V250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"403\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a primeira palavra que não é flag: a leitura para aqui</text><path d=\"M225 178 V186 H385 V178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"305\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lidas como flags</text><text x=\"305\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">-n=3   -v=false</text><path d=\"M405 178 V186 H625 V178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">deixadas para o programa</text><text x=\"515\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flag.Args() = [\"jan.log\" \"-v\"]</text><path d=\"M95 178 V186 H205 V178\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"150\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o próprio programa</text></svg>", "caption": "O shell monta a lista; o pacote flag lê as flags a partir do começo e para na primeira palavra que não é flag."}
```

A primeira linha mostra duas coisas. O `--n` funcionou: o Go aceita um traço ou dois para a mesma
flag, e nenhum dos dois é uma "forma longa". E o `-v` depois de `jan.log` não foi lido como flag.
Isso surpreende quem aprendeu as ferramentas GNU, onde `ls dir -l` funciona, e é a primeira
diferença que a lição 2 elimina quando o mesmo programa passa para o Cobra. O `--` sozinho na
segunda linha é o jeito padrão de dizer "daqui em diante, nada de flags", para um argumento que
começa mesmo com traço.

## Quanto custa uma flag errada

Um valor que não converte e um pedido de ajuda terminam o programa antes de o `main` passar do
`flag.Parse`:

```
ana@vm:~/args$ ./args -n three; echo $?
os.Args:   ["./args" "-n" "three"]
invalid value "three" for flag -n: parse error
Usage of ./args:
  -n int
    	how many (default 1)
  -v	say more
2
ana@vm:~/args$ ./args -h; echo $?
os.Args:   ["./args" "-h"]
Usage of ./args:
  -n int
    	how many (default 1)
  -v	say more
0
```

**O pacote imprime o problema e uma listagem de uso, e sai com status 2**, o código convencional
para "você me chamou errado". Quando pedem ajuda, ele imprime a mesma listagem e sai com 0, porque
nada deu errado. A listagem é montada com os textos de ajuda passados a `flag.Int` e `flag.Bool`, e
o padrão aparece quando não é o valor zero. Esse é o comportamento das funções de pacote; a seção
04 monta uma ferramenta em que cada subcomando tem flags próprias e decide sozinho o que significa
uma leitura que falhou.

## Um log para ler

A ferramenta desta lição, o `hits`, lê o log de acesso de um servidor web. Em vez de entregar um
arquivo, o curso dá um programa que escreve um, para você e Ana contarem as mesmas linhas. Ele fica
num módulo novo em `~/hits`, criado com `go mod init example.com/hits`, num diretório próprio
dentro de `tools/`:

```schooling-example
{
  "language": "go",
  "file": "tools/genlog/main.go",
  "parts": [
    {
      "code": "// Command genlog writes a made-up web server access log: the same lines\n// every time for the same flags.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"flag\"\n\t\"fmt\"\n\t\"math/rand/v2\"\n\t\"os\"\n\t\"time\"\n)\n",
      "note": "Um programa num diretório próprio dentro de `tools/`, no mesmo módulo do `hits`. `go run ./tools/genlog` o executa, e ele nunca vai junto com a ferramenta."
    },
    {
      "code": "var (\n\tmethods  = []string{\"GET\", \"GET\", \"GET\", \"POST\"}\n\tpaths    = []string{\"/\", \"/login\", \"/api/orders\", \"/api/orders/42\", \"/api/users\", \"/static/app.js\", \"/static/app.css\", \"/health\"}\n\tstatuses = []int{200, 200, 200, 200, 200, 200, 201, 204, 301, 304, 400, 401, 404, 404, 500, 503}\n)\n",
      "note": "O que uma linha pode conter. **Um valor que aparece duas vezes é sorteado duas vezes mais**: três `GET` contra um `POST`, e seis `200` entre dezesseis status, para o log parecer um site movimentado e não uma distribuição uniforme."
    },
    {
      "code": "func main() {\n\tn := flag.Int(\"n\", 1000, \"how many lines to write\")\n\tseed := flag.Uint64(\"seed\", 1, \"the seed: the same seed writes the same log\")\n\tflag.Parse()\n",
      "note": "Duas flags, lidas como a lição 21 do `go-concurrency` as lia: cada chamada devolve um ponteiro, e o `flag.Parse` o preenche com a linha de comando. O terceiro argumento de cada uma é o texto de ajuda que o `-h` imprime."
    },
    {
      "code": "\tr := rand.New(rand.NewPCG(*seed, *seed))\n\tw := bufio.NewWriter(os.Stdout)\n\tdefer w.Flush()\n",
      "note": "**Um gerador criado a partir de uma semente sorteia os mesmos números em toda execução.** É isso que torna o log reproduzível: as contagens que esta lição imprime são as que você vai obter."
    },
    {
      "code": "\tt := time.Date(2026, 10, 1, 9, 0, 0, 0, time.UTC)\n\tfor range *n {\n\t\tt = t.Add(time.Duration(r.IntN(2000)) * time.Millisecond)\n\t\tfmt.Fprintf(w, \"%s %s %s %d %dms\\n\",\n\t\t\tt.Format(time.RFC3339),\n\t\t\tmethods[r.IntN(len(methods))],\n\t\t\tpaths[r.IntN(len(paths))],\n\t\t\tstatuses[r.IntN(len(statuses))],\n\t\t\t1+r.IntN(400))\n\t}\n}",
      "note": "Cada linha avança o relógio em até dois segundos e escreve cinco campos separados por espaço. O writer com buffer acumula as linhas, e o `defer w.Flush()` grava o que sobrou quando o `main` retorna."
    }
  ]
}
```

Rodado com um punhado de linhas, e depois com outra semente:

```
ana@vm:~/hits$ cat go.mod
module example.com/hits

go 1.27.1
ana@vm:~/hits$ go run ./tools/genlog -n 5
2026-10-01T09:00:01Z POST /api/users 404 115ms
2026-10-01T09:00:03Z GET /static/app.js 200 119ms
2026-10-01T09:00:04Z GET /health 500 3ms
2026-10-01T09:00:06Z GET /api/orders 201 101ms
2026-10-01T09:00:06Z GET /login 500 141ms
ana@vm:~/hits$ go run ./tools/genlog -n 3 -seed 7
2026-10-01T09:00:01Z GET /api/orders/42 503 95ms
2026-10-01T09:00:02Z GET /api/orders 503 226ms
2026-10-01T09:00:03Z GET /api/orders/42 304 281ms
ana@vm:~/hits$ go run ./tools/genlog -n 20000 > access.log; wc -l access.log
20000 access.log
```

Cada linha é um horário em UTC, um método, um caminho, um código de status e quanto tempo a
requisição levou. As suas cinco primeiras linhas devem ser exatamente essas, e **se não forem, o
seu `genlog` difere do que está acima**; todas as contagens desta lição dependem das mesmas 20.000
linhas em `access.log`.
