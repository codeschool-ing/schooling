---
title: Vegeta, um programa só e um pipeline
version: 1
---

O Vegeta é um programa só, escrito em Go, como o k6, e não tem cenários, nem tempo de reflexão, nem
usuários. **Ele manda requisições na taxa que você nomeia, pelo tempo que você diz, e nada mais.** É
menos que qualquer ferramenta até aqui, e é exatamente a forma do requisito da aula 1: uma operação,
numa taxa, por uma duração.

## Um programa só

```sh
cd ~
curl -fsSLO https://github.com/tsenart/vegeta/releases/download/v12.13.0/vegeta_12.13.0_linux_amd64.tar.gz
tar -xzf vegeta_12.13.0_linux_amd64.tar.gz vegeta
sudo install vegeta /usr/local/bin/
```

Em ARM o pacote é `vegeta_12.13.0_linux_arm64.tar.gz`. **Essas linhas não foram rodadas para este
curso**, porque o computador em que ele foi gravado não alcança o GitHub; o Vegeta das transcrições
foi compilado a partir do mesmo código-fonte da v12.13.0, e é por isso que a versão mostra uma
versão de Go e uma data vazia:

```
ana@nft:~$ vegeta -version
Version: v12.13.0
Commit: 4b240c3089fa4aa10816542d64a74294d974211f
Runtime: go1.25.1 linux/amd64
Date: 
```

## Um pipeline de três comandos

