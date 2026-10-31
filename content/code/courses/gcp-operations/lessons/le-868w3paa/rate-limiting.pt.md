---
title: Limitação de taxa, e o banimento que vem depois
version: 1
---

**Um limite de taxa conta requisições por chave num intervalo e age sobre as que passam de um limite.** A regra
2000 da política da loja conta requisições a `/checkout` por endereço do cliente (`enforce_on_key = "IP"`), e deixa
passar as primeiras sessenta em qualquer minuto. Essa é a metade do estrangulamento. A outra metade é o **ban**:
`rate_based_ban` com `ban_duration_sec = 600` significa que um cliente que passa do limite é recusado com `429` por
dez minutos, mande o que mandar nesse tempo. Um throttle simples (`action = "throttle"`) recusaria só as
requisições acima da taxa e continuaria servindo o resto. Nada disso foi executado; é o mesmo plano.

## Escolhendo os números

Sessenta checkouts por minuto de um endereço é muito acima do que uma pessoa faz, e muito abaixo do que um script
testando números de cartões roubados faz. Esse é o propósito desta regra: **teste de cartões** (card testing), em
que um fraudador roda milhares de pagamentos pequenos para descobrir que cartões roubados ainda funcionam, e a loja
paga uma tarifa a cada tentativa. Os números vêm dos próprios logs da loja (as contagens por minuto da lição 10,
agrupadas por cliente), não de um palpite: a maior taxa legítima do último mês, com folga.

## A chave é a parte difícil

| `enforce_on_key` | conta por | o risco |
|---|---|---|
| `IP` | endereço do cliente | um escritório inteiro ou uma operadora móvel atrás de um endereço divide o limite |
| `HTTP_HEADER` | o valor de um cabeçalho que você nomeia, como uma chave de API | um cliente que omite o cabeçalho é contado sob uma chave vazia |
| `HTTP_COOKIE` | o valor de um cookie | um cookie é definido pelo cliente e pode ser mudado à vontade |
| `ALL` | tudo junto | um limite global, útil como último fusível |

A loja conta por endereço porque os clientes dela são pessoas em casa, um endereço cada. Uma loja que vende para
empresas acharia cem funcionários atrás de um endereço corporativo e baniria todos juntos; ali a chave seria a
sessão ou a conta do cliente.

## Vendo funcionar, sem o Google

O efeito de um limite de taxa aparece no log de requisições do balanceador, onde uma requisição recusada traz a
prioridade da regra e o resultado. A técnica da lição 10 se aplica: um contador baseado em log em
`jsonPayload.enforcedSecurityPolicy.outcome="DENY"`, dividido por prioridade, diz quantas requisições cada regra
recusou por minuto, e um salto repentino na regra 2000 é ou um ataque ou um limite baixo demais. De qualquer jeito,
alguém deve olhar, o que é um chamado na fila e não um chamado urgente (lição 14).
