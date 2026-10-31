---
title: Um SLI é uma razão de eventos bons, medida onde está quem usa
version: 1
---

**Um indicador de nível de serviço (SLI) é a fração dos eventos que foram bons, entre todos os eventos que
contaram.** Requisições boas entre todas as requisições; checkouts terminados em menos de um segundo entre todos
os checkouts. É uma razão entre 0 e 1, então se lê igual a quarenta requisições por minuto e a quatro mil, e é
escrita do lado de quem usa: o que alguém usando a loja chamaria de falha? A resposta é mais estreita que
"qualquer coisa que deu errado lá dentro" e mais larga que "o servidor devolveu 500".

O SLI errado é o fácil de medir. CPU a 90% não é uma falha que alguém sente; um checkout que levou oito segundos
é, diga a CPU o que disser. Uma réplica do banco atrasada só importa a quem usa se fizer o pedido sumir. Então os
indicadores da loja vêm das requisições, não das máquinas:

| SLI | evento bom | todos os eventos |
|---|---|---|
| disponibilidade | uma requisição respondida sem `5xx` | toda requisição ao `shop-api` |
| latência | um checkout respondido em menos de 1 segundo | todo checkout |
| atualidade | uma lista de preços com menos de 10 minutos quando lida | toda leitura da lista de preços |

## Escolhendo o que conta

Três decisões se escondem em cada linha, e cada uma muda o número:

- **Um `4xx` é bom?** Um `404` para um produto que não existe é a loja respondendo certo; um `429` do limitador
  de taxa da própria loja é a loja recusando um cliente. A loja conta `4xx` como bom, e a limitação de taxa da
  lição 16 é medida à parte.
- **Que requisições contam?** Os health checks da lição 8 também são requisições, e sempre têm sucesso.
  Contados, diluem toda falha; o filtro da loja é sobre o serviço, e as requisições do uptime check são uma
  fração pequena, mas um health check a cada segundo de muitos lugares não seria.
- **Onde é medido?** No balanceador de carga, uma requisição que nunca chegou à API porque a API caiu é contada
  como falha. Medida dentro da API, nem é contada, e o SLI parece perfeito durante uma queda. A loja mede na
  entrada do Cloud Run, que é o que `run.googleapis.com/request_count` é.

## Indicador, objetivo, acordo

| | o que é | para a loja |
|---|---|---|
| SLI | a razão medida | a fração de requisições sem `5xx` |
| SLO | a meta para ele, numa janela | 99,5% em 28 dias |
| SLA | uma promessa a clientes, com consequência | nenhum: a loja não vende garantia |

**Um SLO é interno e um SLA é um contrato**, e o SLO é mais apertado que qualquer SLA, para o time perceber que
está perdendo a própria meta muito antes de qualquer cliente ter algo a receber. 99,5% não é lei da natureza: é a
decisão da loja de que uma requisição falha em duzentas é aceitável e uma em cem não é, e é revista quando o
comportamento dos clientes disser outra coisa.
