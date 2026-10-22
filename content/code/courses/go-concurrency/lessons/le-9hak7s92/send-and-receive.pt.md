---
title: Enviar e receber
version: 1
---

A lição 2 deixou uma goroutine sem jeito de devolver o que calculou: o comando `go` joga fora os
valores de retorno. **Um canal é o caminho de volta: um cano tipado em que uma goroutine envia
valores e outra os recebe**, e passar um valor por ele é também a sincronização que a lição 1 seção
04 prometeu. Quem chega a Go costuma imaginar um canal como uma fila com uma API. A propriedade que
o define é outra: ele faz as goroutines das duas pontas esperarem uma pela outra.

Quatro pedaços de sintaxe cobrem tudo:

| | o que faz |
|---|---|
| `ch := make(chan int)` | cria um canal que leva valores `int` |
| `ch <- v` | envia `v`, esperando até um receptor pegá-lo |
| `v := <-ch` | recebe um valor, esperando até um chegar |
| `var ch chan int` | declara um sem criá-lo: o zero value dele é `nil`, e a lição 5 mostra para que isso serve |

A seta sempre aponta o sentido em que o valor viaja. Um canal é uma referência, como um mapa:
passar `ch` a uma função passa o mesmo canal, e não uma cópia dele.

## Dois resultados, um canal

Este programa inicia duas goroutines que somam uma lista cada uma depois de uma demora fingida, e
as duas enviam o total no mesmo canal. Ele aparece em partes, salvo como `hand.go`:

```schooling-example
{"language": "go", "file": "hand.go", "parts": [{"code": "// Command hand sends one result from a goroutine back to main.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\n", "note": "Dois imports: `fmt` para imprimir, `time` para deixar o trabalho lento o bastante para ver."}, {"code": "func sum(numbers []int, out chan int) {\n\ttime.Sleep(200 * time.Millisecond) // pretend this is slow work\n\ttotal := 0\n\tfor _, n := range numbers {\n\t\ttotal += n\n\t}\n\tout <- total\n}\n\n", "note": "**O resultado sai pelo canal, não pelo `return`.** `sum` recebe o canal como parâmetro, e o último ato dela é enviar nele. Até alguém receber, esse envio espera."}, {"code": "func main() {\n\tstart := time.Now()\n\tresults := make(chan int)\n\tgo sum([]int{1, 2, 3, 4}, results)\n\tgo sum([]int{10, 20, 30}, results)\n\n", "note": "Um canal, criado por `make`, compartilhado pelas duas goroutines. Cada uma ganha a sua própria slice para somar."}, {"code": "\ta := <-results\n\tfmt.Println(\"first result:\", a, \"after\", time.Since(start).Round(10*time.Millisecond))\n\tb := <-results\n\tfmt.Println(\"second result:\", b, \"after\", time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "**Cada recebimento espera até um valor chegar.** Dois recebimentos, dois valores, e `main` não passa do segundo até as duas goroutines terem enviado."}]}
```

```
ana@vm:~/channels$ go run hand.go
first result: 60 after 200ms
second result: 10 after 200ms
```

Os dois totais chegaram 200 milissegundos depois do início, e não 200 e depois 400: as duas
goroutines dormiram ao mesmo tempo, e cada envio só esperou `main` estar pronto. **O primeiro
resultado foi 60, da segunda goroutine iniciada.** Qual das duas termina primeiro é assunto do
escalonador, como na lição 1, então `a` é o total que chegou primeiro, e um programa que precisa
saber a que lista um total pertence tem de enviar isso junto. A lição 13 faz exatamente isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O hand.go numa linha do tempo. main inicia duas goroutines e bloqueia no primeiro recebimento. As duas goroutines dormem 200 milissegundos ao mesmo tempo, e depois cada uma envia o seu total. O primeiro recebimento de main pega 60, o segundo pega 10, ambos por volta de 200 milissegundos.\"><defs><marker id=\"l03hand-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03hand-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><text x=\"16\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sum 10, 20, 30</text><text x=\"16\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sum 1, 2, 3, 4</text><rect x=\"150\" y=\"38\" width=\"530\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando em &lt;-results</text><rect x=\"150\" y=\"98\" width=\"470\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dormindo</text><rect x=\"150\" y=\"148\" width=\"470\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dormindo</text><path d=\"M620 110 H635 V65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03hand-amber)\"></path><text x=\"648\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">60</text><path d=\"M620 160 H665 V65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03hand-amber)\"></path><text x=\"678\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">10</text><path d=\"M150 214 H640\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03hand-paper-dim)\"></path><path d=\"M150.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M385.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"385.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><path d=\"M620.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"620.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 ms</text></svg>", "caption": "As duas goroutines dormiram lado a lado, então os dois envios encontraram os recebimentos de main por volta de 200 ms. O primeiro valor a chegar foi 60."}
```

Nada mais foi preciso para fazer `main` esperar. Nenhum `WaitGroup`, nenhuma espera: **um
recebimento não termina até um envio acontecer**, então o valor chegar já é a prova de que a
goroutine foi até ali. E tudo o que `sum` fez antes do envio fica visível para `main` depois do
recebimento, que é a promessa da lição 1 seção 04 que torna seguro compartilhar um valor desse jeito.

Aqui os dois lados se encontraram de igual para igual: quem chegou ao canal primeiro esperou pelo
outro. A lição 4 trata desse encontro, e de dar a um canal espaço para guardar valores, para que quem
envia não precise esperar por quem recebe.
