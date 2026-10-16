---
title: Cotas, custos e planos
version: 1
---

**Um limite de taxa e uma cota respondem a perguntas diferentes, e uma API normalmente precisa dos
dois.** O limite de taxa trata dos próximos segundos: quão rápido este cliente pode ir. A cota trata do
dia ou do mês: quanto ele pode usar no total. Um cliente que segue à risca uma requisição por segundo
nunca esvazia o balde, e manda 86.400 requisições por dia.

| | limite de taxa | cota |
|---|---|---|
| período | segundos ou minutos | um dia, um mês |
| protege | o serviço, agora | o orçamento, e o plano que o cliente pagou |
| reposição | contínua | toda de uma vez, quando o período recomeça |
| no `limits.py` | o balde, `burst` | uma janela fixa de um dia, `daily` |

O `limits.py` confere a cota antes do balde e só gasta dos dois quando os dois dizem sim, então uma
requisição recusada não custa nada de nenhum deles. A janela diária é fixa, e a fronteira dela não faz
mal: a cota de dois dias em sequência, atravessando a meia-noite, continua sendo a cota de dois dias.

## Nem toda requisição custa o mesmo

Ler um livro é uma consulta pela chave primária. Uma busca com `LIKE '%…%'` lê toda linha da tabela, e
com um milhão de livros em vez de seis é a coisa mais cara que a API faz. Um limite que conta
requisições cobra o mesmo das duas, então um cliente que só busca custa ao servidor muitas vezes o que a
contagem sugere.

**Um custo por endpoint resolve isso sem um segundo limitador.** O `limits.py` cobra cinco unidades por
busca, do mesmo balde e da mesma cota:

```
ana@api:~/shelf$ curl -s -H 'X-API-Key: demo-bia' 'localhost:8000/search?q=Cora'
[{"id": 4, "title": "Perto do Coração Selvagem"}]
ana@api:~/shelf$ python3 burst.py demo-bia '/search?q=a' 3
  0.00s  200  burst r=0  daily r=4990
  0.03s  429  burst r=0  daily r=4990  Retry-After: 5
  0.04s  429  burst r=0  daily r=4990  Retry-After: 5
```

A busca por `Cora` levou cinco fichas, e a primeira busca da rajada levou as outras cinco. Duas
requisições esvaziaram um balde de dez. As duas seguintes foram recusadas com `Retry-After: 5`, porque
cinco fichas a uma por segundo levam cinco segundos para voltar, onde uma requisição de custo um teria
ouvido `1`.

Quanto uma unidade deve pesar é um julgamento feito a partir de medição: o tempo que cada endpoint
leva, as linhas que lê, o dinheiro que gasta mais adiante. Uma API GraphQL leva a mesma ideia mais longe
e cobra cada consulta pelo que ela pede, o que a aula 3 levanta.

## Planos

Os números pertencem a um **plano**, e a chave diz qual. Isso torna o limite parte do produto: a chave
trial tem o mesmo balde que a free e uma cota de vinte unidades por dia, ou seja, quatro buscas.
Buscando uma vez a cada cinco segundos, o balde da chave trial nunca seca, então só a cota pode
pará-la:

```
ana@api:~/shelf$ python3 burst.py demo-ana '/search?q=a' 5 5
  0.00s  200  burst r=5  daily r=15
  5.00s  200  burst r=4  daily r=10
 10.00s  200  burst r=4  daily r=5
 15.00s  200  burst r=4  daily r=0
 20.00s  429  burst r=9  daily r=0  Retry-After: 69020
```

Quatro buscas gastaram as vinte unidades, e a quinta foi recusada com o balde tendo nove fichas
sobrando. O `Retry-After` agora é o tempo até a meia-noite UTC, em segundos. A recusa diz qual limite
foi, no corpo:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-ana' localhost:8000/books/1
HTTP/1.1 429 Too Many Requests
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:49:45 GMT
Content-Type: application/json
Content-Length: 51
RateLimit-Policy: "burst";q=10;w=10, "daily";q=20;w=86400
RateLimit: "burst";r=10;t=1, "daily";r=0;t=69015
Retry-After: 69015

{"error": "daily quota used up: retry in 69015 s"}
```

**As duas recusas trazem o mesmo status e conselhos diferentes.** "Too many requests: retry in 1 s"
diz a um programa para desacelerar. "Daily quota used up", com uma espera de quase um dia, diz a uma
pessoa para mudar de plano ou voltar amanhã, e um cliente que recua por horas sozinho precisa ser feito
para esperar isso. Algumas APIs respondem a uma cota esgotada com `403` em vez de `429`, e o rascunho que define o
`RateLimit` dá nome a um tipo de problema para isso, `quota-exceeded`. Qualquer que seja a escolha da
API, a resposta tem de distinguir as duas, em vez de deixar o cliente adivinhar pelo tamanho da espera.
