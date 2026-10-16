---
title: Antes do dia de verdade
version: 1
---

Um teste de carga só é tão bom quanto a semelhança com o dia que ele ensaia. Algumas regras decidem
essa semelhança, e cada uma é um jeito como testes de carga já mentiram para alguém.

- **Testar algo com o formato da produção.** O mesmo número de cópias, os mesmos tamanhos de máquina,
  as mesmas configurações de banco e, acima de tudo, a mesma quantidade de dados: uma mudança de
  esquema que é instantânea em mil linhas leva segundos em dois milhões, como a aula 6 mediu.
- **Nunca testar a carga do sistema de outra pessoa.** O payments da bilheteria é um substituto que o
  laboratório controla; a API de produção de um provedor de pagamento de verdade não é alvo de teste,
  nem a de nenhum terceiro. Provedores oferecem ambientes de teste com os próprios limites de taxa, e
  um teste fica dentro deles ou troca o provedor por um substituto que responde como ele responde,
  lento e rápido, certo e errado.
- **Deixar o tráfego de teste reconhecível.** Ingressos vendidos por um teste de carga precisam ser
  fáceis de achar e remover, e nunca podem chegar à conta de um comprador de verdade, a um email de
  verdade ou a um relatório que alguém usa para decidir algo. Um cabeçalho, uma marca na conta, um
  show separado: decidido antes da primeira execução.
- **Testar a falha, não só a carga.** As aulas 9 a 11 construíram guardas e recuos; um teste de carga
  com uma réplica parada no meio, ou o payments desacelerado para um segundo, é o único jeito de saber
  que eles funcionam na carga para a qual foram construídos. Equipes que fazem isso de propósito, em
  produção, com todo mundo olhando, chamam isso de **dia de jogo** (*game day*); feito continuamente
  por um programa, é **engenharia do caos** (*chaos engineering*).

## O que o curso construiu

Doze aulas atrás a bilheteria era um programa e um banco, e uma linha quente a parava abaixo de 140
vendas por segundo. Desde então ela ganhou cópias e uma réplica, aprendeu para que serve cada tipo de
banco, mudou o esquema sem parar, contou o que faz em métricas, logs e rastros, se defendeu com
limites, descarte e um disjuntor, tentou de novo sem cobrar duas vezes, se degradou em vez de falhar,
e foi planejada e testada na carga de uma abertura de vendas.

Nenhum desses passos fez a bilheteria *escalar* sozinho. Cada um moveu um limite, mediu onde estava o
próximo, ou fez uma falha dizer o que era. Esse é o trabalho, e ele não acaba: o próximo limite é
sempre o que ninguém mediu ainda.
