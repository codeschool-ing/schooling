---
title: Lendo os números, e o que eles não podem dizer
version: 1
---

As duas execuções da seção anterior mandaram as mesmas 20000 requisições para a mesma aplicação, e
não concordaram. A primeira levou 11 segundos a 1878,3 requisições por segundo, com média de 9 ms;
a segunda levou 7 segundos a 2787,8 por segundo, com média de 5 ms. Dentro da primeira execução, a
primeira linha `summary +`, cobrindo os três primeiros segundos, só chegou a 837,9 por segundo.

**A primeira execução depois de uma subida mede um programa diferente.** Na subida, a JVM
interpreta a maior parte do código da livraria. Ela compila para código de máquina os métodos que
se mostram movimentados conforme a carga avança, e carrega muitas classes só quando a primeira
requisição precisa delas. Um teste de carga, portanto, primeiro aquece a aplicação, joga essa
execução fora, e só então mede.

## A média esconde as requisições lentas

O relatório guarda cada número por rótulo e no total, no `statistics.json`. O total da execução
aquecida:

```
ana@vm:~/bookshop$ python3 -c 'import json; print(json.dumps(json.load(open("target/jmeter/report/statistics.json"))["Total"], indent=1))'
{
 "transaction": "Total",
 "sampleCount": 20000,
 "errorCount": 0,
 "errorPct": 0.0,
 "meanResTime": 5.726850000000034,
 "medianResTime": 4.0,
 "minResTime": 0.0,
 "maxResTime": 103.0,
 "pct1ResTime": 13.0,
 "pct2ResTime": 17.0,
 "pct3ResTime": 26.0,
 "throughput": 2821.272393849626,
 "receivedKBytesPerSec": 1422.040308929327,
 "sentKBytesPerSec": 359.5469212865002
}
```

`pct1ResTime`, `pct2ResTime` e `pct3ResTime` são percentis, e as configurações do próprio JMeter
dizem quais:

```
ana@vm:~/bookshop$ grep aggregate_rpt_pct ~/opt/apache-jmeter-5.6.3/bin/jmeter.properties
#aggregate_rpt_pct1=90
#aggregate_rpt_pct2=95
#aggregate_rpt_pct3=99
```

Um **percentil** ordena todos os tempos de resposta e lê uma posição: o percentil 95 é o tempo em
que 95% das requisições ficaram ou abaixo. Nesta execução a mediana foi 4 ms e a média 5,7, enquanto
uma requisição em cada dez levou 13 ms ou mais, uma em cada cem 26 ms ou mais, e a mais lenta
103 ms, dezoito vezes a média.

A média resume mal o tempo de resposta, porque os tempos são desequilibrados: a maioria é curta,
alguns são muitas vezes mais longos, e são esses poucos que as pessoas sentem. Uma página que faz
dez requisições espera pela mais lenta delas, então quem a carrega encontra a cauda lenta muito
mais vezes do que uma requisição em cem faria pensar. É por isso que a meta de um serviço se
escreve como percentil, por exemplo "95% das buscas respondem em menos de 50 ms", e não como média.

## Vinte threads é uma escolha, e ela molda a resposta

Cada thread do plano envia uma requisição, **espera a resposta**, e só então envia a próxima. Isso é
um **modelo fechado**: a carga é um número de usuários, não um número de requisições por segundo, e
ela diminui quando a aplicação fica mais lenta. Então a taxa que uma execução alcança é no máximo o
número de threads dividido pelo tempo de resposta. A execução aquecida tinha vinte threads e média
de 5 ms, então não poderia passar de 4000 requisições por segundo, fosse o servidor capaz do que
fosse; ela chegou a 2787,8.

Para ver o que a livraria faz com mais carga, acrescente threads e observe os dois números. O plano
lê `threads` e `loops` como propriedades, então um laço no shell pode rodá-lo seis vezes, cada
execução com as mesmas 20000 requisições:

```
ana@vm:~/bookshop$ for t in 1 5 10 20 50 100; do printf "%3d threads  " $t; jmeter -n -t src/test/jmeter/books.jmx -Jthreads=$t -Jloops=$((10000 / t)) -l target/jmeter/sweep.jtl -j target/jmeter/sweep.log -f | grep "summary ="; done
  1 threads  summary =  20000 in 00:00:15 = 1356.2/s Avg:     0 Min:     0 Max:    19 Err:     0 (0.00%)
  5 threads  summary =  20000 in 00:00:06 = 3629.1/s Avg:     0 Min:     0 Max:    18 Err:     0 (0.00%)
 10 threads  summary =  20000 in 00:00:05 = 4088.3/s Avg:     1 Min:     0 Max:    24 Err:     0 (0.00%)
 20 threads  summary =  20000 in 00:00:04 = 4447.4/s Avg:     2 Min:     0 Max:    24 Err:     0 (0.00%)
 50 threads  summary =  20000 in 00:00:04 = 4934.6/s Avg:     4 Min:     0 Max:    39 Err:     0 (0.00%)
100 threads  summary =  20000 in 00:00:04 = 4904.4/s Avg:     5 Min:     0 Max:    65 Err:     0 (0.00%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Dois gráficos de barras sobre as mesmas seis execuções de 1, 5, 10, 20, 50 e 100 threads. Requisições por segundo: 1 threads 1356,2, 5 threads 3629,1, 10 threads 4088,3, 20 threads 4447,4, 50 threads 4934,6, 100 threads 4904,4. Tempo de resposta médio em milissegundos: 1 threads 0, 5 threads 0, 10 threads 1, 20 threads 2, 50 threads 4, 100 threads 5.\"><defs><marker id=\"l20s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisições por segundo</text><polyline points=\"20,240 330,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"32\" y=\"187.7813804563693\" width=\"34\" height=\"52.21861954363069\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"49\" y=\"178.7813804563693\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1356.2</text><text x=\"49\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"82\" y=\"100.26648563206746\" width=\"34\" height=\"139.73351436793254\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"99\" y=\"91.26648563206746\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">3629.1</text><text x=\"99\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"132\" y=\"82.5856199084019\" width=\"34\" height=\"157.4143800915981\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"149\" y=\"73.5856199084019\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4088.3</text><text x=\"149\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"182\" y=\"68.75896729218178\" width=\"34\" height=\"171.24103270781822\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"199\" y=\"59.75896729218178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4447.4</text><text x=\"199\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"232\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"249\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4934.6</text><text x=\"249\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"282\" y=\"51.162809548899645\" width=\"34\" height=\"188.83719045110035\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"299\" y=\"42.162809548899645\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4904.4</text><text x=\"299\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"175\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tempo de resposta médio, ms</text><polyline points=\"370,240 680,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"382\" y=\"240.0\" width=\"34\" height=\"0.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"399\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">0</text><text x=\"399\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"432\" y=\"240.0\" width=\"34\" height=\"0.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"449\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">0</text><text x=\"449\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"482\" y=\"202.0\" width=\"34\" height=\"38.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"499\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1</text><text x=\"499\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"532\" y=\"164.0\" width=\"34\" height=\"76.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"549\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2</text><text x=\"549\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"582\" y=\"88.0\" width=\"34\" height=\"152.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4</text><text x=\"599\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"632\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"649\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">5</text><text x=\"649\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"525\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text></svg>", "caption": "Cada execução enviou as mesmas 20000 requisições. A vazão parou de crescer em cinquenta threads enquanto a média continuou subindo. O JMeter imprime milissegundos inteiros, então uma média abaixo de um milissegundo pode aparecer como 0.", "same": ["threads"]}
```

De uma thread para cinco, a vazão quase triplicou. De cinquenta para cem ela não cresceu nada, e a
média continuou subindo: passado um ponto, uma thread a mais no plano acrescenta uma requisição
esperando numa fila, e não uma requisição respondida. Repare também que a execução com vinte
threads chegou aqui a 4447,4 por segundo, contra 2787,8 na execução aquecida um minuto antes, com as
mesmas vinte threads. A JVM ainda estava aquecendo entre as duas, e numa máquina compartilhada duas
execuções do mesmo plano podem diferir tanto assim. Rode cada ponto pelo menos duas vezes, e só
cite o número quando as execuções concordarem.

## Um computador, medindo a si mesmo

```
ana@vm:~/bookshop$ nproc
4
```

Quatro processadores, e durante estas execuções eles carregavam a livraria, o PostgreSQL e o JMeter
ao mesmo tempo. O JMeter não sai de graça. O `time` da execução aquecida na seção anterior mostrou
10,744 segundos de tempo de processador gastos pelo JMeter em código de usuário, em 10,354 segundos
de tempo decorrido: mais de um dos quatro processadores, em média, do início ao fim. As seis execuções acima
mostram o mesmo pelo outro lado. Com cem threads a 4904,4 requisições por segundo, cada thread
completava uma requisição a cada 20 ms, mais ou menos, enquanto a resposta média levava 5. O resto
desses 20 ms não era a livraria respondendo: era o trabalho do próprio JMeter, e threads esperando
por um processador.

**O que uma execução num computador só mede é aquele computador, com aquele gerador de carga
nele.** Ela serve para uma coisa valiosa: comparar duas versões do seu código com o
mesmo plano na mesma máquina, para ver se uma mudança deixou o catálogo mais lento. Ela não diz o
que um servidor de produção vai aguentar. Esse servidor tem outros processadores, uma rede entre o
cliente e ele, um banco com mais de seis livros, e nenhum JMeter ao lado. Um teste de carga que
responde a essa pergunta roda o gerador em máquinas separadas, contra um ambiente com a forma da
produção.

## Leia os erros primeiro

Pare a aplicação no segundo terminal com Ctrl+C, e rode o plano mais uma vez, um curto:

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -Jloops=50 -l target/jmeter/down.jtl -j target/jmeter/down.log -f | grep "summary ="
summary =   2000 in 00:00:02 = 1031.5/s Avg:     0 Min:     0 Max:    25 Err:  2000 (100.00%)
ana@vm:~/bookshop$ cut -d, -f4,5 target/jmeter/down.jtl | sort | uniq -c
   2000 Non HTTP response code: org.apache.http.conn.HttpHostConnectException,Non HTTP response message: Connect to localhost:8080 [localhost/127.0.0.1] failed: Connection refused
      1 responseCode,responseMessage
```

Média de 0 ms, tão baixa quanto a de qualquer execução desta lição, e cada uma das 2000 requisições
falhou. O arquivo de resultados diz por quê: uma conexão recusada em `localhost:8080`. Uma conexão
recusada falha na hora. **Leia o `Err` antes de qualquer tempo**: um tempo de resposta só quer
dizer alguma coisa quando a requisição por trás dele deu certo.

Teste de carga é um assunto à parte. O curso `non-functional-testing`, na trilha de QA, dedica as
lições 3, 4 e 8 a modelar uma carga, ao JMeter a fundo, inclusive execuções espalhadas por várias
máquinas, e a ler resultados.
