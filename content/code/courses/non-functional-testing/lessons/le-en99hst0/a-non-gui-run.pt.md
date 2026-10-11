---
title: Uma rodada sem a janela
version: 1
---

Com a bilheteria rodando no seu próprio terminal, como na aula 2, o plano roda a partir de
`~/loadtest` com um comando. Cada opção tem uma função:

| opção | o que faz |
|---|---|
| `-n` | modo não gráfico |
| `-t plan.jmx` | o plano de teste a rodar |
| `-l results.jtl` | grava cada amostra neste arquivo |
| `-e -o report/` | quando a rodada termina, monta um relatório HTML a partir das amostras, em `report/` |

```
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -l results.jtl -e -o report/
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Starting standalone test @ 2026 Oct 10 16:52:02 BRT (1791661922743)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary +      1 in 00:00:02 =    0.6/s Avg:    28 Min:    28 Max:    28 Err:     0 (0.00%) Active: 7 Started: 7 Finished: 0
summary +    326 in 00:00:25 =   12.8/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%) Active: 20 Started: 20 Finished: 0
summary =    327 in 00:00:27 =   12.0/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%)
summary +     35 in 00:00:03 =   12.2/s Avg:     8 Min:     1 Max:    23 Err:     0 (0.00%) Active: 0 Started: 20 Finished: 20
summary =    362 in 00:00:30 =   12.0/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 10 16:52:32 BRT (1791661952869)
... end of run
```

## As linhas de resumo

Enquanto um teste não gráfico roda, o **summariser** do JMeter imprime uma linha a cada 30 segundos,
e mais uma no fim. Uma linha `summary +` cobre só o período desde a anterior; uma linha `summary =`
é o total acumulado desde o início. **O último `summary =` é a rodada inteira**: 362 amostras em 30
segundos, 12,0 por segundo, uma média de 8 ms, a mais lenta com 32 ms e nenhum erro. `Active`,
`Started` e `Finished` contam as threads, e o primeiro `summary +` mostra a rampa trabalhando, com 7
das 20 iniciadas depois de dois segundos.

Vinte usuários pensando 1,5 segundo em média, contra respostas de poucos milissegundos, deveriam
enviar umas 20 / 1,5 ≈ 13 requisições por segundo pela lei da aula 3, e a rodada mediu 12,0, com a
rampa respondendo por parte da diferença. O resumo basta para saber que a rodada aconteceu e mais ou
menos como foi. **Ele não basta para julgar um requisito**: uma média de duas operações são dois
números borrados num só, e é por isso que o requisito da aula 1 nomeia um percentil de uma operação.

## O arquivo de resultados

Cada amostra foi para `results.jtl`, uma linha CSV cada:

```
ana@nft:~/loadtest$ head -4 results.jtl
timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect
1791661924518,28,GET /shows,200,OK,visitors 1-3,text,true,,1745,124,7,7,http://127.0.0.1:8000/shows,28,0,17
1791661924519,27,GET /shows,200,OK,visitors 1-1,text,true,,1745,124,7,7,http://127.0.0.1:8000/shows,27,0,17
1791661924837,3,GET /shows,200,OK,visitors 1-2,text,true,,1745,124,8,8,http://127.0.0.1:8000/shows,2,0,1
ana@nft:~/loadtest$ ls report
content
index.html
sbadmin2-1.0.7
statistics.json
ana@nft:~/loadtest$ jq -c '.["GET /shows/{id}"] | {sampleCount, errorCount, medianResTime, pct2ResTime, throughput}' report/statistics.json
{"sampleCount":176,"errorCount":0,"medianResTime":13.0,"pct2ResTime":27.0,"throughput":6.460375142238373}
```

As colunas que mais importam são `elapsed`, os milissegundos de logo antes do envio até o último byte
da resposta; `label`, o nome do sampler; `responseCode` e `success`; `Latency`, o tempo até o
primeiro byte; e `Connect`, o tempo gasto abrindo a conexão. Nas duas primeiras linhas, `Connect` é
17 ms de uma amostra de 28 ms, porque cada thread abriu a sua conexão naquele momento. A terceira
linha, uma requisição posterior de uma thread numa conexão que ela manteve, gastou 1 ms conectando.

O diretório `report/` são as mesmas amostras como um painel HTML: gráficos ao longo do tempo, uma
tabela por sampler, e os percentis que a aula 8 explica. O `statistics.json` guarda a tabela, e o
`jq` lê uma linha dela: 176 amostras de `GET /shows/{id}`, uma mediana de 13 ms, e um `pct2ResTime`,
o percentil 95, de 27 ms. Esse último número é o que um requisito julgaria.

Para ler o painel, abra `report/index.html` num navegador do seu próprio computador, depois de
copiar o diretório para fora da VM com `multipass transfer --recursive nft:loadtest/report .`. Isso
não foi rodado aqui. O JMeter se recusa a gravar num diretório de relatório que já tem arquivos,
então apague `report/` antes da próxima rodada com `-e -o report/`.

## Quando uma asserção falha

Uma asserção transforma uma resposta errada num erro, mesmo quando o servidor respondeu depressa e
com um status que parecia bom. Para ver uma falhar, acrescente ao arquivo de dados um espetáculo que
não existe e rode o plano por dez segundos, com `-Jseconds=10` definindo a propriedade que o thread
group lê:

```
ana@nft:~/loadtest$ echo 1001 >> shows.csv
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -l broken.jtl -Jseconds=10
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Starting standalone test @ 2026 Oct 10 16:52:38 BRT (1791661958983)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =     87 in 00:00:10 =    8.8/s Avg:    43 Min:     1 Max:   410 Err:     2 (2.30%)
Tidying up ...    @ 2026 Oct 10 16:52:49 BRT (1791661969186)
... end of run
ana@nft:~/loadtest$ grep -m 2 ",false," broken.jtl
1791661965678,53,GET /shows/{id},404,Not Found,visitors 1-17,text,false,"Test failed: text expected to contain /""left""/",235,129,20,20,http://127.0.0.1:8000/shows/1001,53,0,0
1791661968882,29,GET /shows/{id},404,Not Found,visitors 1-3,text,false,"Test failed: text expected to contain /""left""/",235,129,5,5,http://127.0.0.1:8000/shows/1001,29,0,0
ana@nft:~/loadtest$ sed -i '/1001/d' shows.csv
```

**`Err: 2 (2.30%)` no resumo é a asserção trabalhando**: duas vezes nesses dez segundos uma thread
leu `1001` do arquivo, a bilheteria respondeu `404`, e o corpo não tinha `"left"`. No `.jtl` as
amostras que falharam trazem `false` e a mensagem da própria asserção. Um 404 é marcado como falha
mesmo sem asserção, porque o JMeter trata qualquer status de 400 para cima como falha. A asserção é
o que pega a resposta que está *errada* com um `200`, como uma lista vazia ou uma página de erro
servida como sucesso. O último comando tira o `1001` do arquivo de novo.

## Por que o plano não tem listener

Um listener recebe cada amostra assim que ela é produzida, e alguns guardam todas na memória. O
*View Results Tree* guarda o corpo de cada requisição e de cada resposta, que é exatamente o que o
torna útil para depurar um usuário e ruinoso para mil. **Numa rodada de carga, o `.jtl` gravado com
`-l` é o listener**: ele grava cada amostra em disco e não guarda nada, e o relatório e qualquer
outra análise são montados a partir desse arquivo depois da rodada. Um plano feito para rodadas de
carga não carrega listeners, ou os tem desativados, e os da GUI servem para montá-lo.
