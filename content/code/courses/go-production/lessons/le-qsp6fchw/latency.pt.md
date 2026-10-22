---
title: Esperar também é tempo
version: 1
---

**O tempo de relógio de uma goroutine é o tempo em que ela rodou, o tempo em que estava pronta e sem
processador, e o tempo em que estava bloqueada.** O profile de CPU da lição 12 mede o primeiro e só
o primeiro, porque faz amostras do que está num processador. Os profiles de bloqueio e de mutex da
mesma lição contam o terceiro, depois de ligados, pela chamada que bloqueou. O do meio, pronta e
sem rodar, não está em profile nenhum do pprof, e é o que se chama de **latência do escalonador**.
Um trace tem os três, para cada goroutine, em ordem.

A ideia errada comum é que um programa que não ficou mais rápido com mais goroutines deve estar
fazendo trabalho demais. Às vezes ele está esperando demais, e de fora as duas coisas parecem
iguais.

## Mais workers, nada mais rápido

O `pcount` com um, dois, quatro e oito workers, um depois do outro:

```
ana@vm:~/trace-hits$ for w in 1 2 4 8; do ./pcount -workers $w big.log; done
3000000 lines (0 bad), 8 paths, 1 workers, 1.466s
3000000 lines (0 bad), 8 paths, 2 workers, 1.689s
3000000 lines (0 bad), 8 paths, 4 workers, 2.084s
3000000 lines (0 bad), 8 paths, 8 workers, 2.053s
```

Em quatro CPUs, quatro workers demoraram mais que um. As execuções com trace da seção 02 tinham ido
para o outro lado, 958ms contra 1.357s, e **essa discordância já é o primeiro achado**: o que quer
que limite este programa, não é o número de goroutines fazendo parse.

## Um lock segurado tempo demais

O `-shared` é a versão que alguém com pressa escreve: um `tally.Summary` para todo mundo, atrás de
um mutex, travado em volta de cada linha, parse incluído. Está correto, como o teste da seção 02
confere. Cronometrado com o `time` do shell, ao lado de um worker só:

```
ana@vm:~/trace-hits$ time ./pcount -workers 1 big.log
3000000 lines (0 bad), 8 paths, 1 workers, 1.058s

real	0m1.060s
user	0m1.111s
sys	0m0.166s
ana@vm:~/trace-hits$ time ./pcount -workers 4 -shared big.log
3000000 lines (0 bad), 8 paths, 4 workers, 1.144s

real	0m1.149s
user	0m1.213s
sys	0m0.119s
```

`user` é o tempo de processador que o programa usou: 1,111 segundo para um worker e 1,213 para
quatro dividindo um lock. **Quatro goroutines fizeram o trabalho de uma e usaram o tempo de
processador de uma**, então um profile de CPU da execução com `-shared` mostraria `tally.Parse`,
`strings.Fields` e as atualizações dos maps em proporções bem parecidas com as do worker único. Nada
nele diria que três goroutines estavam paradas a cada momento.

O trace diz isso direto. O `go tool trace -pprof=sync` transforma o tempo que as goroutines passaram
bloqueadas em sincronização num arquivo pprof, que o `go tool pprof` lê como qualquer outro. O
`-focus=main.count` fica com as pilhas que passam por `count` e descarta as goroutines do próprio
runtime:

