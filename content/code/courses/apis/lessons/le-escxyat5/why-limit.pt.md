---
title: Por que limitar
version: 1
---

**Um limite de taxa é uma promessa sobre quanto um cliente pode pedir, cumprida pelo servidor.** Ele
diz, para cada cliente, quantas requisições em quanto tempo, e o que acontece com a que passa da
linha: ela é recusada com `429 Too Many Requests`, e a resposta diz quando tentar de novo.

A imagem com que a maioria chega é a de um muro contra atacantes. Isso é parte da história, e a
parte menor. O cliente que manda dez mil requisições por minuto costuma ser um programa de alguém:
um laço com a condição de saída errada, um app de celular repetindo toda falha de uma vez, um script
que um cliente deixou rodando no fim de semana. Nenhum deles quer fazer mal, e cada um consegue
derrubar o serviço para todos os outros do mesmo jeito.

Nada no `rest.py` impede nada disso. Cem requisições, uma depois da outra, num laço do shell:

```
ana@api:~/shelf$ time (for i in $(seq 100); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/v1/books; done | sort | uniq -c)
    100 200

real	0m1.878s
user	0m0.500s
sys	0m0.422s
```

Cem respostas e cem `200`. Seis livros são baratos de ler; uma busca em um milhão de linhas, um PDF
gerado na hora ou uma mensagem de texto enviada por um provedor que cobra por mensagem não são, e o
laço é o mesmo, três linhas.

## Para que serve um limite

São três motivos, e eles decidem números diferentes:

| motivo | o que dá errado sem limite | em que o limite é medido |
|---|---|---|
| **proteger o serviço** | um cliente ocupa as threads, as conexões com o banco ou a memória, e as requisições de todo mundo ficam lentas ou falham | requisições por segundo, e quantas podem rodar ao mesmo tempo |
| **justiça entre clientes** | quem pede mais rápido leva mais serviço, seja lá o que tenha pago | uma cota de uso por cliente, não uma para a API inteira |
| **custo** | cada requisição gasta dinheiro: processamento, tráfego de saída, uma API paga chamada por trás | uma cota por dia ou por mês, muitas vezes por plano |

A segunda linha é o motivo de o limite desta lição ser **por cliente**. Um contador único para a API
inteira protege o servidor e mais nada: quando um cliente ocupado o esgota, todos os outros também são
recusados, e quem causou o problema derrubou todo mundo com educação em vez de sem ela.

## O nome que a OWASP dá ao limite que falta

O OWASP API Security Top 10 é uma lista dos jeitos como APIs são de fato quebradas, e a edição de 2023
chama este de **API4:2023, Unrestricted Resource Consumption** (consumo irrestrito de recursos). Os
exemplos dela vão além de requisições por segundo: nenhum teto para o tamanho de um upload, para
quantos registros uma página devolve, para quantas operações uma requisição pode juntar, para a memória
ou o tempo que uma requisição pode gastar, e nenhum limite de gasto num serviço de terceiros que a API
chama a cada requisição. A última seção desta lição volta a eles. A lição 13 percorre o resto da lista.

Um limite faz um segundo trabalho que é fácil de não ver. **A recusa também é uma instrução.** Um
`429` com `Retry-After: 1` diz a um cliente bem escrito exatamente o que fazer, e os cabeçalhos de toda
resposta bem-sucedida dizem quão perto da linha ele está antes de chegar lá. Isso transforma o limite
de um muro em que os clientes batem numa velocidade que eles conseguem manter.