O Vegeta são três subcomandos ligados por pipes, cada um fazendo um passo. O `vegeta attack` lê
alvos, uma requisição por linha, e escreve os resultados num formato binário; o `vegeta report` lê
resultados e os imprime. O `tee` guarda uma cópia dos resultados num arquivo no caminho:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-pipeline\" aria-label=\"O Vegeta como um pipeline, da esquerda para a direita. O echo escreve um alvo, uma linha com GET e um endereço. O vegeta attack lê alvos e os manda na taxa que recebeu, pela duração que recebeu, e escreve um resultado binário por requisição. O tee copia esses resultados em results.bin no caminho. O vegeta report lê resultados e os imprime como texto, como histograma ou como JSON, e consegue ler results.bin de novo depois, sem mandar nada.\"><defs><marker id=\"l07-pipeline-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-pipeline-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">echo</text><rect x=\"20.0\" y=\"92.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"80.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um alvo</text><text x=\"80.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">por linha</text><rect x=\"172.0\" y=\"50.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"247.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">vegeta attack</text><rect x=\"172.0\" y=\"92.0\" width=\"150.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"247.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-rate=50</text><text x=\"247.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-duration=10s</text><rect x=\"354.0\" y=\"50.0\" width=\"100.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tee</text><rect x=\"354.0\" y=\"92.0\" width=\"100.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"404.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma cópia</text><text x=\"404.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no caminho</text><rect x=\"486.0\" y=\"50.0\" width=\"214.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"593.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">vegeta report</text><rect x=\"486.0\" y=\"92.0\" width=\"214.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"593.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type=text</text><text x=\"593.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type='hist[...]'</text><text x=\"593.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type=json</text><path d=\"M140.0 67.0 L168.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><path d=\"M322.0 67.0 L350.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><path d=\"M454.0 67.0 L482.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><text x=\"156.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alvos</text><text x=\"338.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultados</text><text x=\"470.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultados</text><rect x=\"354.0\" y=\"176.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">results.bin</text><path d=\"M404.0 148.0 L404.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-amber)\"></path><path d=\"M454.0 191.0 L593.0 191.0 L593.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-amber)\"></path><text x=\"600.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">relatar de novo, sem mandar nada</text></svg>", "caption": "Três comandos ligados por pipes: o que mandar, mandar, e ler o que voltou."}
```

Cinquenta requisições por segundo durante dez segundos para o espetáculo de que a aula 1 falava,
com a bilheteria rodando no primeiro terminal:

```
ana@nft:~$ echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=50 -duration=10s | tee results.bin | vegeta report
Requests      [total, rate, throughput]         500, 50.10, 49.80
Duration      [total, attack, wait]             10.041s, 9.981s, 60.171ms
Latencies     [min, mean, 50, 90, 95, 99, max]  7.45ms, 47.629ms, 52.846ms, 58.017ms, 60.875ms, 68.687ms, 74.068ms
Bytes In      [total, mean]                     60000, 120.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:500  
Error Set:
```

**`Requests` diz que a taxa foi mantida**: 500 requisições, mandadas a 50.10 por segundo, respondidas
a uma vazão de 49.80. `Latencies` dá o mínimo, a média, os percentis 50, 90, 95 e 99 e o máximo,
então o número do requisito é o quinto: um percentil 95 de 60.875 ms, abaixo dos 200 ms da aula 1.
`Success` é a fração de respostas com status 2xx ou 3xx, e `Error Set` lista os erros distintos,
nenhum aqui.

Os resultados em `results.bin` podem ser relatados de novo, em qualquer das formas do relatório,
sem mandar uma requisição sequer. Um histograma com as faixas que você escolhe mostra onde os tempos
caíram:

```
ana@nft:~$ vegeta report -type='hist[0,20ms,40ms,60ms,100ms,200ms]' results.bin
Bucket           #    %       Histogram
[0s,     20ms]   82   16.40%  ############
[20ms,   40ms]   5    1.00%   
[40ms,   60ms]   367  73.40%  #######################################################
[60ms,   100ms]  46   9.20%   ######
[100ms,  200ms]  0    0.00%   
[200ms,  +Inf]   0    0.00%   
```

**O histograma tem duas corcovas.** 82 respostas voltaram em menos de 20 ms, mais ou menos o tempo
que o `curl` da aula 1 mediu, e 367 entre 40 e 60 ms, quase sem nada entre as duas. Numa conexão que
o gerador de carga mantém aberta, uns 40 ms de uma resposta são gastos fora da aplicação, e a aula 9
descobre onde.

## Um modelo aberto, e por que isso importa

**O Vegeta manda a próxima requisição quando o relógio manda, não quando chega a última resposta.**
Se a bilheteria está lenta, o Vegeta começa mais workers e mantém a taxa. Esse é o modelo aberto das
aulas 5 e 6, e o Vegeta não tem usuários nem tempo de reflexão para ser outra coisa; só o
`-max-workers`, que limita quantas requisições podem estar em voo, o impediria de manter a taxa.
Pedindo mais do que a bilheteria atende, as respostas ficam para trás e se acumulam:

```
ana@nft:~$ echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=300 -duration=5s -timeout=5s | vegeta report
Requests      [total, rate, throughput]         1500, 300.16, 135.39
Duration      [total, attack, wait]             9.86s, 4.997s, 4.863s
Latencies     [min, mean, 50, 90, 95, 99, max]  15.483ms, 2.508s, 2.413s, 5s, 5.001s, 5.001s, 5.013s
Bytes In      [total, mean]                     160200, 106.80
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           89.00%
Status Codes  [code:count]                      0:165  200:1335  
Error Set:
Get "http://127.0.0.1:8000/shows/990": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l07-backlog\" aria-label=\"Requisições por segundo ao longo do tempo, nos dez segundos da execução a 300 por segundo, desenhadas a partir dos totais e não amostradas. O Vegeta manda 300 por segundo por cinco segundos e para. A bilheteria responde umas 135 por segundo o tempo todo, até 9,86 segundos. A distância entre as duas linhas durante o ataque é a fila: requisições mandadas e esperando resposta. Depois do ataque, a bilheteria passa quase mais cinco segundos atendendo a fila, e as requisições que esperaram mais que o timeout de cinco segundos ficam sem resposta.\"><path d=\"M90.0 200.0 L650.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 200.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 200.0 L90.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M202.0 200.0 L202.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"202.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M314.0 200.0 L314.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><path d=\"M426.0 200.0 L426.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"426.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s</text><path d=\"M538.0 200.0 L538.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 s</text><path d=\"M650.0 200.0 L650.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M86.0 200.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 136.7 L90.0 136.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"136.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">135</text><path d=\"M86.0 59.4 L90.0 59.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"59.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"82.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisições/s</text><path d=\"M90.0 59.4 L370.0 59.4 L370.0 136.7 L90.0 136.7 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"230.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">a fila cresce</text><path d=\"M90.0 59.4 L370.0 59.4 L370.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"378.0\" y=\"59.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mandadas: 300 por segundo, e para</text><path d=\"M90.0 136.7 L642.2 136.7 L642.2 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"504.4\" y=\"124.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">respondidas: umas 135 por segundo</text><text x=\"504.4\" y=\"171.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a fila esvazia</text><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um gerador aberto continua mandando, então a espera aparece nos tempos que ele informa</text></svg>", "caption": "A execução a 300 por segundo: a bilheteria não acompanha, e as requisições ainda sem resposta esperam na fila."}
```

**O Vegeta mandou a 300.16 por segundo e a bilheteria respondeu a 135.39.** A taxa foi mantida até
o fim do ataque, então as requisições que a bilheteria não conseguia atender esperaram na fila. A
mediana foi de 52.846 ms a cinquenta por segundo para 2.413 s aqui, e 165 requisições chegaram ao
`-timeout` de cinco segundos sem resposta nenhuma: é o `0` em `Status Codes` e o `context deadline
exceeded` em `Error Set`, e o motivo de o `Success` ser 89.00%. Um gerador fechado com o mesmo
número de usuários teria diminuído o próprio envio para acompanhar, e imprimido números bem mais
gentis.

A aula 8 dá nome ao que um gerador fechado faz no lugar: **omissão coordenada** (*coordinated
omission*). Um gerador fechado, cujos usuários esperam cada resposta, manda menos requisições
justamente enquanto o sistema está lento, e deixa os momentos lentos fora da própria amostra. O
Vegeta não consegue fazer isso, o que faz dele a ferramenta certa quando a pergunta é "o que
acontece nesta taxa", e a aula 8 mostra a diferença em números.
