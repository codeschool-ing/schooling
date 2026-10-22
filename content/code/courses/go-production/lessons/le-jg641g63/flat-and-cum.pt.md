---
title: Flat e cum
version: 1
---

A lição 12 terminou com três profiles que concordavam num nome, `strings.Fields`, e com a promessa
de que lê-los direito viria depois. **Cada linha do `go tool pprof -top` traz duas medidas da mesma
função, e a maioria das leituras erradas de um profile vem de olhar uma e achar que é a outra.**
Esta seção separa as duas num profile com amostras suficientes para confiar.

## Um profile que vale ler

Um benchmark de um segundo deu à lição 12 umas 120 amostras. O `-benchtime 200x` roda exatamente 200
iterações em vez disso, alguns segundos de trabalho, e o `-run '^$'` não casa com nome de teste
nenhum, então os testes do pacote não rodam antes e não vão parar no profile ao lado do benchmark.
Ana está em `~/prof` como a lição 12 deixou:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchtime 200x -cpuprofile cpu.out -memprofile mem.out ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	     200	  31520093 ns/op	 145.05 MB/s
PASS
ok  	example.com/hits/internal/tally	6.369s
```

Cada iteração levou uns 31,5 milissegundos, então as 200 são 20 milhões de chamadas de `Parse` sobre
as 100.000 linhas de `testdata/access.log`. O relatório, ordenado do jeito padrão:

```
ana@vm:~/prof$ go tool pprof -top cpu.out | sed /^Time:/d | head -16
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 5.51s, 91.83% of 6s total
Dropped 81 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      2.53s 42.17%  strings.Fields
     0.53s  8.83% 28.83%      0.53s  8.83%  runtime.asyncPreempt
     0.31s  5.17% 34.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
     0.28s  4.67% 38.67%      0.29s  4.83%  runtime.unlock2
     0.22s  3.67% 42.33%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.22s  3.67% 46.00%      0.23s  3.83%  runtime.lock2
     0.19s  3.17% 49.17%      0.22s  3.67%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.15s  2.50% 51.67%      0.15s  2.50%  internal/runtime/maps.memHashAES
     0.14s  2.33% 54.00%      0.14s  2.33%  runtime.memmove
```

Desta vez são 600 amostras, de 10 ms cada. Cinco colunas de números, em dois grupos:

| coluna | o que diz |
|---|---|
| `flat` | amostras em que esta função era a que estava rodando: o quadro do topo da pilha |
| `flat%` | o mesmo, como fração de todas as amostras |
| `sum%` | o total acumulado de `flat%` descendo a lista |
| `cum` | amostras em que esta função estava **em qualquer ponto** da pilha: ela e tudo o que ela chamou |
| `cum%` | o mesmo, como fração |

**Flat é o tempo gasto no código da própria função. Cum é o tempo entre ela ser chamada e
retornar**, seja quem for que fez o trabalho. `strings.Fields` tem 1,20 segundo de flat e 2,53 de
cum: dos 2,53 segundos durante os quais uma chamada de `Fields` estava em andamento, 1,20 foram os
laços dela sobre os bytes e os outros 1,33 ficaram em funções que ela chamou, que a próxima seção
nomeia. O `-top` ordena por flat, então as primeiras linhas são as funções cujo código próprio está
mais ocupado.

## O mesmo profile por cum

O `-cum` ordena pela outra coluna. No prompt interativo, `go tool pprof cpu.out`, os dois relatórios
são os comandos `top` e `top -cum`:

```
ana@vm:~/prof$ go tool pprof -top -cum cpu.out | sed /^Time:/d | head -16
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 5.51s, 91.83% of 6s total
Dropped 81 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     0.22s  3.67%  3.67%      4.95s 82.50%  example.com/hits/internal/tally.Count
         0     0%  3.67%      4.95s 82.50%  example.com/hits/internal/tally_test.BenchmarkCount
         0     0%  3.67%      4.95s 82.50%  testing.(*B).run1.func1
         0     0%  3.67%      4.95s 82.50%  testing.(*B).runN
     0.02s  0.33%  4.00%      3.82s 63.67%  example.com/hits/internal/tally.Parse
     1.20s 20.00% 24.00%      2.53s 42.17%  strings.Fields
     0.02s  0.33% 24.33%      1.05s 17.50%  runtime.mallocgc
     0.03s   0.5% 24.83%      0.75s 12.50%  runtime.makeslice
     0.31s  5.17% 30.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
