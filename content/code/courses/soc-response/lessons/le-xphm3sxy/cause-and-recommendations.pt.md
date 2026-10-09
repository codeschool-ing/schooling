---
title: Causa, e recomendações
version: 1
---

A seção de **causa** são os fatores contribuintes da aula 15, reescritos para leitores de fora da equipe. A mesma
regra sem culpa vale, e importa mais aqui, porque um relatório é lido por pessoas que podem querer alguém para
culpar:

> A invasão foi possível porque quatro condições existiam ao mesmo tempo. O servidor de acesso remoto aceitava
> senhas de qualquer endereço da internet, sem limite de tentativas. Alertas críticos chegavam a uma fila que ninguém
> olhava à noite. O servidor de arquivos conseguia mandar dados para qualquer endereço da internet. E não havia
> registro de quais chaves SSH deveriam existir, então uma chave adicionada durante a noite não teria como ser
> notada.

Nenhum nome aparece, e nenhum é necessário: cada condição é uma propriedade dos sistemas da empresa, e cada uma é
algo que a empresa pode mudar.

As **recomendações** saem das causas, uma ou mais por causa, e o relatório diz a qual causa cada uma responde. Elas
têm prioridade, e a prioridade é explicada pelo que cada uma teria mudado na quinta:

| prioridade | recomendação | responde a | na quinta, teria |
|---|---|---|---|
| 1 | acionar quem está de sobreaviso para alertas críticos, a qualquer hora | alertas que ninguém olhava | cortado a janela do invasor de 7 horas para minutos |
| 2 | acesso remoto só por chave, no padrão de instalação | senhas aceitas de qualquer lugar | impedido o primeiro login |
| 3 | servidores só alcançam os destinos de internet de que precisam | dados podiam ir para qualquer lugar | impedido a transferência |
| 4 | um inventário de chaves SSH, auditado diariamente | nenhum registro de quais chaves existem | sinalizado a chave nova de manhã |

Cada linha aponta para a lista de ações da aula 15, onde estão o dono e o prazo. **O relatório recomenda; o
postmortem acompanha.** Uma recomendação num relatório sem uma ação por trás é como o mesmo relatório acaba escrito de
novo um ano depois.
