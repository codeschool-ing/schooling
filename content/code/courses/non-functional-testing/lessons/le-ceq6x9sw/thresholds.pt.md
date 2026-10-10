---
title: Limites, e o código de saída
version: 1
---

Um teste de carga que imprime números ainda precisa de alguém para lê-los. **Um limite transforma
a execução num veredito**, e o k6 informa esse veredito no único lugar para onde todo script,
terminal e pipeline já olha: o código de saída do programa. Zero é aprovado, qualquer outra coisa é
reprovado, e ninguém precisa combinar depois o que os números queriam dizer.

## Uma execução que passa

Com a bilheteria rodando no primeiro terminal, rode o script no padrão de três jornadas por
segundo e imprima o código de saída depois dele:

```
ana@nft:~$ k6 run -q k6/boxoffice.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=127.01ms

      {name:booking}
      ✓ 'p(95)<300' p(95)=134.14ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    checks_total.......: 162     7.461202/s
    checks_succeeded...: 100.00% 162 out of 162
    checks_failed......: 0.00%   0 out of 162

    ✓ show answers 200
    ✓ seats left is a number
    ✓ booked or taken

    HTTP
    http_req_duration..............: avg=55.65ms min=16.84ms med=52.53ms max=179.68ms p(90)=103.28ms p(95)=127.01ms
      { expected_response:true }...: avg=55.65ms min=16.84ms med=52.53ms max=179.68ms p(90)=103.28ms p(95)=127.01ms
      { name:booking }.............: avg=79.55ms min=17.18ms med=71.86ms max=179.68ms p(90)=127.19ms p(95)=134.14ms
    http_req_failed................: 0.00% 0 out of 108
    http_reqs......................: 108   4.974135/s

    EXECUTION
    iteration_duration.............: avg=2.06s   min=1.13s   med=2.06s   max=3.02s    p(90)=2.76s    p(95)=2.87s   
    iterations.....................: 54    2.487067/s
    vus............................: 3     min=1        max=7 
    vus_max........................: 20    min=20       max=20

    NETWORK
    data_received..................: 31 kB 1.4 kB/s
    data_sent......................: 14 kB 629 B/s



exit 0
```

O resumo abre com os limites, um bloco por métrica, cada um com um visto e o valor que foi
comparado. Todas as requisições juntas chegaram a um percentil 95 de 127.01 ms contra um limite de
200, só as reservas a 134.14 ms contra 300, e nenhuma requisição falhou. **O código de saída é 0**,
e o `echo "exit $?"` está ali só para você vê-lo; um pipeline o lê sem que ninguém peça.

## O mesmo arquivo, dez vezes a carga

`-e RATE=30` não muda nada no arquivo e pede trinta jornadas por segundo em vez de três:

```
ana@nft:~$ k6 run -q -e RATE=30 k6/boxoffice.js; echo "exit $?"
time="2026-10-10T04:36:07-03:00" level=warning msg="Insufficient VUs, reached 60 active VUs and cannot initialize more" executor=ramping-arrival-rate scenario=visitors


  █ THRESHOLDS 

    http_req_duration
    ✗ 'p(95)<200' p(95)=2.71s

      {name:booking}
      ✗ 'p(95)<300' p(95)=2.76s

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    checks_total.......: 801     33.630389/s
    checks_succeeded...: 100.00% 801 out of 801
    checks_failed......: 0.00%   0 out of 801

    ✓ show answers 200
    ✓ seats left is a number
    ✓ booked or taken

    HTTP
    http_req_duration..............: avg=1s    min=16.66ms med=112.02ms max=2.85s p(90)=2.61s p(95)=2.71s
      { expected_response:true }...: avg=1s    min=16.66ms med=112.02ms max=2.85s p(90)=2.61s p(95)=2.71s
      { name:booking }.............: avg=1.95s min=23.75ms med=2.1s     max=2.85s p(90)=2.71s p(95)=2.76s
    http_req_failed................: 0.00%  0 out of 534
    http_reqs......................: 534    22.42026/s

    EXECUTION
    dropped_iterations.............: 260    10.916231/s
    iteration_duration.............: avg=4.06s min=1.17s   med=4.28s    max=5.91s p(90)=5.21s p(95)=5.54s
    iterations.....................: 267    11.21013/s
    vus............................: 16     min=3        max=60
    vus_max........................: 60     min=20       max=60

    NETWORK
    data_received..................: 152 kB 6.4 kB/s
    data_sent......................: 68 kB  2.8 kB/s



time="2026-10-10T04:36:23-03:00" level=error msg="thresholds on metrics 'http_req_duration, http_req_duration{name:booking}' have been crossed"
exit 99
```

**Dois xis, e o código de saída é 99**, o código que o k6 usa para limites ultrapassados. O
percentil 95 de todas as requisições foi de 127.01 ms para 2.71 s, e o das reservas de 134.14 ms
para 2.76 s. O `app.py` da aula 1 mostra por que as reservas são as que sofrem: ele segura uma
trava enquanto paga, então as reservas passam uma de cada vez, e trinta jornadas por segundo
mandam mais reservas do que uma de cada vez dá conta. A aula 9 mede essa trava.

Outras três linhas desta execução importam tanto quanto os xis.

- **O `http_req_failed` continuou aprovado, em 0.00%.** Toda requisição foi respondida certo, só
  que tarde. Uma resposta lenta não é um erro, e é exatamente por isso que o requisito precisa de
  um limite de tempo além de um limite de erro: só com o segundo, esta execução estaria verde.
- **Todos os checks também passaram**, 801 de 801. Os checks perguntaram se cada resposta estava
  certa, e cada uma estava. Certo e lento demais é uma falha que só um limite enxerga.
- **`dropped_iterations` é 260**, e o aviso no topo diz por quê: o cenário chegou ao seu `maxVUs`
  de 60, todos ocupados esperando uma reserva, e o k6 ficou sem ninguém para começar a próxima
  jornada. O teste pediu trinta jornadas por segundo e entregou 11.21013. **Uma execução que
  descarta iterações não aplicou a carga para a qual foi escrita**, então leia essa linha antes de
  qualquer percentil: estes números descrevem um teste mais leve que o pretendido.

## O que lê o código de saída

Num terminal, `$?` guarda o código de saída do último comando, e `&&` roda o próximo comando só se
ele foi 0: `k6 run -q k6/boxoffice.js && echo "release it"` imprime a mensagem só depois de uma
aprovação. Um job de pipeline funciona do mesmo jeito, e falha quando o seu passo sai com qualquer
coisa diferente de 0; a aula 11 põe este script num pipeline e mantém os limites como orçamento de
desempenho.

Um limite também consegue parar uma execução antes da hora. Escrito como objeto,
`http_req_duration: [{ threshold: 'p(95)<200', abortOnFail: true }]`, ele faz o k6 parar o teste
assim que o limite é ultrapassado, em vez de carregar um sistema por mais dez minutos depois de o
veredito já ser conhecido. Essa forma não foi rodada aqui; toda execução desta aula dura os vinte
segundos inteiros.
