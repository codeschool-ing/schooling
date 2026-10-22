---
title: O que um profile registra
version: 1
---

A imagem que a maioria das pessoas traz de um profiler é um cronômetro em cada função: cada chamada
medida na entrada e na saída, depois tudo somado. **O profiler do Go não cronometra chamada
nenhuma. Ele amostra.** Enquanto um profile de CPU está sendo tirado, o runtime interrompe o que
estiver rodando cem vezes por segundo, anota a pilha de chamadas que encontra e deixa o programa
seguir. Uma função que aparece em muitas dessas pilhas é para onde o tempo foi, tenha ela rodado uma
vez por muito tempo ou dois milhões de vezes por um instante cada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Uma goroutine roda por 60 milissegundos, chamando Count, Parse e Fields milhares de vezes. A cada 10 milissegundos o runtime registra a pilha que está rodando naquele instante: strings.Fields sobre tally.Parse sobre tally.Count; tally.Count sozinha; runtime.mallocgc sobre Scanner.Text sobre tally.Count; time.Parse sobre tally.Parse sobre tally.Count; e strings.Fields mais duas vezes. O profile guarda as seis pilhas. strings.Fields está no topo de três delas, uns 30 milissegundos dela mesma; tally.Count está nas seis, uns 60 milissegundos contando o que chamou.\"><text x=\"110\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma goroutine contando linhas, durante 60 ms</text><rect x=\"110\" y=\"32\" width=\"540\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Count, Parse, Fields, Parse, Text, Parse... milhares de chamadas, nenhuma cronometrada</text><text x=\"110\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M200 58 V64 M200 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"200\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10 ms</text><rect x=\"157\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"157\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"157\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><path d=\"M290 58 V64 M290 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"290\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">20 ms</text><rect x=\"247\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><path d=\"M380 58 V64 M380 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">30 ms</text><rect x=\"337\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"337\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">(*Scanner).Text</text><rect x=\"337\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">runtime.mallocgc</text><path d=\"M470 58 V64 M470 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">40 ms</text><rect x=\"427\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"427\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"427\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">time.Parse</text><path d=\"M560 58 V64 M560 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">50 ms</text><rect x=\"517\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"517\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"517\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><path d=\"M650 58 V64 M650 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"650\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">60 ms</text><rect x=\"607\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"607\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"607\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><text x=\"16\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a cada 10 ms o runtime</text><text x=\"16\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">registra a pilha</text><path d=\"M16 196 H704\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que o profile guarda: seis pilhas, cada uma valendo 10 ms</text><text x=\"16\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">strings.Fields no topo de 3 das 6 pilhas: uns 30 ms dela mesma</text><text x=\"16\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tally.Count nas 6 pilhas: uns 60 ms, contando o que ela chamou</text></svg>", "caption": "Um profile de CPU é uma pilha de pilhas de chamadas colhidas nos tiques de um relógio de 100 Hz, e nada entre eles. Estas seis são pilhas do tipo que o profile do benchmark guarda, cortadas aos quadros de tally.Count para cima."}
```

**Uma amostra custa o mesmo, faça o programa o que fizer**, e por isso é razoável tirar um profile de
um processo atendendo tráfego de verdade, onde um cronômetro em volta de cada chamada não seria. O
preço é a resolução. Um tique a cada 10 milissegundos não vê nada mais curto que um tique, a menos
que aconteça com frequência. O profile de uma execução de um segundo tem umas cem pilhas, então o
terceiro dígito de qualquer porcentagem nele é ruído. A seção 03 mede um benchmark que rodou por
cerca de um segundo e obtém exatamente isso.

## Oito profiles, um formato

Tempo de CPU é uma pergunta. O runtime guarda registros para várias outras, e todos são gravados no
mesmo formato e lidos com a mesma ferramenta, `go tool pprof`:

| profile | o que é uma amostra | coletando? |
|---|---|---|
| CPU | a pilha em execução quando um tique de 10 ms disparou | só entre `StartCPUProfile` e `StopCPUProfile`, ou com `-cpuprofile` |
| `heap` | a pilha que alocou, escolhida mais ou menos uma vez a cada 512 KB alocados | sempre |
| `allocs` | os mesmos registros de `heap`, mostrados por padrão como tudo o que já foi alocado | sempre |
| `goroutine` | a pilha de cada goroutine que existe neste momento | tirado quando pedido |
| `goroutineleak` | a pilha de cada goroutine bloqueada para sempre em algo que nenhuma goroutine em execução alcança | tirado quando pedido, depois de uma coleta de lixo que procura por elas |
| `block` | o tempo que uma goroutine passou esperando um canal, um mutex, um `WaitGroup` | **desligado** até `runtime.SetBlockProfileRate` |
| `mutex` | o tempo que outras goroutines passaram esperando um lock, cobrado de quem o segurava | **desligado** até `runtime.SetMutexProfileFraction` |
| `threadcreate` | a pilha que fez o runtime iniciar uma thread do sistema operacional | sempre |

Os nomes da primeira coluna são os do próprio runtime: `runtime/pprof` os lista na documentação e
`net/http/pprof` os serve com esses nomes na seção 05. O profile de CPU não tem nome nessa lista
porque funciona de outro jeito: **ele vai gravando amostras num arquivo enquanto roda**, então tem
início e fim, enquanto os outros são um retrato de registros que o runtime já mantém.

## O profile de heap tem quatro visões

O profiler de memória amostra alocações conforme acontecem. `runtime.MemProfileRate` vale 512 ×
1024, o que significa uma amostra a cada 512 KB alocados, mais ou menos, e cada amostra lembra a pilha
que alocou e o tamanho. Quando o objeto é coletado, o registro fica sabendo também. Então **cada
amostra carrega quatro números**, e o `go tool pprof` mostra um de cada vez:

| `-sample_index` | a pergunta que responde |
|---|---|
| `inuse_space` | quantos bytes estão vivos agora, e quem os alocou |
| `inuse_objects` | quantos objetos estão vivos agora |
| `alloc_space` | quantos bytes foram alocados desde o início do programa, lixo incluído |
| `alloc_objects` | quantas alocações foram feitas desde o início do programa |

**Um vazamento aparece em `inuse`, e rotatividade aparece em `alloc`.** Um programa cuja memória
cresce por uma semana tem a resposta na primeira visão. Um programa lento porque cria e joga fora
milhões de objetos pequenos tem a resposta na terceira e na quarta, e a visão `inuse` dele pode estar
quase vazia. O `hits` é do segundo tipo, como a seção 04 mostra com dois milhões de linhas. `heap` e
`allocs` são os mesmos registros com outra visão padrão: `heap` abre em `inuse_space` e `allocs` em
`alloc_space`.

A visão do heap também vem com um atraso que surpreende: **ela descreve o heap como estava na última
coleta de lixo**, então uma alocação feita há um instante ainda não está nela. Um programa que quer o
heap de agora chama `runtime.GC()` antes de gravar o profile, que é o que a seção 04 faz.

## Dois que vêm desligados, e por quê

`block` e `mutex` registram espera, e espera acontece o tempo todo num programa concorrente: cada
recebimento de canal que não encontra nada, cada `Lock` que encontra o mutex ocupado. **Registrar
cada uma deixaria lentos justamente os programas que precisam do profile**, então os dois começam
desligados e não registram nada até o programa pedir. `runtime.SetBlockProfileRate(rate)` mira uma
amostra a cada `rate` nanossegundos passados em bloqueio, e 1 significa todos;
`runtime.SetMutexProfileFraction(n)` registra em média um evento de disputa a cada `n`. A seção 05
mostra a lista de profiles que um programa em execução serve, com os dois ainda em zero.

Os profiles de goroutines são diferentes outra vez. Não custam nada até alguém pedir, e então são um
censo: cada goroutine e onde ela está esperando. **Uma contagem de goroutines que só sobe é a
assinatura de um vazamento**, e o `goroutineleak` vai um passo além e nomeia as goroutines que nunca
mais vão rodar. A seção 05 encontra trinta delas num programa que estava rodando havia uns dezesseis
segundos.
