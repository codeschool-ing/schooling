---
title: Decisões se perdem
version: 1
---

Toda aula deste curso terminou numa decisão: perguntar ao serviço de estoque ou escutá-lo, replicar de
forma síncrona ou não, orquestrar o checkout ou deixá-lo coreografado. Cada uma veio com motivos, e cada
motivo dependia de fatos sobre a Quitanda naquele momento: o tráfego, a equipe, o dinheiro.

Um ano depois as decisões continuam no código e os motivos não. A pessoa que as defendeu mudou de equipe;
a reunião não foi registrada; a conversa no chat está mil mensagens acima. O que as pessoas novas veem é um
sistema que faz uma coisa estranha, e elas fazem uma de duas coisas, as duas ruins. **Deixam como está**,
porque pode importar, e o sistema acumula decisões que ninguém consegue explicar. Ou **mudam**, porque
parece errado, e redescobrem o motivo do jeito difícil.

Michael Nygard propôs um remédio em 2011, num texto curto chamado *Documenting Architecture Decisions*, e
ele virou o padrão: um **registro de decisão de arquitetura**, ou ADR (*architecture decision record*). Um
arquivo de texto curto por decisão significativa, escrito quando a decisão é tomada, guardado no
repositório ao lado do código que ele explica, numerado em ordem, e nunca reescrito. O conjunto é o
**log de decisões**.

Nem toda escolha precisa de um. Uma decisão é **significativa para a arquitetura** quando é cara de mudar
depois ou molda o que muitas outras decisões podem ser:

| merece um registro | não merece |
| --- | --- |
| separar o módulo de estoque num serviço | o nome de uma função |
| PostgreSQL em vez de um banco de documentos | que linter rodar |
| entrega pelo menos uma vez com consumidores idempotentes | a ordem dos campos numa resposta JSON |
| um API gateway na frente de todo serviço | a versão menor de uma dependência |

A aula 1 deste curso definiu arquitetura como as decisões que são caras de mudar. Os ADRs são onde essas
decisões ficam guardadas.