```
ana@vm:~/trace-hits$ ./pcount -workers 4 -shared -trace shared.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 1.023s
ana@vm:~/trace-hits$ go tool trace -pprof=sync shared.trace > sync.pprof
ana@vm:~/trace-hits$ go tool pprof -top -focus=main.count sync.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main.count
Showing nodes accounting for 2.16s, 50.73% of 4.26s total
Dropped 11 nodes (cum <= 0.02s)
      flat  flat%   sum%        cum   cum%
     1.71s 40.15% 40.15%      1.71s 40.15%  sync.(*Mutex).Lock
     0.32s  7.53% 47.68%      0.32s  7.53%  runtime.chansend1
     0.10s  2.27% 49.96%      0.10s  2.27%  runtime.chanrecv2
     0.02s  0.41% 50.36%      0.02s  0.41%  runtime.gcMarkDone
     0.02s  0.37% 50.73%      0.02s  0.37%  runtime.gcStart
         0     0% 50.73%      0.01s  0.32%  example.com/hits/internal/tally.Parse
         0     0% 50.73%      0.01s  0.32%  main.(*part).add
         0     0% 50.73%      0.34s  8.02%  main.count
         0     0% 50.73%      1.82s 42.75%  main.count.func1
         0     0% 50.73%      1.72s 40.47%  main.count.func1.1
         0     0% 50.73%      0.34s  8.02%  main.main
         0     0% 50.73%      0.34s  8.02%  main.run
         0     0% 50.73%      0.02s  0.41%  runtime.gcAssistAlloc
         0     0% 50.73%      0.02s  0.56%  runtime.makeslice
         0     0% 50.73%      0.03s  0.77%  runtime.mallocgc
         0     0% 50.73%      0.01s  0.32%  runtime.mallocgcSmallScanNoHeaderSC7
         0     0% 50.73%      1.72s 40.47%  runtime/trace.WithRegion
         0     0% 50.73%      0.01s  0.32%  strings.Fields
         0     0% 50.73%      1.82s 42.75%  sync.(*WaitGroup).Go.func1
```

`Type: delay` diz que os números são tempo bloqueado, não tempo num processador. **1,71 segundo em
`sync.(*Mutex).Lock`, numa execução que durou 1,023 segundo.** As esperas dos quatro workers se
sobrepõem, então somam mais que o relógio; em média, 1,7 dos quatro estavam esperando o lock a cada
momento. `main.count.func1.1` é a closure dentro do `WithRegion`, a que trava a cada linha. A
primeira linha, `Main binary filename not available.`, é o pprof avisando que o arquivo não cita
nenhum binário; o trace trouxe os próprios símbolos, então não falta nada.

A mesma pergunta feita ao trace de quatro workers da seção 02, que não pega lock nenhum:

```
ana@vm:~/trace-hits$ go tool trace -pprof=sync w4.trace > sync4.pprof && go tool pprof -top -focus=main.count sync4.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main.count
Showing nodes accounting for 1497.97ms, 60.10% of 2492.53ms total
Dropped 3 nodes (cum <= 12.46ms)
      flat  flat%   sum%        cum   cum%
  605.17ms 24.28% 24.28%   605.17ms 24.28%  runtime.gcStart
  570.17ms 22.88% 47.15%   570.17ms 22.88%  runtime.chanrecv2
  248.04ms  9.95% 57.11%   248.04ms  9.95%  runtime.gcMarkDone
   74.60ms  2.99% 60.10%    74.60ms  2.99%  runtime.chansend1
         0     0% 60.10%    93.23ms  3.74%  bufio.(*Scanner).Text
         0     0% 60.10%   687.18ms 27.57%  example.com/hits/internal/tally.Parse
         0     0% 60.10%   687.18ms 27.57%  main.(*part).add
         0     0% 60.10%   241.39ms  9.68%  main.count
         0     0% 60.10%  1257.35ms 50.44%  main.count.func1
         0     0% 60.10%   687.18ms 27.57%  main.count.func1.1
         0     0% 60.10%   241.39ms  9.68%  main.main
         0     0% 60.10%   241.39ms  9.68%  main.run
         0     0% 60.10%     8.31ms  0.33%  runtime.deductAssistCredit
         0     0% 60.10%   248.04ms  9.95%  runtime.gcAssistAlloc
         0     0% 60.10%   759.99ms 30.49%  runtime.makeslice
         0     0% 60.10%   853.21ms 34.23%  runtime.mallocgc
         0     0% 60.10%    71.60ms  2.87%  runtime.mallocgcSmallNoScanSC5
         0     0% 60.10%    21.62ms  0.87%  runtime.mallocgcSmallNoScanSC6
         0     0% 60.10%    41.42ms  1.66%  runtime.mallocgcSmallNoScanSlowPath
         0     0% 60.10%    64.50ms  2.59%  runtime.mallocgcSmallScanHeader
         0     0% 60.10%   687.18ms 27.57%  runtime.mallocgcSmallScanNoHeaderSC7
         0     0% 60.10%   205.60ms  8.25%  runtime.mallocgcSmallScanSlowPath
         0     0% 60.10%    93.23ms  3.74%  runtime.slicebytetostring
         0     0% 60.10%   687.18ms 27.57%  runtime/trace.WithRegion
         0     0% 60.10%   687.18ms 27.57%  strings.Fields
         0     0% 60.10%  1257.35ms 50.44%  sync.(*WaitGroup).Go.func1
```

