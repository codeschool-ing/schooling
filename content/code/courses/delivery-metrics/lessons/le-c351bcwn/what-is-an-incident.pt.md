---
title: O que é um incidente, e por que declarar cedo
version: 1
---

As aulas 5 a 7 contaram falhas: um deploy falhou, o serviço foi restaurado, e um número entrou numa tabela. Esta parte do curso, as aulas 13 a 18, trata do que acontece **dentro** desse número: a hora entre algo quebrar e alguém dizer que está consertado, o documento escrito depois, a pessoa cujo telefone tocou.

## Uma definição de trabalho

Um **incidente** é um evento não planejado que prejudica, ou está prestes a prejudicar, as pessoas que usam o serviço, e que pede uma resposta coordenada agora. Cada parte dessa frase tem uma função:

- **não planejado**: uma janela de manutenção que corre como planejado não é um incidente;
- **prejudica os usuários**: um painel interno quebrado é um bug; cobranças de cartão falhando são um incidente;
- **coordenada**: mais de uma pessoa precisa agir, ou uma pessoa precisa que outras saibam;
- **agora**: não dá para esperar a próxima reunião de planejamento.

A definição deixa a causa de fora de propósito. Um incidente pode vir de um deploy, de um fornecedor, de um disco cheio ou de um pico de tráfego, e a resposta começa antes de alguém saber qual deles.

## Declare cedo, e faça isso ser barato

O hábito mais danoso na resposta a incidentes é **esperar ter certeza antes de declarar**. Alguém vê algo estranho, passa vinte minutos confirmando que é real e não um engano seu, depois mais dez decidindo se é "grande o bastante", e só então avisa alguém. A essa altura os usuários já estão sendo afetados há meia hora e ninguém está coordenando.

A correção é cultural e processual ao mesmo tempo:

- **Declarar tem de custar quase nada.** Um comando numa ferramenta de chat, um botão, uma mensagem num canal fixo. Se declarar exige um formulário e uma aprovação, as pessoas só vão fazer isso quando tiverem certeza.
- **Um alarme falso é um sucesso.** Um incidente declarado e fechado dez minutos depois como "não era real" custou dez minutos. Um incidente que só foi declarado quando ficou óbvio custou aos usuários todo o tempo em que não era óbvio.
- **Qualquer pessoa pode declarar.** Um atendente do suporte, um dev, uma gerente de produto. Quem vê primeiro raramente é quem é dono do sistema.

## O que declarar põe em movimento

Declarar um incidente é passar do trabalho normal para outro modo, com regras próprias, que as próximas três seções apresentam: **uma severidade**, que diz quanto do resto deve parar; **papéis**, para que quem está respondendo saiba quem decide e quem anota; e **um canal**, para que tudo o que se diz sobre o incidente seja dito num lugar só. Nada disso exige que alguém já saiba a causa, e é por isso que pode começar no primeiro minuto.
