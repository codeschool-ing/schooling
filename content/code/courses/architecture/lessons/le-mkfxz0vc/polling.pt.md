---
title: Polling e long polling
version: 1
---

O **polling** pergunta se há algo mais novo que o último evento que viu. Antes de qualquer coisa acontecer,
e depois de o armazém marcar o pedido o-1 como pago:

```
ana@vm:~/lab/live$ curl -s "localhost:8001/poll?since=0"; echo
[]
ana@vm:~/lab/live$ curl -s -X POST localhost:8001/publish -d "o-1 paid"
a: published
ana@vm:~/lab/live$ curl -s "localhost:8001/poll?since=0"; echo
["o-1 paid"]
```

A primeira pergunta não recebeu nada, e a maioria também não vai receber. Uma página que faz polling a cada
dois segundos manda 1.800 requisições por hora por aba aberta, e se o pedido mudar três vezes nessa hora,
1.797 foram desperdiçadas, cada uma uma requisição HTTP completa com cabeçalhos, cookies e uma passagem por
toda camada da loja. Ainda é uma boa resposta para **dados que mudam devagar e têm poucos observadores**,
um painel interno atualizado a cada minuto, porque não exige da infraestrutura nada além de HTTP comum.

O **long polling** faz a mesma pergunta e deixa o servidor esperar. Se não houver nada mais novo, o
servidor segura a requisição aberta até haver, ou por 25 segundos, e responde então. Peça qualquer coisa
depois do evento 1, e faça o armazém marcar o pedido como embalado dois segundos depois:

```
ana@vm:~/lab/live$ (sleep 2; curl -s -X POST localhost:8001/publish -d "o-1 packed" > /dev/null) & time curl -s "localhost:8001/long-poll?since=1"; echo
["o-1 packed"]
real	0m2.019s
user	0m0.004s
sys	0m0.019s
```

A requisição foi respondida **2,0 segundos** depois de enviada, no momento em que o evento chegou, e não no
próximo polling. O navegador então pergunta de novo na hora, e o ciclo se repete. Custa uma requisição
segurada por cliente esperando e mais ou menos uma requisição por evento, e funciona através de todo proxy
que permita a uma requisição levar 25 segundos. Era como o chat no navegador funcionava antes das
alternativas abaixo, e ainda é o plano B em bibliotecas como o Socket.IO quando nada melhor passa.