Nenhum mutex. **As esperas em `sync` que a seção 03 contou são do coletor**: `runtime.gcStart` e
`runtime.gcMarkDone` são workers que alocaram o bastante para iniciar uma coleta, ou para ajudar a
terminar uma, e então esperaram nos semáforos do próprio coletor. `runtime.chanrecv2` é o laço
`range batches` esperando a leitora, 570,17ms disso somados nos quatro workers.

## Para onde foi o tempo, execução por execução

A página Goroutine analysis divide a vida de cada goroutine em estados. Somado nos quatro workers,
ou no único, para cada execução com trace desta lição, incluindo a execução com `GOMAXPROCS=1`
mais abaixo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Barras empilhadas de como os workers gastaram o tempo em quatro execuções do pcount com trace. Um worker: 73 por cento rodando, 13 executável, 4 esperando em sync, 10 esperando num recebimento de canal. Quatro workers: 31 rodando, 35 executável, 18 sync, 15 canal. Quatro workers dividindo um mutex: 22 rodando, 33 executável, 42 sync, 2 canal. Quatro workers com GOMAXPROCS=1: 19 rodando, 80 executável, 2 canal.\"><text x=\"200.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde foi o tempo dos workers</text><text x=\"690.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">execução</text><text x=\"190.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 worker</text><rect x=\"200.0\" y=\"38.0\" width=\"305.8\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"352.9\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">73%</text><rect x=\"505.8\" y=\"38.0\" width=\"53.9\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"532.8\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">13%</text><rect x=\"559.7\" y=\"38.0\" width=\"18.2\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"577.8\" y=\"38.0\" width=\"41.0\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"598.3\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10%</text><rect x=\"618.8\" y=\"38.0\" width=\"1.2\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36 s</text><text x=\"190.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers</text><rect x=\"200.0\" y=\"78.0\" width=\"129.4\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"264.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">31%</text><rect x=\"329.4\" y=\"78.0\" width=\"147.7\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"403.2\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">35%</text><rect x=\"477.0\" y=\"78.0\" width=\"75.3\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"514.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">18%</text><rect x=\"552.4\" y=\"78.0\" width=\"62.5\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"583.6\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15%</text><rect x=\"614.9\" y=\"78.0\" width=\"5.1\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">958 ms</text><text x=\"190.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers, -shared</text><rect x=\"200.0\" y=\"118.0\" width=\"93.1\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"246.5\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">22%</text><rect x=\"293.1\" y=\"118.0\" width=\"139.2\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"362.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">33%</text><rect x=\"432.2\" y=\"118.0\" width=\"176.9\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"520.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">42%</text><rect x=\"609.2\" y=\"118.0\" width=\"9.9\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"619.1\" y=\"118.0\" width=\"0.9\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.02 s</text><text x=\"190.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers, GOMAXPROCS=1</text><rect x=\"200.0\" y=\"158.0\" width=\"78.5\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"239.2\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">19%</text><rect x=\"278.5\" y=\"158.0\" width=\"335.2\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"446.1\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">80%</text><rect x=\"613.7\" y=\"158.0\" width=\"6.3\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">768 ms</text><rect x=\"40.0\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--phosphor)\"></rect><text x=\"60.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rodando</text><rect x=\"130.8\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--amber)\"></rect><text x=\"150.8\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">executável</text><rect x=\"240.8\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"260.8\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esperando: sync</text><rect x=\"382.8\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"402.8\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esperando: chan receive</text><rect x=\"576.0\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"596.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outros</text></svg>", "caption": "O tempo dos workers em quatro execuções com trace, tirado da página Goroutine analysis do go tool trace: cada barra soma o tempo de todos os workers na execução, com a duração da execução à direita.", "same": ["1 worker", "4 workers", "4 workers, -shared", "4 workers, GOMAXPROCS=1"]}
```

**Um worker rodou 73% do seu tempo; quatro workers rodaram 31% do deles.** O resto da barra de
quatro workers é a resposta para o enigma da seção 02. Um terço dela é executável: quatro workers, a
leitora e os workers do próprio coletor queriam mais processadores do que havia, então goroutines
prontas fizeram fila por um `P`. Quase um quinto é o coletor, e um sétimo é espera por uma leitora
que não dava conta. Na execução com `-shared` o lock fica com a maior fatia, 42%, e a parte rodando
cai para 22%, abaixo dos 31% dos quatro workers que não dividiam nada.

Uma ressalva sobre tudo isso. **O trace é a visão do escalonador do Go.** Quando o sistema
operacional tira uma CPU de uma das threads do programa, como fez muitas vezes nesta máquina
compartilhada, a goroutine naquela thread continua contando como rodando. Um trace explica o tempo
que o runtime controla; o resto aparece como execução que demorou mais do que devia.

## Latência do escalonador

Para ver o estado do meio sozinho, dê ao programa um `P` e quatro workers:

```
ana@vm:~/trace-hits$ GOMAXPROCS=1 ./pcount -workers 4 -trace p1.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 768ms
ana@vm:~/trace-hits$ go tool trace -pprof=sched p1.trace > sched.pprof && go tool pprof -top -focus=main -nodecount=6 sched.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main
Showing nodes accounting for 3184.43ms, 75.21% of 4234.05ms total
Dropped 4 nodes (cum <= 21.17ms)
Showing top 6 nodes out of 20
      flat  flat%   sum%        cum   cum%
 2437.01ms 57.56% 57.56%  2437.01ms 57.56%  runtime.chansend1
  476.27ms 11.25% 68.81%   476.27ms 11.25%  runtime.chanrecv2
  271.15ms  6.40% 75.21%   271.15ms  6.40%  runtime.systemstack_switch
         0     0% 75.21%    71.73ms  1.69%  bufio.(*Scanner).Text
         0     0% 75.21%   199.43ms  4.71%  example.com/hits/internal/tally.Parse
         0     0% 75.21%   199.43ms  4.71%  main.(*part).add
