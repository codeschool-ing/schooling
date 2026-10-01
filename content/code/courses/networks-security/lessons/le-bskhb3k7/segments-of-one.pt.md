---
title: Segmentos de um
version: 1
---

A aula 4 desenhou zonas e pôs um firewall entre elas, e encontrou nelas a falha: máquinas na mesma zona
se alcançam livremente. A **microssegmentação** (microsegmentation) leva a ideia até o fim:
cada carga de trabalho é o seu próprio segmento, e cada conexão entre duas cargas de trabalho, mesmo no
mesmo switch, é permitida por uma regra ou recusada.

Não dá para fazer isso só com o firewall central, porque o tráfego dentro de um segmento nunca passa
por ele. Isso é feito **em cada máquina**, com um firewall de host como os que as aulas 9 e 19
escreveram à mão, ou no switch virtual de um hipervisor, ou na política de rede de uma plataforma de
contêineres. O mecanismo muda; a política tem a mesma forma.

O que torna isso administrável é **escrever a política uma vez, por papel, e gerar a partir dela as
regras de cada máquina**. Ninguém mantém duzentos firewalls de host escritos à mão de forma consistente;
as pessoas mantêm uma tabela de quem pode falar com quem, e um programa escreve as regras. A regra da aula 19
para `db` foi escrita à mão. Esta aula a escreve a partir de uma política, para cada servidor, e aplica
o mesmo tipo de regra ao resto.

| | zonas (aula 4) | microssegmentação |
|---|---|---|
| a unidade | um segmento de muitas máquinas | uma carga de trabalho |
| aplicada por | o firewall entre segmentos | cada host, ou o hipervisor ao lado dele |
| escrita como | uma matriz de zonas | uma tabela de papéis |
| dentro de uma zona | aberto | fechado, a não ser que uma regra permita |
| o custo | uma política em uma caixa | uma política por carga de trabalho, que só a automação torna suportável |
