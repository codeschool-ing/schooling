---
title: A venda das dez horas, como um número
version: 1
---

A aula 1 deu nome ao momento mais movimentado da bilheteria: um espetáculo concorrido, 300 lugares,
abrindo as vendas às 10:00. Aqui ele vira um número de requisições por segundo. **A aritmética é
curta; o trabalho está nas suposições**, e elas vão para o plano de teste ao lado do resultado, para
que quem souber melhor possa corrigir uma delas e o número acompanhe.

## As suposições

Cada uma é um palpite com um motivo. Num sistema real, a venda do ano passado nos logs as substitui.

1. **Quem vem.** Quatro pessoas para cada lugar, 1.200 ao todo, e elas chegam no primeiro minuto,
   porque estavam esperando as 10:00. Isso é uma taxa de chegada de 1.200 / 60 = **20 pessoas por
   segundo**.
2. **O que cada uma pede.** A lista de espetáculos uma vez, a página do espetáculo três vezes (para
   abri-la, depois de escolher um assento, depois de saber que o assento foi tomado) e uma reserva.
   Cinco requisições por visita.
3. **Quanto tempo elas pensam.** Quatro segundos entre uma requisição e a próxima. Uma visita de
   cinco requisições tem quatro intervalos, então dura 4 × 4 = 16 segundos, mais respostas de algumas
   dezenas de milissegundos, pequenas o bastante para ficar de fora aqui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-sale\" aria-label=\"A venda das dez horas resolvida em caixas. 1.200 pessoas no primeiro minuto são 20 pessoas por segundo. Cada pessoa envia 5 requisições, então o site recebe 100 requisições por segundo: 20 para a lista de espetáculos, 60 para a página de um espetáculo e 20 para reservas. Cada visita dura 16 segundos, quatro intervalos de 4 segundos, então pela lei de Little 20 por segundo vezes 16 segundos são 320 pessoas no site ao mesmo tempo. Só para a página do espetáculo, 60 requisições por segundo vezes 4,02 segundos são cerca de 241 usuários virtuais.\"><defs><marker id=\"l03-sale-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1.200 pessoas</text><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no primeiro minuto</text><path d=\"M172.0 70.0 L210.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><rect x=\"212.0\" y=\"30.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"287.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">20 por segundo</text><text x=\"287.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pessoas chegando</text><path d=\"M364.0 70.0 L402.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"383.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">× 5</text><rect x=\"404.0\" y=\"30.0\" width=\"296.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">100 requisições por segundo</text><text x=\"552.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 GET /shows · 60 GET /shows/{id}</text><text x=\"552.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 POST /bookings</text><path d=\"M287.0 112.0 L287.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"297.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">× 16 s por visita</text><rect x=\"212.0\" y=\"152.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"287.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">320 pessoas</text><text x=\"287.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no site ao mesmo tempo</text><path d=\"M552.0 112.0 L552.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"562.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60 × 4.02 s</text><rect x=\"452.0\" y=\"152.0\" width=\"200.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">≈ 241 usuários virtuais</text><text x=\"552.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só para a página do espetáculo</text><text x=\"20.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">suposto: 4 pessoas por assento, 5 requisições por visita, 4 s de pensamento</text></svg>", "caption": "De uma multidão a uma taxa, e de uma taxa a um número de usuários. Mude uma suposição no alto e todas as caixas abaixo se movem.", "same": ["20 GET /shows · 60 GET /shows/{id}", "20 POST /bookings"]}
```

## Os números que vêm daí

**Requisições por segundo**: 20 pessoas por segundo × 5 requisições cada = **100 requisições por
segundo** no site todo. Por operação, são 20 por segundo para `GET /shows`, 60 por segundo para
`GET /shows/{id}` e 20 por segundo para `POST /bookings`. A divisão importa mais do que o total,
porque a página do espetáculo é a leitura cara e a reserva é a que segura uma trava.

**Pessoas no site ao mesmo tempo**, pela lei de Little: 20 chegando por segundo × 16 segundos cada =
**320 pessoas** no meio de uma visita em qualquer momento daquele minuto. É o número de que um teste
fechado precisaria como usuários virtuais para reproduzir a jornada inteira, com um tempo de
pensamento de 4 s.

**Usuários virtuais só para a página do espetáculo**: para oferecer 60 requisições por segundo com
4 s de pensamento e respostas de uns 20 ms, N = 60 × 4,02 ≈ **241 usuários**. É esse que esta aula
consegue conferir, com o `users.py` de duas seções atrás.

## Conferindo a página do espetáculo contra uma medida

Esta é a última rodada daquela seção, 240 usuários pensando quatro segundos cada, com rampa de dez
segundos e medidos durante vinte:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 240 4 10 20
240 users, think 4.0 s, ramp 10.0 s, measured for 20.0 s
requests 1197, errors 0
throughput X           59.9 requests/s
response time R        18.2 ms (mean)
in flight, counted      0.9 requests at a time
X × R                   1.1 requests at a time
X × (R + think)       240.5 users
```

**O modelo disse 60 requisições por segundo, e a bilheteria recebeu 59,9**, com um tempo médio de
resposta de 18,2 ms. A aritmética estava certa, e a suposição dentro dela de que o servidor
acompanha também. Nesta taxa ele acompanhou: 0,9 requisição em voo em média. A escada de estresse da
aula 2 quebrou a mesma página perto de 80 requisições por segundo, então os 60 da venda ficam
abaixo, com uma margem que mais uma suposição poderia comer: cinco pessoas por lugar em vez de quatro
são 75 por segundo.

## O que o número não diz

A média do minuto esconde os seus primeiros segundos. Quem estava esperando as 10:00 aperta o botão
às 10:00:00, então os primeiros dez segundos provavelmente carregam mais de um sexto das chegadas, e
o teste de carga da venda é o pico da aula 2, partindo deste número em vez de um palpite.

E as reservas acabam. Vinte por segundo para 300 lugares vendem o espetáculo em quinze segundos, se
cada reserva der certo na primeira tentativa. Depois disso todo `POST /bookings` é uma recusa rápida
com um `409`, e as pessoas que ainda estão chegando estão ouvindo que o espetáculo esgotou. **Isso
também é carga**, e o requisito deveria dizer com que rapidez elas ficam sabendo. Quantas reservas
por segundo a bilheteria consegue aceitar é uma pergunta que a aula 9 mede.