```

O `-pprof=sched` mede **o tempo entre uma goroutine ficar executável e começar a rodar**. O total do
profile, 4.234,05ms, é cinco vezes e meia os 768ms da execução: em média, mais de cinco goroutines,
contando as do runtime, estavam prontas atrás daquela que tinha o `P`. A pilha a que ele atribui o
tempo é onde a goroutine ficou executável, que não é onde ela estava esperando. `runtime.chansend1`
debaixo de `main.count` é a leitora enviando um lote: cada envio acordou um worker, e os workers
acordados assim esperaram 2.437,01ms no total pela vez deles.

A barra dessa execução na figura é 80% executável, e mesmo assim 768ms é a execução mais curta da
lição. **O paralelismo não rendeu nada a este programa naquela máquina**, porque o limite dele nunca foi o parse. Era uma goroutine lendo e alocando uma string por linha, e um coletor limpando atrás
dela, 94 vezes nos 958ms da execução de quatro workers. É o trace que diz isso, e ele também diz
onde olhar em seguida. As lições 12 e 13 medem as alocações; as lições 19 e 20 explicam por que
custam o que custam.

| `go tool trace -pprof=` | o que mede | onde atribui o tempo |
|---|---|---|
| `sync` | bloqueio num canal, num `select`, num mutex, num `WaitGroup` ou num semáforo do runtime | a chamada que bloqueou |
| `sched` | executável e esperando um `P` | onde a goroutine ficou executável |
| `syscall` | bloqueio numa chamada de sistema | a chamada que entrou nela |
| `net` | bloqueio esperando a rede | a leitura ou escrita que esperou |
