---
title: Meio aberto, e fechando de novo
version: 1
---

Um disjuntor aberto precisa descobrir, cedo ou tarde, se a dependência voltou. Ele não consegue fazer
isso sem chamá-la, e chamá-la a cada pedido desfaria o motivo de ter aberto. Então, depois da espera,
o disjuntor fica **meio aberto** (*half-open*): ele deixa passar **uma** chamada como teste, e recusa
o resto até essa chamada voltar. Se o teste der certo, o disjuntor fecha; se não, abre de novo por
mais uma espera.

Dez segundos depois de ele abrir, com o payments ainda lento, e depois com o payments de volta ao
normal:

```
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-10' localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 1.006760 s
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-11' localhost:8080/events/1/tickets
{"error": "payments unavailable"} 503 in 0.002606 s
ana@lab:~/tickets$ docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-12' localhost:8080/events/1/tickets
{"event": 1, "seat": 56, "code": "395c51a230ea1282"} 201 in 0.053180 s
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-13' localhost:8080/events/1/tickets
{"event": 1, "seat": 57, "code": "2abf4d857699c3df"} 201 in 0.039834 s
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep ^tickets_breaker
tickets_breaker_open 0.0
```

Leia em pares:

- **A primeira venda depois da espera foi o teste, e ele falhou** depois de um segundo, porque o
  payments ainda estava lento. O disjuntor abriu de novo na hora, então **a venda seguinte foi
  recusada em 2,6 ms**, sem um segundo teste.
- O payments recriado com o atraso normal, mais dez segundos, e **a venda seguinte foi de novo o
  teste, e deu certo**: um ingresso, em 53 ms. O disjuntor fechou, a venda depois dela passou
  normalmente em 40 ms, e o medidor voltou a 0.

Ninguém precisou perceber que o payments tinha voltado. Essa é a segunda metade do que um disjuntor
faz: ele se recupera sozinho, no ritmo de um teste por espera, e não de uma vez.

## Ajustando

- **Cinco seguidas** é a regra mais simples e a mais fácil de ler. Serviços movimentados costumam usar
  uma **taxa de falhas numa janela**, digamos mais de 50% de pelo menos 20 chamadas nos últimos dez
  segundos, para que uma chamada azarada entre milhares não pese muito e uma taxa constante de 30% de
  falhas ainda seja notada.
- **A espera** troca tempo de recuperação por carga num serviço doente. Dez segundos aqui; algumas
  bibliotecas a dobram depois de cada teste que falha, até um máximo.
- **Um disjuntor por dependência, por cópia.** A bilheteria guarda o disjuntor na memória, então cada
  uma de três cópias abre sozinha depois de cinco falhas suas. Ao contrário do limite de taxa, isso
  está certo: cada cópia está se protegendo, e não precisa combinar nada com as outras.
