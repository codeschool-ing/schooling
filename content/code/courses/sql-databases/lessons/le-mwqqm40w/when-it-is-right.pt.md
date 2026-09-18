---
title: Quando é a resposta certa, e quando é inércia
version: 1
---

Esta aula passou a maior parte do tempo no que o Oracle custa e no que é estranho nele, então a
última seção deve um relato honesto do outro lado. Depois a pergunta que todo mundo numa
organização grande acaba fazendo, que é se deve sair.

## No que ele é genuinamente bom

**Ele faz isso há muito tempo, numa escala que poucas coisas fizeram.** Os sistemas de núcleo
bancário, os sistemas tributários nacionais, a cobrança de telefonia que não para desde os anos
noventa. Isso não é alegação de marketing; é uma base instalada com histórico, e para um sistema em
que errar é um evento regulatório, histórico vale pagar.

**Consistência de leitura sem vacuum.** O desenho de undo faz com que um relatório longo nunca
bloqueie e nunca veja uma mudança pela metade, e não há um processo de fundo recuperando versões
mortas de linha, que é uma classe real de trabalho operacional de PostgreSQL que aqui não existe. O
`ORA-01555` é o preço do desenho, e é um preço menor do que parece.

**Real Application Clusters.** Várias máquinas abrindo um banco, com failover entre elas, é uma
forma que os outros motores deste curso não têm. É caro e é complexo e para um número pequeno de
sistemas é a resposta.

**O contrato de suporte é uma coisa para a qual se liga.** Para uma organização cujo registro de
riscos tem uma linha "o banco está fora e ninguém sabe por quê", um fornecedor obrigado a responder
é parte do que se está comprando. Isso não é uma propriedade técnica e é real.

**E a ferramenta em volta é profunda.** Onde os pacotes são licenciados, o AWR, o ASH e os
assessores são melhores que qualquer coisa gratuita, e as pessoas que os conhecem são muito boas
nisso.

## Quando é inércia

**Quando a razão é que ele já está lá.** É uma razão de verdade para não migrar neste trimestre e
não é razão para pôr o *próximo* sistema nele.

**Quando os requisitos são comuns.** Um serviço novo com algumas centenas de gigabytes, alguns
milhares de transações por minuto e nenhuma necessidade exótica é um serviço PostgreSQL. Pô-lo no
Oracle corporativo porque a licença existe é a licença decidindo arquitetura de novo, na direção
que aumenta a conta.

**Quando ninguém sabe dizer quais opções são licenciadas.** Uma organização que perdeu o controle
disso carrega um risco que não está medindo, e isso é razão para descobrir e não para comprar mais.

## Migrar para fora

É feito, com frequência, e é um projeto com orçamento e não um fim de semana. O que custa não são
as tabelas — dados migram — é tudo que cresceu em volta delas.

| o que migra | quão difícil |
|---|---|
| o esquema e os dados | há ferramenta e essa parte é bastante mecânica |
| SQL comum | quase tudo portátil, e a lista da aula 12 é o diff |
| o dialeto | `DUAL`, `ROWNUM`, `NVL`, `SYSDATE`, junções externas com `(+)` — mecânico e tedioso |
| **a string vazia** | todo lugar em que a aplicação distinguia em branco de ausente, o que o Oracle nunca a deixou fazer |
| **os pacotes PL/SQL** | reescritos, na linguagem do destino ou na aplicação. Isto é o projeto |
| a prática operacional | os backups, o standby, o monitoramento e as pessoas, todos substituídos |

As duas linhas do meio são a resposta honesta a "quanto tempo". Um sistema com mil pacotes é um
sistema cuja lógica de negócio tem que ser reescrita e testada de novo, e não há ferramenta que faça
isso por você — os tradutores produzem algo que roda e que ninguém vai assinar embaixo.

**Existe um movimento intermediário que muitas vezes é o real:** parar de acrescentar. Serviços
novos vão para outra coisa, o sistema Oracle fica com o que tem, e a superfície encolhe ao longo de
anos em vez de numa migração. É menos satisfatório e é o que costuma acontecer.

## Com o que esta aula te deixa

Três coisas, e a primeira é a de levar para uma entrevista ou uma primeira semana.

**O motor não é o assunto.** Toda aula deste curso se aplica ao Oracle: o modelo, as chaves, as
junções, os agregados, as transações, os índices, o plano. A aula 12 disse que as ferramentas mudam
e as perguntas não, e esta aula é o caso mais forte disso. O motor mais diferente da lista, e a
diferença estava no contrato, no vocabulário e na operação, e não no que é uma consulta correta.

**Dinheiro é uma entrada de engenharia aqui, em voz alta.** Na maior parte deste curso as
restrições eram técnicas. No Oracle uma licença por núcleo e um pacote de diagnóstico cobrado à
parte decidem onde a lógica mora, quantos ambientes existem e o que alguém pode medir. Conseguir ler
uma decisão e enxergar o contrato por baixo dela é a maior parte do que torna alguém útil naquele
prédio.

**E a consulta continua sendo sua.** Você não vai escolher o motor, não vai guardar as credenciais,
e pode não ter permissão de rodar o relatório que diria qual consulta está lenta. O que você
escreve, e se você manda com variáveis de ligação dentro de uma transação curta depois de ler o
plano dela, está inteiramente nas suas mãos — e é a parte que decide a maior parte do que o sistema
faz.
