---
title: Lendo o resumo, linha a linha
version: 1
---

O resumo do fim do teste tem a mesma forma em toda execução, então vale lê-lo uma vez com calma.
Estas são as linhas da execução aprovada de "Limites, e o código de saída", na ordem em que o k6
as imprime, com os valores que essa execução imprimiu.

## Checks

| linha | o que conta |
|---|---|
| `checks_total: 162` | todo check avaliado: três por jornada, em 54 jornadas |
| `checks_succeeded: 100.00%` | a fração que passou, com a contagem ao lado |
| `✓ show answers 200` | uma linha por check, pelo nome que o script deu a ele; um xis quando algum falhou, com as contagens |

## HTTP

| linha | o que mede |
|---|---|
| `http_req_duration` | do primeiro byte da requisição enviado ao último byte da resposta recebido: o tempo de resposta de que o requisito fala |
| `{ expected_response:true }` | o mesmo, sobre as respostas que o callback de resposta chamou de esperadas: os tempos das requisições com falha ficam de fora |
| `{ name:booking }` | o mesmo, sobre as requisições com a tag `booking`. Aparece porque um limite a cita; uma tag que nenhum limite menciona não ganha linha própria |
| `http_req_failed: 0.00%` | a fração de respostas que não eram esperadas, 0 de 108 |
| `http_reqs: 108  4.974135/s` | as requisições enviadas, e quantas por segundo na execução inteira |

Cada linha de duração traz seis números: `avg`, `min`, `med`, `max`, `p(90)` e `p(95)`. A mediana
é o tempo abaixo do qual ficou metade das requisições, e `p(95)` o tempo abaixo do qual ficaram 95
de cada 100. **Leia `med` e `p(95)` antes de `avg`.** Para as reservas, a média foi 79.55 ms e a
mediana 71.86 ms, próximas aqui. Na execução reprovada, a média de todas as requisições foi 1 s
contra uma mediana de 112.02 ms: uma média que fica entre as páginas rápidas e as reservas lentas
e não descreve nenhuma das duas. A aula 8 é sobre o porquê.

A primeira execução desta aula imprimiu uma mediana de 27.68 ms e um percentil 95 de 62.09 ms para
o espetáculo 990, quando o `curl` da aula 1 via uns 17 ms e o `Server-Timing` dizia que o banco
ficava com quase todo esse tempo. **Numa conexão que o gerador de carga mantém aberta, uns 40 ms de
uma resposta podem ser gastos fora da aplicação**, e a aula 9 descobre onde.

## Execução e rede

| linha | o que diz |
|---|---|
| `iteration_duration: avg=2.06s` | uma jornada inteira: as duas requisições e o tempo de reflexão entre elas, de um a três segundos |
| `iterations: 54  2.487067/s` | jornadas terminadas, um pouco menos de três por segundo porque os primeiros cinco segundos sobem a partir de uma |
| `vus: 3  min=1  max=7` | usuários virtuais ocupados, na última amostra e ao longo da execução: no máximo 7 foram necessários ao mesmo tempo |
| `vus_max: 20` | usuários virtuais que o k6 tinha prontos, o `preAllocatedVUs` do cenário |
| `data_received`, `data_sent` | bytes pela rede em cada sentido, com a taxa |

**`max=7` contra `vus_max: 20` é a linha que diz que a execução foi saudável.** O k6 nunca ficou
sem usuários para começar uma jornada, então entregou a taxa de chegada que o cenário pediu, e não
há linha `dropped_iterations` nenhuma.

## Os grupos, e as fases de uma requisição

O resumo padrão deixa os grupos de fora. `--summary-mode=full` acrescenta um bloco para o cenário e
um para cada grupo, e cada um deles traz mais linhas sobre tempo. Rode o teste aprovado de novo com
ele, ficando só com os grupos:

```
ana@nft:~$ k6 run -q --summary-mode=full k6/boxoffice.js 2>&1 | sed -n '/GROUP: browse/,$p'
    ↳ GROUP: browse 

      checks_total.......: 110     5.105001/s
      checks_succeeded...: 100.00% 110 out of 110
      checks_failed......: 0.00%   0 out of 110

      ✓ show answers 200
      ✓ seats left is a number

      HTTP
      http_req_blocked...........: avg=163.54µs min=7.22µs  med=10.63µs  max=930.18µs p(90)=422.73µs p(95)=512.05µs
      http_req_connecting........: avg=109.12µs min=0s      med=0s       max=813.4µs  p(90)=291.78µs p(95)=333.62µs
      http_req_duration..........: avg=20.39ms  min=16.43ms med=18.42ms  max=46.86ms  p(90)=27.22ms  p(95)=31.64ms 
      http_req_failed............: 0.00% 0 out of 55
      http_req_receiving.........: avg=234.83µs min=89.25µs med=136.66µs max=2.96ms   p(90)=277.15µs p(95)=645.94µs
      http_req_sending...........: avg=66.43µs  min=21.22µs med=53.8µs   max=280.08µs p(90)=112.5µs  p(95)=126.21µs
      http_req_tls_handshaking...: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_waiting...........: avg=20.09ms  min=16.31ms med=18.23ms  max=46.34ms  p(90)=27.07ms  p(95)=31.4ms  
      http_reqs..................: 55    2.552501/s

    ↳ GROUP: book 

      checks_total.......: 55      2.552501/s
      checks_succeeded...: 100.00% 55 out of 55
      checks_failed......: 0.00%   0 out of 55

      ✓ booked or taken

      HTTP
      http_req_blocked...........: avg=11.35µs  min=7.43µs  med=9.72µs   max=48.55µs  p(90)=14.21µs  p(95)=17.02µs 
      http_req_connecting........: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_duration..........: avg=57.31ms  min=16.69ms med=61.73ms  max=122.57ms p(90)=70.77ms  p(95)=102.4ms 
      http_req_failed............: 0.00% 0 out of 55
      http_req_receiving.........: avg=144.3µs  min=82.01µs med=128.45µs max=378.48µs p(90)=187.65µs p(95)=280.21µs
      http_req_sending...........: avg=114.41µs min=28.47µs med=55.19µs  max=3.09ms   p(90)=82.29µs  p(95)=93.65µs 
      http_req_tls_handshaking...: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_waiting...........: avg=57.05ms  min=16.5ms  med=61.54ms  max=122.39ms p(90)=70.64ms  p(95)=102.06ms
      http_reqs..................: 55    2.552501/s
```

**O resumo completo divide `http_req_duration` nas suas fases.** `http_req_sending` é escrever a
requisição, `http_req_waiting` é esperar o primeiro byte da resposta, e `http_req_receiving` é ler
o resto; as três somadas dão a duração. `http_req_blocked`, `http_req_connecting` e
`http_req_tls_handshaking` vêm antes, enquanto o k6 acha ou abre uma conexão, e não fazem parte
dela. Aqui a espera é quase tudo em toda requisição: 20.09 ms dos 20.39 ms de média em `browse`, e
57.05 ms dos 57.31 ms em `book`, onde está o pagamento de 40 ms. Esse é o tempo do servidor, e a
aula 9 começa por ele.
