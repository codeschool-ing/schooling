---
title: Três tipos de requisito, e o que a arquitetura mais escuta
version: 1
---

**Um requisito é qualquer coisa que o sistema precisa fazer ou ser, e há três tipos: requisitos
funcionais, atributos de qualidade e restrições.** A aula 7 de `architecture-role` separou os três e
mostrou como pedir cada um ao negócio. Esta aula é sobre registrá-los como modelos: numa forma
precisa o bastante para ser conferida, priorizada e rastreada até as decisões que a atendem.

| tipo | o que diz | um exemplo da Carcará |
| --- | --- | --- |
| **funcional** | o que o sistema faz | *um passageiro pode cancelar uma passagem paga até três horas antes da partida e receber o reembolso integral* |
| **atributo de qualidade** | quão bem ele faz | *o motorista consegue conferir uma passagem em menos de um segundo, sem sinal* |
| **restrição** | uma decisão já tomada por outra pessoa | *dados pessoais ficam no Brasil (LGPD e a política da empresa)*; *a Frota não pode ser modificada* |

O nome mais antigo dos atributos de qualidade é **requisitos não funcionais**. Ele ainda aparece em
vagas de emprego e editais, e é um nome ruim: disponibilidade e segurança têm tudo a ver com função,
e chamá-las de *não funcionais* faz parecer que são opcionais. Este curso usa *atributos de
qualidade*, e o título da aula traz os dois para você reconhecer qualquer um.

## Por que a arquitetura escuta as qualidades

Os requisitos funcionais decidem **o que o sistema contém**. Os atributos de qualidade decidem
**como ele é construído**, e esse é o trabalho do arquiteto. Pegue uma funcionalidade, *conferir a
passagem na porta*, e dois requisitos de qualidade para ela:

- *a conferência funciona sem sinal*: a lista de passagens tem de morar no celular, o que significa
  um processo de sincronização, um formato publicado e uma regra para passagens vendidas depois da
  última sincronização (o mapa da aula 4);
- *uma passagem cancelada é recusada na porta em até um minuto depois do cancelamento*: o celular
  tem de saber dos cancelamentos quase na hora, e isso precisa de sinal.

Os dois são razoáveis, e **eles puxam um contra o outro**. Nenhum trabalho na funcionalidade resolve
isso; é uma decisão sobre qualidades, e Celeste tem de tomá-la com os custos na frente dela. O resto
desta aula constrói as ferramentas que põem esses custos na frente dela: um catálogo para nenhuma
qualidade ser esquecida, cenários para cada uma poder ser conferida e uma árvore para priorizá-las.

## Requisitos arquiteturalmente significativos

Nem todo requisito molda a arquitetura. *O e-mail da passagem mostra o logotipo da empresa de
ônibus* muda um template. Um requisito é **arquiteturalmente significativo** quando atendê-lo, ou
mudá-lo depois, mudaria a estrutura: onde os dados moram, o que fala com o quê, o que roda onde. A
Carcará tem algumas centenas de requisitos e uns quinze significativos. Achar esses quinze cedo é o
objetivo de tudo o que vem a seguir.
