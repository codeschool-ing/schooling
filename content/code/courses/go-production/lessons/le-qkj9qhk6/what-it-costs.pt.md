---
title: Quanto custa, medido no hits
version: 1
---

A lição 16 de `go-concurrency` mediu o detector num programa que não fazia nada além de pegar um
lock e mexer num mapa, e o achou doze vezes mais lento, com nove vezes a memória. **Essas proporções
pertencem àquele programa, e um pipeline roda o seu.** Então meça o preço no código que o pipeline
vai de fato testar: o `BenchmarkCountParallel` da seção 02, que faz o parsing de 20.000 linhas com
quatro workers, agora sobre o `CountParallel` corrigido da seção 03.

## Tempo, com o benchmark

`-run "^$"` não casa com nenhum nome de teste, então só o benchmark roda. Uma vez sem detector e uma
vez com ele:

```
ana@vm:~/race-hits$ go test -run "^$" -bench . -benchmem ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCountParallel-4   	      93	  10830468 ns/op	 4132806 B/op	   40042 allocs/op
PASS
ok  	example.com/hits/internal/tally	1.032s
ana@vm:~/race-hits$ go test -race -run "^$" -bench . -benchmem ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCountParallel-4   	      20	  50833093 ns/op	 4133512 B/op	   40044 allocs/op
PASS
ok  	example.com/hits/internal/tally	2.059s
```

**10.830.468 nanossegundos por rodada sem detector, 50.833.093 com ele: quase cinco vezes mais
tempo.** A proporção varia entre execuções numa máquina que divide espaço com outros trabalhos, de
menos de cinco a mais de sete nas execuções feitas para esta lição, então leia como "várias vezes", e
não como 4,7. As outras duas colunas são a surpresa. O `-benchmem` informou 4.132.806 bytes por
rodada contra 4.133.512, e 40.042 alocações contra 40.044: o mesmo. Isso não quer dizer que o
detector sai de graça. O `-benchmem` conta o que o heap do Go entregou, e **o detector guarda seus
registros fora do heap do Go**, numa memória que as estatísticas de alocação do runtime nunca veem.
Para enxergar essa memória é preciso perguntar ao sistema operacional.

## Memória, pelo kernel

O `go test -c` compila o binário de teste de um pacote sem rodá-lo, então os dois builds podem ser
executados como qualquer programa. O kernel guarda uma marca de pico da memória de cada processo, a
linha `VmHWM` de `/proc/PID/status`; o laço abaixo a lê a cada décimo de segundo enquanto o benchmark
roda e imprime a última leitura antes de o processo sumir:

```
ana@vm:~/race-hits$ go test -c -o tally.test ./internal/tally && go test -race -c -o tally-race.test ./internal/tally
ana@vm:~/race-hits$ stat -c "%s bytes  %n" tally.test tally-race.test
4745513 bytes  tally.test
6049910 bytes  tally-race.test
ana@vm:~/race-hits$ ./tally.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"
VmHWM:	   19748 kB
ana@vm:~/race-hits$ ./tally-race.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"
VmHWM:	   46020 kB
```

