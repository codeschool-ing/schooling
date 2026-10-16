---
title: Planejando uma abertura de vendas
version: 1
---

Suponha que a Sabiá Ingressos ponha à venda um show de estádio às dez da manhã: 20.000 lugares, e o
último show desse tamanho trouxe cerca de 6.000 compradores no primeiro minuto. Um plano responde uma
pergunta: **quantas cópias da bilheteria, e o que mais precisa mudar, para que o primeiro minuto fique
abaixo de 70%?**

## O que uma cópia consegue

Meça, em vez de adivinhar. Uma cópia, o limite por comprador levantado, leituras e depois vendas:

```
ana@lab:~/tickets$ export BUYER_RATE=100000 BUYER_BURST=100000
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py 'http://localhost:8080/events/{event}' --events 50 -c 16 -d 10
requests  8990 in 10.0 s = 898.0 per second
latency   p50 14.2 ms  p95 41.5 ms  p99 61.8 ms  max 202.1 ms
status    200: 8990
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 16 -d 10
requests  1020 in 10.1 s = 101.2 per second
latency   p50 167.0 ms  p95 264.4 ms  p99 310.5 ms  max 410.4 ms
status    201: 998  409: 22
```

Uma cópia, uma CPU, responde cerca de **900 leituras por segundo** ou cerca de **100 vendas por
segundo**. Isso faz uma leitura custar cerca de 1,1 ms de CPU e uma venda cerca de 10 ms: a
assinatura, as consultas e a chamada ao payments. As 22 recusas foram para o show 7, que a seção 07
esgotou.

## O que o minuto pede

Suponha que os logs da última abertura digam que um comprador, no primeiro minuto, carrega a página
de um show umas 10 vezes e tenta comprar cerca de uma vez. Então 6.000 compradores em 60 segundos são:

| | por segundo | CPU de cada | CPU por segundo |
|---|---|---|---|
| leituras | 6.000 × 10 ÷ 60 = 1.000 | 1,1 ms | 1,1 s |
| vendas | 6.000 × 1 ÷ 60 = 100 | 10 ms | 1,0 s |
| total | | | **2,1 CPUs** |

## Da demanda às cópias

- **A 100% de ocupação**, 2,1 cópias bastariam. A seção 09 explica por que isso não é um plano.
- **A 70%**, 2,1 ÷ 0,7 = **3 cópias**.
- **Mais uma para falhas**: se uma cópia morre às 10:00:30, as outras três precisam carregar o minuto.
  Com 2,1 ÷ 3 = 70% elas conseguem. **4 cópias**, que é a regra chamada **N + 1**.

## O que mais o plano encontra

As cópias são a parte fácil. O plano precisa percorrer todo recurso que elas dividem:

- **Conexões com o banco.** 4 cópias × 32 vagas = 128 conexões, e o primário permite 100. O plano
  precisa mudar: 24 vagas por cópia dão 96, ou um agregador de conexões como o PgBouncer na frente do
  primário deixa muitas vagas dividirem poucas conexões.
- **O primário.** Toda venda é um `UPDATE` da linha do mesmo show, a linha quente da aula 1, que
  mediu o limite de uma linha em cerca de 138 vendas por segundo. 100 já está perto. Se 6.000 virar
  20.000, nenhum número de cópias ajuda, e a resposta é o particionamento dos lugares da aula 2 ou uma
  fila na frente da venda.
- **O payments.** 100 cobranças por segundo a 30 ms são 3 em andamento; o contrato com eles diz
  quantas aceitam, e esse número também faz parte do plano.
- **Os compradores que não entram.** 6.000 compradores para 20.000 lugares está bem. 60.000 não, e o
  plano então é a sala de espera da aula 9, decidida antes das dez horas em vez de durante.

## E depois verificar

Todo número acima é uma medida de uma cópia, multiplicada. Um plano é uma hipótese sobre como o
sistema inteiro se comporta sob a carga inteira, e o único jeito de testá-la antes das dez horas é
mandar a carga inteira. Essa é a aula 12.
