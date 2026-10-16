---
title: Rodando uma simulação, e o relatório dela
version: 1
---

Uma simulação é rodada pelo Maven, pelo wrapper do pacote, e a propriedade `gatling.simulationClass`
diz qual classe rodar. Inicie a bilheteria no primeiro terminal e depois, no segundo, a partir da
pasta do pacote:

```sh
cd ~/gatling-charts-highcharts-bundle-3.15.1
./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation
```

O Maven compila a classe primeiro, depois o Gatling imprime um bloco de contagens a cada cinco
segundos enquanto o teste roda, e um resumo no fim. A transcrição abaixo manda tudo isso para um
arquivo, `run.log`, imprime o código de saída e depois mostra o arquivo do resumo em diante:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation > run.log; echo "exit $?"
Oct 10, 2026 4:37:50 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
exit 0
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ sed -n '/Global Information/,$p' run.log
---- Global Information -------------------------------------------------------------|---Total---|-----OK----|----KO----
> request count                                                                      |       110 |       110 |         -
> min response time (ms)                                                             |        14 |        14 |         -
> max response time (ms)                                                             |       252 |       252 |         -
> mean response time (ms)                                                            |        65 |        65 |         -
> response time std deviation (ms)                                                   |        48 |        48 |         -
> response time 50th percentile (ms)                                                 |        58 |        58 |         -
> response time 75th percentile (ms)                                                 |        84 |        84 |         -
> response time 95th percentile (ms)                                                 |       155 |       155 |         -
> response time 99th percentile (ms)                                                 |       249 |       249 |         -
> mean throughput (rps)                                                              |         5 |         5 |         -
---- Response Time Distribution ----------------------------------------------------------------------------------------
> OK: t < 800 ms                                                                                            110   (100%)
> OK: 800 ms <= t < 1200 ms                                                                                   0     (0%)
> OK: t >= 1200 ms                                                                                            0     (0%)
> KO                                                                                                          0     (0%)
========================================================================================================================

Reports generated, please open the following file: file:///home/ana/gatling-charts-highcharts-bundle-3.15.1/target/gatling/boxofficesimulation-20261010193751406/index.html
show: 95th percentile of response time is less than 200.0 : true (actual : 83.0)
Global: percentage of failed events is less than 1.0 : true (actual : 0.0)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  30.753 s
[INFO] Finished at: 2026-10-10T16:38:14-03:00
[INFO] ------------------------------------------------------------------------
```

As duas linhas antes do código de saída vêm do Java criando uma pasta de preferências numa pasta
pessoal que nunca teve uma; aparecem uma vez e não significam nada para o teste.

## O resumo do console

| linha | o que diz aqui |
|---|---|
| `request count` | 110 requisições, todas na coluna `OK`: nenhum check falhou |
| `min`, `max`, `mean` | 14, 252 e 65 ms, somando espetáculos e reservas |
| `response time std deviation` | 48 ms: quanto os tempos se espalham em volta da média |
| `50th`, `75th`, `95th`, `99th percentile` | 58, 84, 155 e 249 ms |
| `mean throughput (rps)` | 5 requisições por segundo, na execução inteira |
| `Response Time Distribution` | quantas respostas ficaram abaixo de 800 ms, entre 800 e 1.200, acima, e quantas foram KO |

**As colunas próprias do Gatling são `OK` e `KO`**: OK é uma requisição que passou em todos os
checks, KO uma que falhou em algum. Os limites de 800 e 1.200 ms da distribuição são os padrões do
Gatling, definidos em `gatling.conf`, e não têm nada a ver com o requisito deste curso. Como no k6,
muitos desses tempos incluem uns 40 ms gastos fora da aplicação, numa conexão que o gerador mantém
aberta; a aula 9 descobre onde.

**Depois vêm as asserções, uma linha cada, com o valor que foi comparado.** `show: 95th percentile
of response time is less than 200.0 : true (actual : 83.0)` é o requisito da aula 1 para
`GET /shows/{id}`, cumprido. As duas se mantiveram, o Maven imprimiu `BUILD SUCCESS` e o código de
saída foi 0.

## Uma asserção que reprova

`-Dp95=5` pede um percentil 95 abaixo de 5 ms, que nenhuma requisição a esta bilheteria alcança:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation -Dp95=5 > run.log; echo "exit $?"
exit 1
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ sed -n '/Reports generated/,/BUILD/p' run.log
Reports generated, please open the following file: file:///home/ana/gatling-charts-highcharts-bundle-3.15.1/target/gatling/boxofficesimulation-20261010193821502/index.html
show: 95th percentile of response time is less than 5.0 : false (actual : 33.0)
Global: percentage of failed events is less than 1.0 : true (actual : 0.0)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
```

**Uma asserção ultrapassada reprova o build do Maven, e o código de saída é 1.** O Maven sai com 1
para qualquer falha, então o pipeline vê um teste de carga reprovado do mesmo jeito que vê um teste
unitário reprovado, e a linha que diz `false` é onde você descobre qual asserção foi.

## O relatório HTML

Toda execução escreve um relatório, e o caminho dele é o que a linha `Reports generated` imprime.
Cada execução ganha uma pasta própria, com o nome da simulação e o momento em que começou:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ls target/gatling/*/index.html
target/gatling/boxofficesimulation-20261010193751406/index.html
target/gatling/boxofficesimulation-20261010193821502/index.html
```

**O relatório é um `index.html` por execução**, com os mesmos números desenhados em gráficos:
usuários ativos e requisições por segundo ao longo do tempo, tempos de resposta ao longo do tempo
por percentil, e uma página por nome de requisição, `show` e `booking`. Ele precisa de um
navegador, então abra-o no seu próprio computador: copie a pasta para fora da VM com
`multipass transfer --recursive`, ou rode `python3 -m http.server 8090 --bind 0.0.0.0` dentro de
`target/gatling` e abra o endereço da VM na porta 8090. Nenhuma das duas coisas foi feita para este
curso; as transcrições mostram só o console.
