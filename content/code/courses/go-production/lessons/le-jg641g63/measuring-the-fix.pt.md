---
title: Medindo a correção
version: 1
---

Uma mudança feita por causa de um profile termina quando **uma medição diz que funcionou, quanto, e
como o profile ficou**. Três ferramentas fazem isso: o benchstat compara dois conjuntos de execuções
de benchmark e diz se a diferença é real, o `-diff_base` subtrai um profile de outro, e o profile
novo mostra o que ainda resta achar.

## Dez execuções contra dez execuções

O mesmo comando de benchmark de antes, num segundo arquivo, e o benchstat para compará-los. Ele não
vem na distribuição padrão. Mora em `golang.org/x/perf`, um módulo sem tags de versão, então a
versão a fixar é uma pseudoversão, uma data e um commit:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchmem -count 10 ./internal/tally > new.txt
ana@vm:~/prof$ go install golang.org/x/perf/cmd/benchstat@v0.0.0-20261009192801-be2c69fb417e
ana@vm:~/prof$ benchstat old.txt new.txt
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
        │   old.txt   │               new.txt               │
        │   sec/op    │   sec/op     vs base                │
Count-4   33.52m ± 7%   18.33m ± 7%  -45.31% (p=0.000 n=10)

        │   old.txt    │               new.txt                │
        │     B/s      │     B/s       vs base                │
Count-4   130.1Mi ± 7%   237.9Mi ± 7%  +82.87% (p=0.000 n=10)

        │    old.txt    │               new.txt                │
        │     B/op      │     B/op      vs base                │
Count-4   12.706Mi ± 0%   5.077Mi ± 0%  -60.04% (p=0.000 n=10)

        │   old.txt   │               new.txt               │
        │  allocs/op  │  allocs/op   vs base                │
Count-4   200.0k ± 0%   100.0k ± 0%  -50.00% (p=0.000 n=10)
```

Cada tabela é uma medida, o antigo à esquerda, o novo no meio e a mudança à direita. **De 33,52 ms
para 18,33 ms por contagem, −45,31%**: a mediana de dez execuções de cada lado, e o `± 7%` ao lado
de cada uma é o intervalo de confiança de 95% em volta dessa mediana, mais largo quando as execuções
discordam. O `p=0.000` é a probabilidade de ver uma diferença desse tamanho se a mudança não tivesse
feito nada; o benchstat imprime `~` no lugar da porcentagem quando essa probabilidade é alta demais
para chamar aquilo de mudança. A memória se moveu exatamente como planejado, sem dispersão nenhuma,
porque alocação não depende de quão ocupada está a máquina: **5,077 MiB por contagem em vez de
12,706, e 100.000 alocações em vez de 200.000**, uma por linha, a fatia sumiu.

**A dispersão é o motivo das dez execuções.** Na máquina compartilhada em que isto foi gravado, uma
execução do código antigo e uma do novo poderiam ter caído em qualquer ponto dos 7%. Numa máquina mais
ocupada a dispersão aumenta, e um único par
antes e depois mediria só o momento.

## O profile, antes e depois

O `-diff_base` subtrai um profile de base do que está sendo lido, então cada linha mostra o que
mudou. Os dois profiles vêm de `-benchtime 200x`, as mesmas 200 iterações do mesmo trabalho, e é
isso que dá sentido à subtração: duas execuções de durações diferentes difeririam em tudo.

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchtime 200x -cpuprofile cpu.new -memprofile mem.new ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	     200	  17741499 ns/op	 257.70 MB/s
PASS
ok  	example.com/hits/internal/tally	3.573s
ana@vm:~/prof$ go tool pprof -top -diff_base cpu.out cpu.new | sed /^Time:/d | head -14
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: cpu
Duration: 9.90s, Total samples = 6s (60.63%)
Showing nodes accounting for -2.31s, 38.50% of 6s total
Dropped 70 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
    -1.20s 20.00% 20.00%     -2.53s 42.17%  strings.Fields
     0.68s 11.33%  8.67%      0.72s 12.00%  example.com/hits/internal/tally.split5
    -0.31s  5.17% 13.83%     -0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
    -0.28s  4.67% 18.50%     -0.28s  4.67%  runtime.asyncPreempt
     0.20s  3.33% 15.17%     -1.63s 27.17%  example.com/hits/internal/tally.Parse
    -0.19s  3.17% 18.33%     -0.19s  3.17%  runtime.lock2
    -0.16s  2.67% 21.00%     -0.17s  2.83%  runtime.unlock2
```

