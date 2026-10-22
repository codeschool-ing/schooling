---
title: Timers e tickers
version: 1
---

`time.Sleep` para a goroutine que o chama, e nada mais acontece nela até que acorde. **Um timer é
uma espera transformada em canal**: ele entrega um valor depois de uma duração, então uma goroutine
pode esperá-lo dentro de um `select` ao lado de outras coisas, como a lição 5 fez com `time.After`.
Um ticker entrega um valor de novo e de novo. Os dois são valores que você guarda, então os dois
podem ser parados, e essa é a diferença para o `time.After`.

Salvo como `timer.go`:

```schooling-example
{"language": "go", "file": "timer.go", "parts": [{"code": "// Command timer starts timers, stops one, and lets a ticker run.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\nfunc main() {\n\tstart := time.Now()\n\tsince := func() time.Duration { return time.Since(start).Round(10 * time.Millisecond) }\n\n", "note": "`since` informa a que altura da execução cada linha foi impressa, arredondando para dez milissegundos para que os pequenos atrasos do escalonador não poluam a saída."}, {"code": "\tt := time.NewTimer(300 * time.Millisecond)\n\t<-t.C\n\tfmt.Println(\"timer fired at\", since())\n\n", "note": "**O canal de um timer é `t.C`.** Receber dele espera até a duração passar e então recebe a hora em que ele disparou. Aqui o recebimento está sozinho, então isto é uma espera escrita do jeito longo."}, {"code": "\tlate := time.NewTimer(time.Hour)\n\tfmt.Println(\"stopped before firing:\", late.Stop())\n\n", "note": "`Stop` cancela um timer que ainda não disparou e diz se fez alguma coisa. `true` significa que a hora nunca será entregue."}, {"code": "\ttime.AfterFunc(100*time.Millisecond, func() { fmt.Println(\"AfterFunc ran at\", since()) })\n\n", "note": "**`AfterFunc` não tem canal: ele roda a função numa goroutine própria** quando chega a hora. `main` não espera por ela; quando a função dispara, `main` ainda está rodando o ticker abaixo."}, {"code": "\ttick := time.NewTicker(200 * time.Millisecond)\n\tfor range 3 {\n\t\t<-tick.C\n\t\tfmt.Println(\"tick at\", since())\n\t}\n\ttick.Stop()\n}\n", "note": "Um ticker dispara a cada 200 milissegundos até ser parado. O `Stop` depois do laço encerra os ticks; um ticker que ninguém para continua disparando enquanto o programa rodar."}]}
```

```
ana@vm:~/clock$ go run timer.go
timer fired at 300ms
stopped before firing: true
AfterFunc ran at 400ms
tick at 500ms
tick at 700ms
tick at 900ms
```

O timer disparou em 300 milissegundos. O `AfterFunc` foi armado naquele momento para mais cem e
rodou em 400, na sua própria goroutine, entre o início do ticker e o primeiro tick. Os ticks vieram
em 500, 700 e 900, com duzentos de distância, contados de quando o ticker foi criado.

## O que mudou no Go 1.23

Código antigo está cheio de um ritual: `defer t.Stop()` logo depois de todo `NewTimer`, e um
esvaziamento de `t.C` antes de todo `Reset`. **Os dois eram necessários antes do Go 1.23 e nenhum
é agora**, e `go doc time.NewTimer` diz isso com todas as letras. Um timer a que ninguém se refere
mais é recolhido pelo coletor de lixo mesmo que nunca tenha disparado. E o canal de um timer não
guarda mais um valor velho, então, depois que `Stop` ou `Reset` retorna, um recebimento não pega
uma hora da configuração antiga. `Stop` continua sendo o jeito de cancelar um timer que você não
quer; só deixou de ser o jeito de evitar um vazamento.

Isso vale porque o `go.mod` do módulo diz `go 1.23` ou posterior, como diz todo módulo criado com o
Go 1.27.1. Um módulo que declara uma versão mais velha mantém o comportamento antigo, então o
ritual que você encontrar num projeto antigo ainda pode estar fazendo o seu trabalho lá.

## Um ticker lido com atraso descarta ticks

Um ticker não enfileira os seus ticks para quem lê devagar. **Um tick espera para ser lido, e todo
tick que dispara enquanto ele espera é descartado.** Aqui quem lê dorme 250 milissegundos depois de
cada tick de um ticker de 100 milissegundos, salvo como `slow.go`:

```go
// Command slow reads a ticker more slowly than it ticks.
package main

import (
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	tick := time.NewTicker(100 * time.Millisecond)
	defer tick.Stop()
	for range 4 {
		at := <-tick.C
		fmt.Println("tick stamped", at.Sub(start).Round(10*time.Millisecond),
			"read at", time.Since(start).Round(10*time.Millisecond))
		time.Sleep(250 * time.Millisecond)
	}
}
```

```
ana@vm:~/clock$ go run slow.go
tick stamped 100ms read at 120ms
tick stamped 200ms read at 370ms
tick stamped 400ms read at 620ms
tick stamped 700ms read at 870ms
```

Cada valor traz a hora em que foi carimbado, e os carimbos são 100, 200, 400 e 700. Os ticks de
300, 500 e 600 nunca foram entregues. O tick carimbado em 400 foi lido em 620, então esperou 220
milissegundos enquanto dois ticks mais novos vinham e iam. **Quem lê nunca recebe uma rajada de
ticks velhos para pôr em dia**: por mais atrasado que esteja, encontra um tick esperando e nenhum
outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um ticker dispara a cada 100 milissegundos, em 100, 200 e assim por diante até 800. Quem lê pega os ticks carimbados em 100, 200, 400 e 700, lendo-os em 120, 370, 620 e 870 milissegundos. Os ticks de 300, 500, 600 e 800 são descartados, porque cada um disparou enquanto um tick mais velho ainda esperava para ser lido.\"><defs><marker id=\"l20ticks-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o ticker dispara</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem lê recebe</text><path d=\"M150.0 60 H690.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 150 H690.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M210.0 71 L222.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"215.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"261.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M270.0 71 L372.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"365.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"321.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"381.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M390.0 71 L522.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"515.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"441.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"501.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"561.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M570.0 71 L672.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"665.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"621.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M150.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M210.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M270.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"270.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M330.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M390.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"390.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M450.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"450.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><path d=\"M510.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M570.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"570.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">700</text><path d=\"M630.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">800</text><path d=\"M690.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900</text><path d=\"M150.0 190 H690.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">milissegundos desde o início</text><rect x=\"470\" y=\"16\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entregue</text><rect x=\"580\" y=\"16\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"600\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">descartado</text></svg>", "caption": "O slow.go: um tick espera para ser lido, e os ticks que disparam enquanto isso são descartados."}
```

É o comportamento certo para o trabalho de um ticker, que é "faça isto de tempos em tempos". Um
programa que precisa contar todo evento, uma taxa de requisições por exemplo, tem de contá-los de
outro jeito que não pelos ticks recebidos.
