---
title: Timeouts, a primeira guarda de toda chamada
version: 1
---

Toda guarda até aqui protege a bilheteria de quem a chama. As próximas duas a protegem do que ela
chama. Uma venda não termina até o payments responder, e **uma chamada sem prazo espera o quanto o
outro lado levar**: o `urlopen` do Python sem `timeout` espera para sempre. A aula 8 deu cinco
segundos à chamada; esta aula dá um.

Deixe o payments lento, cinco segundos por cobrança, e compre um ingresso:

```
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
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
ana@lab:~/tickets$ PAYMENTS_DELAY_MS=5000 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 1.026242 s
ana@lab:~/tickets$ sleep 12
ana@lab:~/tickets$ python3 trace.py
trace f6c754085051d13924a9513c9a6601d0
POST /events/{id}/tickets      tickets   at   0.0 ms  took 1023.8 ms
  charge                       tickets   at   4.9 ms  took 1018.1 ms
    POST /charges              payments  at  17.9 ms  took 5602.2 ms
```

O comprador recebeu um `502` depois de **1,03 segundo** em vez de esperar cinco. Agora leia o rastro.
O span `charge` da bilheteria terminou depois de 1018 ms, quando ela desistiu. O span do próprio
payments, no mesmo rastro, **levou 5602 ms**: ele continuou cobrando depois de a bilheteria ter
parado de escutar.

**Um timeout acaba com a espera, não com o trabalho.** O cartão foi cobrado e o comprador ouviu que o
pagamento falhou. Se deve tentar de novo, e como tentar de novo sem cobrar duas vezes, é exatamente o
assunto da aula 10; por enquanto, note que um timeout sempre deixa quem chamou sem saber se o
trabalho foi feito.

## Escolhendo um prazo

Um timeout tem dois lados a satisfazer:

- **acima do quanto a dependência costuma levar**, num percentil alto, ou o timeout derruba chamadas
  que teriam dado certo. O payments normalmente responde em 20 a 40 ms, então um segundo deixa uma
  margem larga;
- **abaixo do quanto quem chama vai esperar**, ou a resposta chega para ninguém. Um comprador olhando
  um indicador de carregamento desiste em segundos.

E ele tem um custo enquanto corre: **uma venda esperando o payments segura uma das 32 vagas** pelo
segundo inteiro. Com o payments travado, a bilheteria consegue completar no máximo 32 falhas lentas
por segundo, e todo outro pedido é descartado. Quando um pedido chama vários serviços em sequência, o
arranjo comum é um **prazo** (*deadline*) para o pedido inteiro, passado adiante, para que cada
chamada ganhe o que sobra dele em vez de um timeout cheio só dela.
