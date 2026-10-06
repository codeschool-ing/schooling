---
title: Closures: uma função que guarda uma variável
version: 1
---

Uma função literal pode usar as variáveis à sua volta, e essa é a ideia inteira de uma
**closure**. A imagem comum é a de que a função tira uma foto desses valores quando é criada. **Não
tira: uma closure se agarra às próprias variáveis**, e as mantém vivas enquanto o valor de função
existir, mesmo depois que a função que as declarou já retornou.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc counter() func() int {\n\tn := 0\n\treturn func() int {\n\t\tn++\n\t\treturn n\n\t}\n}\n",
      "note": "**`counter` devolve uma função, e essa função usa `n`, uma variável local de `counter`.** `counter` já retornou quando alguém chama o resultado, e `n` continua lá, porque a closure se refere a ela."
    },
    {
      "code": "\nfunc main() {\n\tnext := counter()\n\tfmt.Println(next(), next(), next())\n",
      "note": "Cada chamada a `next` soma um ao mesmo `n` e o devolve: 1, 2, 3. A contagem vive entre as chamadas, sem variável global."
    },
    {
      "code": "\n\tother := counter()\n\tfmt.Println(other(), next())\n",
      "note": "Uma segunda chamada a `counter` executa `n := 0` de novo e cria um segundo `n`. `other` começa em 1 enquanto `next` segue para 4: **cada chamada da função de fora cria variáveis novas para as suas closures guardarem.**"
    },
    {
      "code": "\n\tx := 1\n\tshow := func() { fmt.Println(\"x is\", x) }\n\tx = 2\n\tshow()\n}\n",
      "note": "A imagem da foto, posta à prova. `show` foi criada quando `x` valia 1 e chamada depois que virou 2, e imprime 2, porque o que ela guarda é `x`, não o 1."
    }
  ],
  "output": "1 2 3\n1 4\nx is 2"
}
```

Onde essas variáveis moram, quando uma função já retornou e a closure dela não, é uma questão de
memória. A lição 24 responde com a regra que o compilador segue, a análise de escape: uma variável
que pode sobreviver à sua função, como `n` sobrevive a `counter`, fica no heap.

## Duas closures, uma variável

Como uma closure guarda a variável e não uma cópia, duas closures criadas na mesma chamada
compartilham aquilo a que se referem. Esta função devolve duas, usando os resultados nomeados da
lição 20:

```go
package main

import "fmt"

func account() (deposit func(int), balance func() int) {
	total := 0
	deposit = func(amount int) {
		total += amount
	}
	balance = func() int {
		return total
	}
	return
}

