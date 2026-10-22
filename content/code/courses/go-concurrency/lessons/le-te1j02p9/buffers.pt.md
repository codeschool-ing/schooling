---
title: Um buffer, e o que ele muda
version: 1
---

`make(chan T, n)` dá ao canal espaço para `n` valores. **Um envio num canal com buffer termina assim
que há espaço, sem esperar quem recebe; ele só bloqueia quando o buffer está cheio.** Um recebimento
pega o valor mais antigo, e só bloqueia quando o buffer está vazio. Duas funções embutidas informam o
estado: `cap(ch)` é o espaço, `len(ch)` quanto dele está em uso.

O mesmo receptor atrasado da seção 02, mas agora o canal guarda três, e quem envia tem cinco valores
para enviar, salvo como `buffered.go`:

```go
// Command buffered sends five values into a channel with room for three.
package main

import (
	"fmt"
	"time"
)

var start = time.Now()

func stamp(format string, args ...any) {
	ms := time.Since(start).Round(10 * time.Millisecond).Milliseconds()
	fmt.Printf("%4dms  "+format+"\n", append([]any{ms}, args...)...)
}

func main() {
	ch := make(chan int, 3)
	done := make(chan struct{})

	go func() {
		for i := 1; i <= 5; i++ {
			ch <- i
			stamp("sent %d, len %d of cap %d", i, len(ch), cap(ch))
		}
		close(ch)
		close(done)
	}()

	time.Sleep(300 * time.Millisecond)
	for v := range ch {
		stamp("received %d", v)
		time.Sleep(100 * time.Millisecond)
	}
	<-done
}
```

```
ana@vm:~/buffers$ go run buffered.go
   0ms  sent 1, len 1 of cap 3
   0ms  sent 2, len 2 of cap 3
   0ms  sent 3, len 3 of cap 3
 300ms  received 1
 300ms  sent 4, len 3 of cap 3
 400ms  received 2
 400ms  sent 5, len 3 of cap 3
 500ms  received 3
 600ms  received 4
 700ms  received 5
```

**Os três primeiros envios retornaram em 0 milissegundo**, com `len` subindo até 3: o buffer os pegou
e ninguém precisou estar lá. O quarto teve de esperar. Ele retornou em 300, no momento em que quem
recebe pegou o `1` e liberou uma posição, e `len` voltou a 3 porque o `4` ocupou a posição na hora.
Dali em diante quem envia e quem recebe andaram no mesmo passo, um valor a cada 100 milissegundos,
porque quem recebe dorme 100 entre um recebimento e outro e cada envio esperou a posição que ele
liberava. Depois do close, quem recebe ainda pegou `3`, `4` e `5`, os valores que o buffer guardava.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois canais comparados. Sem buffer: o canal não tem espaço, então quem envia espera de 0 a 300 milissegundos até quem recebe chegar, e o valor passa direto de um para o outro. Com buffer para três: quem envia põe 1, 2 e 3 no buffer de uma vez e só espera no quarto, quando o buffer está cheio; quem recebe tira valores da frente.\"><defs><marker id=\"l04meet-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04meet-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sem buffer: make(chan string)</text><rect x=\"30\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem envia</text><rect x=\"570\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem recebe</text><path d=\"M150 65 H566\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-amber)\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;ping&quot;</text><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem espaço: de mão em mão</text><text x=\"90\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera até quem recebe chegar</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">com buffer: make(chan int, 3)</text><rect x=\"30\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem envia</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem recebe</text><rect x=\"280\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"303\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><rect x=\"334\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"357\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"388\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"411\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M272 172 H450 V222 H272 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150 197 H268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-amber)\"></path><text x=\"206\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><path d=\"M454 197 H566\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-phosphor)\"></path><text x=\"510\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tira o mais antigo</text><text x=\"90\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só espera quando os três estão ocupados</text></svg>", "caption": "Um envio sem buffer espera quem recebe. Um envio com buffer só espera espaço."}
```

Então um buffer muda duas coisas, e as duas importam para o projeto.

- **Ele deixa quem envia andar na frente, no máximo o tamanho do buffer.** Um produtor com rajadas e
  um consumidor de ritmo constante podem ser desacoplados por um buffer do tamanho de uma rajada.
- **Ele tira o encontro.** Um envio que retorna pôs o valor no buffer; não diz nada sobre alguém ter
  recebido. A garantia da seção 02 some.

O que um buffer não faz é deixar rápido um consumidor lento. Aqui o buffer ficou cheio do quarto
envio em diante, e quem envia andou no ritmo de quem recebe do mesmo jeito. **Um buffer absorve uma
rajada; não absorve uma diferença de velocidade que dura.** Aumentá-lo só adia o momento em que ele
enche, e esconde o descompasso enquanto isso.

Dois tamanhos têm sentido próprio. `0` é o canal sem buffer. `1` é um canal em que quem envia sempre
consegue deixar um valor sem esperar, o que a lição 6 usa para impedir que uma goroutine vaze.
Qualquer outro tamanho é um número que alguém escolheu, e a pergunta honesta sobre ele é o que
acontece quando enche.