```

**`tally.Count` vem primeiro, com 82,50% de cum e 0,22 segundo de flat.** Os dois números estão
certos. O `Count` está na pilha de quase toda amostra, porque tudo o que o benchmark faz acontece
dentro dele. Quase nenhuma instrução dele mesmo está rodando num dado instante: ele dá voltas, chama
`Scan`, chama `Parse`, atualiza dois mapas, e cada um desses é uma função com amostras próprias. As
três linhas com os mesmos 82,50% e flat zero, `BenchmarkCount`, `runN` e `run1.func1`, são os
quadros abaixo dele, a estrutura do benchmark, que não gasta tempo próprio nenhum.

**Cum alto com flat minúsculo é uma função que delega.** Otimizar o código dela rende no máximo o
flat, 3,67% aqui; o que ela rende mudando o que chama, ou quantas vezes, vai até o cum. Flat alto é
o contrário: o trabalho está no laço da própria função, e é esse laço que se olha. Os 17,5%
restantes das amostras nem estão sob o `Count`: são as goroutines do próprio runtime, o coletor de
lixo varrendo memória, uma goroutine sendo reescalonada, que trabalham em outras threads e aparecem
no profile como qualquer outro código.

Duas linhas do runtime merecem uma frase, porque aparecem em quase todo profile de Go.
`runtime.mallocgc` e as parentes são **alocação**: 17,50% de cum aqui, o preço de duas alocações por
linha. `runtime.asyncPreempt`, 8,83% de flat, é onde uma amostra cai quando o runtime acabou de
interromper uma goroutine em execução para deixar o escalonador ou o coletor agir; é tempo real, e
cresce quando a máquina está ocupada com outro trabalho.

## A mais frequente e a mais cara

A pergunta do título desta lição é fácil de entender ao contrário. **Um profile de CPU não conta
chamadas.** O `Parse` é chamado 20 milhões de vezes e o `Count` 200, e nada no relatório diz isso:
os dois são só pilhas apanhadas num tique. Uma função chamada muitas vezes e muito barata, e uma
chamada uma vez e devagar, ficam iguais no profile se somarem o mesmo tempo.

Então o custo de uma chamada é algo que você calcula, a partir do total do profile e de uma contagem
que você conhece pelo programa. `strings.Fields` ficou na pilha por 2,53 segundos ao longo de uns 20
milhões de chamadas, **cerca de 126 nanossegundos por chamada**, dos uns 315 que custa uma linha
inteira, a 31,5 ms por 100.000 linhas. É esse número que diz se uma função é lenta ou só ocupada, e
é ele que se compara com uma alternativa.

O profile de memória deixa a distinção à vista, porque registra contagens e tamanhos. As duas visões
que o `go tool pprof` chama de `alloc_objects` e `alloc_space`:

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_objects mem.out | sed /^Time:/d | head -8
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_objects
Showing nodes accounting for 39884661, 100% of 39895461 total
Dropped 37 nodes (cum <= 199477)
      flat  flat%   sum%        cum   cum%
  20343925 50.99% 50.99%   20343925 50.99%  strings.Fields
  19538916 48.98%   100%   19538916 48.98%  bufio.(*Scanner).Text (inline)
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -8
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_space
Showing nodes accounting for 2550.17MB, 99.62% of 2559.89MB total
Dropped 37 nodes (cum <= 12.80MB)
      flat  flat%   sum%        cum   cum%
 1552.12MB 60.63% 60.63%  1552.12MB 60.63%  strings.Fields
  997.55MB 38.97% 99.60%   997.55MB 38.97%  bufio.(*Scanner).Text (inline)
```

**Em contagem, os dois alocadores empatam: uma alocação cada por linha**, uns 20 milhões cada na
execução, e os 4% entre eles são do amostrador, não do código. Em tamanho, `strings.Fields` fez
1.552,12 MB contra 997,55 MB do `Scanner.Text`. Cada chamada de `Fields` aloca uma fatia de cinco
strings, 5 × 16 = 80 bytes, enquanto o `Text` copia a linha, uns 45 bytes, que o alocador arredonda
para uma das classes de tamanho dele, 48 ou 64 bytes. A alocação mais frequente e a mais cara são
perguntas diferentes, e **o `-sample_index` é como se faz a segunda**: `alloc_objects` acha o código
que aloca muitas vezes, `alloc_space` o código que aloca muito.