**19.748 kB no pico sem detector, 46.020 kB com ele: mais que o dobro**, para o mesmo benchmark e o
mesmo heap do Go. O binário cresceu de 4.745.513 bytes para 6.049.910, cerca de 1,3 MB, que são o
runtime do detector embutido e as chamadas extras compiladas em volta de cada acesso à memória. Como
a lição 16 de `go-concurrency` viu no programa dela, o tamanho é pequeno e o preço é pago enquanto o
programa roda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Gráfico de barras: o build com detector de corrida do benchmark de CountParallel comparado ao build comum. Tempo por rodada 10,83 ms contra 50,83 ms, 4,7 vezes. Pico de memória 19.748 kB contra 46.020 kB, 2,3 vezes. Binário de teste 4.745.513 contra 6.049.910 bytes, 1,3 vez. Heap alocado por rodada, como o -benchmem informa, 4.132.806 contra 4.133.512 bytes, igual: a memória do próprio detector não fica no heap do Go.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o build com -race, em múltiplos do build comum</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tempo por rodada do benchmark</text><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.83 ms / 50.83 ms</text><rect x=\"230\" y=\"50\" width=\"243.9\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"483.88\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4,7 vezes</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pico de memória, VmHWM</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19,748 kB / 46,020 kB</text><rect x=\"230\" y=\"96\" width=\"121.2\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"361.15999999999997\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2,3 vezes</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tamanho do binário de teste</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,745,513 B / 6,049,910 B</text><rect x=\"230\" y=\"142\" width=\"66.0\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"306.04\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1,3 vez</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">heap por rodada, B/op</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,132,806 / 4,133,512</text><rect x=\"230\" y=\"188\" width=\"52.0\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"292.0\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">igual</text><path d=\"M282 40 V47\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 75 V93\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 121 V139\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 167 V185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 213 V224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><text x=\"282\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">build comum</text></svg>", "caption": "Um benchmark, medido duas vezes. O detector custa tempo e memória enquanto o programa roda; o -benchmem conta só o heap do Go, então não mostra nada dessa memória."}
```

Não há uma proporção fixa para citar. Código que passa o tempo mexendo em memória, como um parser
enchendo mapas, paga mais; código que passa o tempo esperando um disco ou uma rede paga menos,
porque esperar não toca memória que o detector precise conferir. **Meça sua própria suíte de testes
uma vez com e sem `-race`** e você sabe quanto o passo do pipeline vai custar; a próxima seção faz
essa conta.

## Um segundo em cada saída

Um custo não é proporcional de jeito nenhum. Aqui estão os testes do mesmo pacote, sem detector e
depois com ele:

```
ana@vm:~/race-hits$ go test -count=1 ./internal/tally; go test -race -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.003s
ok  	example.com/hits/internal/tally	1.017s
ana@vm:~/race-hits$ GORACE=atexit_sleep_ms=0 go test -race -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.013s
```

Três milissegundos sem detector e 1,017 segundo com ele, para testes que quase não levam tempo.
**Um programa compilado com `-race` espera um segundo antes de sair.** A própria descrição das opções do detector chama isso de `atexit_sleep_ms`, em 1.000, "useful to catch 'at exit' races". Uma goroutine ainda rodando quando o `main` retorna ganha um momento para fazer seus acessos e ser
acusada. Com `GORACE=atexit_sleep_ms=0` a mesma execução levou 0,013 segundo.

Todo binário de teste de um módulo paga esse segundo, então um módulo de trinta pacotes paga cerca de
trinta segundos de espera, divididos entre as execuções paralelas que o `go test` faz. Ele também
entra em qualquer medição de um programa `-race` curto com o `time` do shell, o que é mais um motivo
para medir com benchmark: o `ns/op` é tomado dentro da execução e nunca inclui a saída. Zerar isso no
CI troca esses segundos pelas corridas que acontecem quando o programa termina. **Mantenha o padrão a menos que os segundos doam**, e se mudar, mude sabendo quais goroutines do seu código sobrevivem ao
`main`.

## Do que ele precisa

O detector é um runtime em C++, o ThreadSanitizer do projeto LLVM, embutido no binário Go, então o
`-race` precisa de cgo, e o cgo precisa de um compilador C. A lição 1 instalou o `gcc` por esse
motivo e mostrou o que uma máquina sem ele imprime. Um pipeline pode perder o cgo de outro jeito,
definindo `CGO_ENABLED=0` para o job inteiro, como muitos fazem para gerar binários estáticos:

```
ana@vm:~/race-hits$ CGO_ENABLED=0 go test -race ./...; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

**A mesma mensagem da lição 1, com outra causa**: aqui o compilador está instalado e a variável
desligou o cgo. A seção 05 define `CGO_ENABLED=1` no passo que roda o detector exatamente por isso.

O segundo limite é a plataforma. O `go help build` lista onde o `-race` funciona, e pedir qualquer
outra plataforma falha antes de compilar qualquer coisa:

```
ana@vm:~/race-hits$ go help build | grep -A4 "enable data race"
		enable data race detection.
		Supported only on darwin/amd64, darwin/arm64, freebsd/amd64, linux/amd64,
		linux/arm64 (only for 48-bit VMA), linux/ppc64le, linux/riscv64 and
		windows/amd64.
	-msan
ana@vm:~/race-hits$ GOARCH=386 go test -race ./...; echo $?
-race is not supported on linux/386
2
```

Oito pares de sistema operacional e arquitetura, todos de 64 bits. A lista do próprio toolchain, no
código-fonte, admite três a mais do que o texto de ajuda cita, `linux/loong64`, `linux/s390x` e
`netbsd/amd64`, e os runtimes de corrida deles vêm em `/usr/local/go/src/runtime/race`. **Para um
pipeline a resposta prática é curta: rode o passo de corrida em `linux/amd64` ou `linux/arm64`**,
que é onde roda a maioria das máquinas de CI, e deixe os builds de release com compilação cruzada da
lição 16 sem ele. Um alvo de 32 bits como `linux/386` não tem detector nenhum.
