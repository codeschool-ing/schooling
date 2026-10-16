---
title: O relatório, sem culpa
version: 1
---

Depois do incidente, o relatório pós-incidente transforma o que aconteceu no que muda. A forma dele é
fixa e vale a pena manter, porque um relatório que muda de formato toda vez é um relatório que ninguém
compara com o anterior:

```localised
Título      Pedidos falharam por 30 segundos: primário pg1 perdido
Data        ...
Autores     ...
Status      rascunho / revisado / ações concluídas

Resumo      Duas ou três frases: o que quebrou, por quanto tempo, o que os
            clientes viram.
Impacto     Medido: quanto tempo, quantas requisições ou pedidos falharam,
            quantos dados se perderam (o RPO de fato sofrido), quanto tempo
            levou a recuperação (o RTO de fato alcançado).
Linha do    Uma linha por evento, com a hora e a fonte.
tempo
Causas      O que fez acontecer, e o que fez ser tão grave quanto foi. Várias,
            em geral; "erro humano" nunca é uma delas sozinho.
O que deu   Coisas que funcionaram e devem ser mantidas.
certo
Ações       Cada uma é uma mudança, com responsável e data. "Ter mais cuidado"
            não é uma ação.
```

**Sem culpa** (blameless) significa que o relatório pergunta como o sistema deixou a ação razoável de
uma pessoa causar dano, nunca quem punir. As pessoas escondem o que fizeram quando vão ser culpadas
por isso, e um relatório só é tão bom quanto o que as pessoas estão dispostas a pôr nele.

A linha do tempo acima é montada na seção anterior a partir do que este incidente deixou no disco. As
ações, para um incidente como este, poderiam ser: fazer a contraparte real do `orders.sh` tentar de
novo com as regras da lição 19, para que trinta segundos de pedidos falhos virem trinta segundos de
pedidos lentos; adicionar um alerta para a troca de primário no HAProxy, para que uma pessoa saiba em
menos de um minuto, e não pela caixa de entrada do suporte do shop; e ensaiar o failover a cada
trimestre, que é a lição 23.
