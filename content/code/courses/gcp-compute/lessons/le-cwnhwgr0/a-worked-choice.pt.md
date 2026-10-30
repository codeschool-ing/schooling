---
title: Uma escolha resolvida para a loja
version: 1
---

A loja tem quatro peças de computação, e elas não querem todas a mesma resposta. **Escolher por
serviço é o ponto desta lição**: uma plataforma única para tudo é uma decisão sobre a equipe, às
vezes boa, e deve ser tomada como tal em vez de alcançada por omissão.

## O serviço de pedidos

O serviço orders da lição 8 é o que tem um perfil de verdade. Os logs, na média dos dias úteis
comuns, dão uma ou duas requisições por segundo à noite, uma subida a partir das 07:00, um platô de
35 a 40 das 09:00 às 16:00 e uma descida lenta pela noite. Escrito como 24 taxas e entregue ao
programa:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py orders=2,1,1,1,1,1,2,6,18,35,40,38,30,36,40,38,30,22,14,10,8,6,4,3
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
orders         42.38M           97.84           54.97           49.93          112.67

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

**42,38 milhões de requisições por mês, nenhuma hora ociosa e pico de 40.** A instância fica
ocupada a maior parte do dia e raramente vazia à noite, então o Cloud Run com cobrança por
instância é o mais barato, com 49,93, e o por requisição vem logo atrás, com 54,97. As duas
máquinas do Compute Engine custam o dobro e passam a maior parte do tempo paradas; o piso de dois
pods do Autopilot e a taxa do cluster custam mais ainda.

Agora a pergunta que toda escolha deve ouvir: e se der certo? Dez vezes o tráfego, o mesmo
formato:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py orders-x10=20,10,10,10,10,10,20,60,180,350,400,380,300,360,400,380,300,220,140,100,80,60,40,30
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
orders-x10     423.76M           97.84          301.69          104.03          153.17

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

Com dez vezes o volume, **duas máquinas `e2-standard-2`, a 97,84, ficam mais baratas que o Cloud
Run por instância, a 104,03**, porque as máquinas nunca estavam cheias antes e agora estão. A
cobrança por requisição ficou muito para trás, pagando a taxa sobre 424 milhões de requisições. A
escolha de hoje deve então ser o Cloud Run com cobrança por instância, anotada junto com o volume em
que ela será revista, perto de dez vezes o de hoje.

## Os outros três

- **O front-end web** serve páginas a pessoas. O perfil dele acompanha os clientes da loja, com
  noites calmas, e cabe no Cloud Run pelos mesmos motivos do orders. Ele divide com o serviço de
  pedidos o build, o registry (lição 21) e os hábitos de publicação.
- **O worker de fotos** gera miniaturas quando uma imagem chega. Ninguém o chama num horário; cada
  upload é um evento. Esse é o formato das funções do Cloud Run com um gatilho do Eventarc (lições 17
  e 18), e a conta dele acompanha os uploads, não as horas.
- **A exportação noturna** monta um relatório dos pedidos do dia e roda uns 20 minutos. Não é um
  serviço: começa, trabalha e para. Um job do Cloud Run, disparado pelo Cloud Scheduler (lições 10 e
  20), paga esses 20 minutos e nada mais.

## A decisão, anotada

| serviço | onde roda | por quê | rever quando |
|---|---|---|---|
| orders | Cloud Run, cobrança por instância | ocupado a maior parte do dia, escala até zero se um dia ficar quieto | o tráfego chegar a dez vezes o de hoje |
| web | Cloud Run | o mesmo formato do orders | o mesmo |
| worker de fotos | funções do Cloud Run, Eventarc | um evento por upload | uma miniatura levar mais que o limite da função |
| exportação noturna | job do Cloud Run, Cloud Scheduler | trabalho que termina | a exportação levar horas |

**Nada aqui roda no Compute Engine nem no GKE**, e isso é um resultado, não um princípio. Uma loja
com um serviço que precise de GPU, de uma conexão longa ou de um protocolo que não seja HTTP teria
uma linha que roda. A tabela é um registro de motivos, e a última coluna é a parte que a maioria
das equipes esquece: a condição em que os motivos deixam de valer.