func main() {
	deposit, balance := account()
	deposit(50)
	deposit(25)
	fmt.Println(balance())
}
```

```
ana@vm:~/closures-account$ go run .
75
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas closures devolvidas por uma chamada a account. A closure deposit, func(amount int) { total += amount }, escreve na variável total. A closure balance, func() int { return total }, lê a mesma variável. Existe um só total, que guarda 75 depois dos depósitos de 50 e 25, e as duas funções apontam para ele.\"><defs><marker id=\"cla-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"cla-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"270\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">deposit</text><text x=\"165\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func(amount int) {</text><text x=\"165\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total += amount }</text><rect x=\"420\" y=\"30\" width=\"270\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">balance</text><text x=\"555\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func() int {</text><text x=\"555\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">return total }</text><rect x=\"285\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">75</text><path d=\"M165 100 L290 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cla-phosphor)\"></path><path d=\"M555 100 L430 165\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cla-phosphor-dim)\"></path><text x=\"195\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escreve nela</text><text x=\"525\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê dela</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma variável, criada por uma chamada a account</text></svg>", "caption": "deposit e balance capturam a mesma variável. Um depósito aparece em balance porque só existe um total.", "same": ["deposit", "balance"]}
```

`deposit` altera `total` e `balance` o lê, e nada mais no programa alcança essa variável. **A
variável é privada das duas funções que a capturam**, e é isso que torna as closures úteis: estado
com uma porta estreita, sem declarar um tipo para ele. A lição 25 faz o mesmo serviço com uma
struct e métodos, que é a escolha usual quando há mais de duas operações.

## A variável do loop, e por que o `x := x` sumiu

Uma closure criada dentro de um loop captura a variável do loop, e o que essa variável é mudou no
Go 1.22. A lição 2 rodou um programa como este sob duas linhas `go` para mostrar que a linha `go`
escolhe o comportamento. Eis por que as respostas diferem:

```go
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
```

```
ana@vm:~/closures-loop$ go mod edit -go=1.21 && go vet && go run .
hello, caio
hello, caio
hello, caio
ana@vm:~/closures-loop$ go mod edit -go=1.22 && go run .
hello, ana
hello, bia
hello, caio
```

Sob `go 1.21` o loop declara **uma** `name` e atribui um valor novo a ela a cada volta. As três
closures guardam essa mesma variável, e quando são chamadas ela vale `"caio"`. É a figura de duas
closures e uma variável acima, com três closures, e o `go vet` não diz nada a respeito. Sob `go
1.22` em diante, **cada volta do loop declara uma `name` nova**, então cada closure guarda uma
variável só dela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O loop de closures-loop sob duas linhas go. Com go 1.21, as três closures apontam para uma só variável name, que guarda caio quando elas são chamadas, então cada uma imprime hello, caio. Com go 1.22, cada closure aponta para a sua própria variável name, com ana, bia e caio.\"><defs><marker id=\"cll-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"cll-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">go 1.21</text><text x=\"545\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">go 1.22</text><path d=\"M360 10 L360 240\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"130\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"240\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"115\" y=\"160\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"175\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">name</text><text x=\"175\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;caio&quot;</text><path d=\"M65 74 L131.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><path d=\"M175 74 L175.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><path d=\"M285 74 L219.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><text x=\"175\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma variável para o loop inteiro</text><rect x=\"390\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"390\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"435\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"435\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;ana&quot;</text><path d=\"M435 74 L435 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><rect x=\"500\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"500\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"545\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"545\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;bia&quot;</text><path d=\"M545 74 L545 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><rect x=\"610\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"610\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"655\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"655\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;caio&quot;</text><path d=\"M655 74 L655 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><text x=\"545\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma variável nova a cada volta</text></svg>", "caption": "O que cada closure capturou. Sob go 1.21 o loop tem um só name e as closures o compartilham; sob go 1.22 cada volta declara o seu."}
```

Antes do 1.22 a correção era uma linha que parece não fazer nada, `name := name`, o `x := x` da
lição 6. Ela declara uma variável nova dentro do corpo do loop, uma por volta, e a inicia como
cópia da variável do loop, então cada closure captura uma diferente:

```go
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		name := name
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
```

```
ana@vm:~/closures-loopcopy$ go mod edit -go=1.21 && go run .
hello, ana
hello, bia
hello, caio
ana@vm:~/closures-loopcopy$ grep -n 'is122 :=' /usr/local/go/src/cmd/compile/internal/noder/writer.go
1643:	is122 := fileVersion == "" || version.Compare(fileVersion, "go1.22") >= 0
```

**A partir do Go 1.22 o loop faz o que `name := name` fazia, então a cópia deixou de ser
necessária.** A linha do próprio código-fonte do compilador é onde a decisão é tomada: um arquivo
cuja versão é `go1.22` ou mais nova ganha uma variável por volta. Aqui a versão vem da linha `go`
do módulo, e é por isso que o mesmo compilador deu duas respostas acima. Você ainda vai encontrar
`name := name` em código escrito antes de 2024 e em módulos que nunca mudaram a linha `go`, e agora
sabe para que servia. Num módulo em 1.22 ou posterior ela é inofensiva e pode sair.