Números negativos são tempo que foi embora. **O `strings.Fields` perdeu todos os 2,53 segundos dele
e o `split5` acrescentou 0,72**, então as mesmas linhas foram separadas em menos de um terço do
tempo; o `tally.Parse` inteiro ficou 1,63 segundo mais leve, e o alocador e os locks do runtime
ficaram mais leves junto. O profile novo tem 3,55 segundos de amostras contra os 6 do antigo para as
mesmas 200 iterações, o que concorda com o benchstat na direção e, mais ou menos, no tamanho, como
duas medições independentes de uma mudança devem concordar.

## O que sobrou

O profile novo sozinho, ordenado por flat:

```
ana@vm:~/prof$ go tool pprof -top cpu.new | sed /^Time:/d | head -16
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: cpu
Duration: 3.56s, Total samples = 3.55s (99.61%)
Showing nodes accounting for 3.37s, 94.93% of 3.55s total
Dropped 43 nodes (cum <= 0.02s)
      flat  flat%   sum%        cum   cum%
     0.68s 19.15% 19.15%      0.72s 20.28%  example.com/hits/internal/tally.split5
     0.25s  7.04% 26.20%      0.25s  7.04%  runtime.asyncPreempt
     0.22s  6.20% 32.39%      2.19s 61.69%  example.com/hits/internal/tally.Parse
     0.18s  5.07% 37.46%      3.26s 91.83%  example.com/hits/internal/tally.Count
     0.18s  5.07% 42.54%      0.37s 10.42%  time.Date
     0.17s  4.79% 47.32%      0.50s 14.08%  time.ParseDuration
     0.15s  4.23% 51.55%      0.17s  4.79%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.13s  3.66% 55.21%      0.13s  3.66%  internal/runtime/maps.memHashAES
     0.12s  3.38% 58.59%      0.12s  3.38%  runtime.unlock2
```

**A primeira linha agora é o `split5`, com 19,15% de flat**, o laço que olha cada byte uma vez. Isso
não é sinal de um problema novo: alguma função sempre vem primeiro, e um laço que toca cada byte da
entrada tem de custar alguma coisa. Por chamada são 0,72 segundo sobre uns 20 milhões de linhas, uns
36 nanossegundos, contra os 126 que o `strings.Fields` custava. Abaixo dele as amostras se espalham:
o horário, `time.Date` e `time.ParseDuration`, as consultas a mapas por trás das contagens, o
runtime. **Nenhuma linha domina mais**, e é isso que um profile plano quer dizer.

A memória diz o mesmo:

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space mem.new | sed /^Time:/d | head -8
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: alloc_space
Showing nodes accounting for 1.01GB, 99.21% of 1.02GB total
Dropped 31 nodes (cum <= 0.01GB)
      flat  flat%   sum%        cum   cum%
    1.01GB 99.21% 99.21%     1.01GB 99.21%  bufio.(*Scanner).Text (inline)
         0     0% 99.21%     1.01GB 99.26%  example.com/hits/internal/tally.Count
```

1,02 GB alocados nas 200 iterações, contra 2.559,89 MB antes, e **quase tudo é do `Scanner.Text`**,
a string por linha que o `Count` pede. Remover essa também é possível, trabalhando nos bytes do
scanner e convertendo em string só o caminho, e custa um `Parse` que recebe `[]byte` e um segundo
conjunto de testes. O pacote `unsafe` também consegue pular a cópia, e a lição 22 trata do que esse
tipo de atalho custa.

## Quando parar

Duas regras saem desta lição, e a segunda é a que as pessoas quebram.

**Meça antes de otimizar.** Todo instinto sobre este código apontava para o `time.Parse`; o profile
apontou para o `strings.Fields`, e um parser de horário escrito à mão teria sido um dia de trabalho
para o quarto do custo que o profile já tinha descartado.

**Pare quando o profile estiver plano.** Antes da mudança, uma função tinha 42% das amostras, e
remover a maior parte do custo dela deu uma contagem 45% mais rápida por algumas dezenas de linhas
de código e um teste. Agora a maior linha tem 19%, e nem tornar o `split5` gratuito, o que é
impossível, renderia mais que isso; a linha seguinte tem 7%. Cada mudança a mais rende menos que a
anterior e acrescenta código que alguém precisa ler. **O que é suficiente é uma decisão sobre o
programa, não sobre o profile**: o `hits` conta 91 MB em bem menos de um segundo, o que basta para o
log que um servidor escreve num dia, e o profile agora diz onde olhar se um dia não bastar.