---
title: ACID, com a versão honesta do C
version: 2
---

Quatro letras que se recitam bastante. Três delas são promessas que o banco faz, e uma é uma
promessa sobre você.

## A — atomicidade

**Todas as instruções da transação têm efeito, ou nenhuma tem.** É a seção anterior, e vale através
de uma queda: uma máquina que perde energia no meio de uma transação volta com a transação
desfeita, porque o banco anotou o que ia fazer antes de fazer.

O mecanismo tem um nome que você vai reencontrar nas aulas 9 e 10 — o log de escrita antecipada. As
mudanças vão para o log primeiro e para as tabelas depois, então uma recuperação consegue terminar
ou desfazer o que estava em andamento.

## C — consistência, que é a esquisita

A frase de sempre é *"uma transação leva o banco de um estado válido a outro"*. Leia com atenção e
faça a pergunta que ela está evitando: **válido segundo quem?**

Segundo as restrições que você declarou. Chaves estrangeiras, `NOT NULL`, `CHECK`, índices únicos —
as coisas de que a aula 3 tratava. O banco impõe essas, numa transação como em todo lugar.

Ele **não** sabe que o total de um pedido deveria ser igual à soma dos itens, nem que uma reserva
não deveria passar da capacidade de uma sala, a menos que você tenha escrito isso como restrição. Se
a regra vive só no código da aplicação, uma transação não a impõe, e nível de isolamento nenhum vai
impor.

Então a formulação honesta do C é:

> **O banco cumpre as promessas que você declarou. Ele não tem opinião sobre as que você não
> declarou.**

Que é por que esta letra é a que engana. Um time dizendo *"o banco é ACID, então nossos dados são
consistentes"* em geral escreveu a maior parte das regras numa camada de serviço, onde a letra não
alcança. O argumento da aula 3 — que uma restrição é a única regra de fato imposta — é o mesmo
argumento chegando por outro caminho.

## I — isolamento

**Quanto do trabalho inacabado de outra transação a sua consegue ver.** Esta é a que tem um botão,
ela tem quatro posições, e o resto desta aula trata delas.

A posição mais rigorosa se comporta como se as transações rodassem uma depois da outra sem
sobreposição. Também é a mais lenta e pode recusar a sua transação, que é por que não é o padrão em
lugar nenhum. Os padrões diferem entre bancos, e essa diferença muda o que a sua aplicação faz.

## D — durabilidade

**Depois que o `COMMIT` retorna, a mudança sobrevive a uma queda.** O banco escreve a entrada de log
em disco e espera o armazenamento dizer que ela está lá antes de o commit voltar para você.

Duas ressalvas honestas, porque esta é a letra com mais folclore grudado.

**Ela é tão boa quanto o que está embaixo.** Um disco que mente sobre ter descarregado — certo
hardware de consumo, certas máquinas virtuais, um sistema de arquivos montado com as opções erradas
— transforma durabilidade em esperança. O banco fez a parte dele e a confirmação era falsa.

**E ela é sobre esta máquina.** Se o primário confirma e depois pega fogo, uma réplica que ainda não
tinha recebido a mudança não a tem. Isso não viola a durabilidade; é a durabilidade querendo dizer o
que diz. Replicação síncrona é como se amplia isso para mais de uma máquina, e custa latência em
todo commit, que é uma troca que alguém tem que escolher de propósito.

## Dois bancos não são uma transação

O `BEGIN` cobre um banco. Escreva num banco e mande uma mensagem para uma fila, ou escreva em dois
bancos, e não existe `COMMIT` que cubra os dois:

```localised
BEGIN;
UPDATE accounts …;
   → manda "pagamento feito" para a fila de mensagens        ← fora da transação
COMMIT;                                                       ← e isto ainda pode falhar
```

Se o commit falhar depois de a mensagem ter sido mandada, a mensagem é mentira. Se a mensagem for
mandada depois do commit e o processo morrer no meio, ela nunca é mandada. Não existe ordem dessas
duas linhas que seja segura, e perceber isso é a maior parte da batalha.

As respostas de verdade são padrões e não uma palavra-chave: grave a mensagem numa tabela **dentro**
da transação e deixe um processo separado entregá-la, ou faça o lado que recebe tolerar ser avisado
duas vezes. Commit em duas fases existe e é um protocolo genuinamente distribuído com modos de falha
próprios, e não é algo a que se recorre por hábito.

## E o slogan sobre NoSQL

Vão lhe dizer que bancos relacionais são ACID e o resto não é. Era um resumo justo em 2010 e não é
uma descrição do cenário atual: vários bancos de documentos e de chave-valor hoje oferecem
transações de verdade, alguns sobre várias chaves, e algumas configurações relacionais abrem mão de
garantias de durabilidade por velocidade, de propósito.

O hábito útil não é perguntar se algo é ACID. É fazer as quatro perguntas separadamente — *o que
acontece se esta metade falhar, quais regras são de fato impostas, o que outra conexão consegue ver,
e o que sobrevive a uma queda de energia* — porque um produto responde a elas uma por vez, e um
arquivo de configuração também.
