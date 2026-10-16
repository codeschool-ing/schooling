---
title: Quando o outro banco ganha, com honestidade
version: 1
---

Um curso que termina recomendando o Postgres poderia ser lido como se as vinte e uma aulas
anteriores tivessem sido à toa. **Não foram, porque há casos em que cada um dos três é a resposta
melhor**, e cada um foi mostrado funcionando neste curso. O que segue é essa lista, cada caso ligado à
aula que o demonstrou, e cada um com o sinal de que você está nele.

## Redis, ao lado do banco principal

O Redis ganha como **um segundo banco para as operações que precisam de velocidade de memória e de
estruturas de dados**, com o banco principal ainda guardando a verdade:

| o caso | por que o Redis | aula |
|---|---|---|
| contadores, a milhares de incrementos por segundo numa chave | `INCR` é atômico e em memória; uma linha atualizada com essa frequência é uma trava em que todos fazem fila | 12 |
| limites de taxa | um contador com expiração é o algoritmo inteiro | 12, 14 |
| sessões | lidas a cada pedido, pequenas, descartáveis com um login como alternativa | 14 |
| rankings | um sorted set mantém a classificação ordenada enquanto as pontuações mudam | 12 |
| filas e fluxos de eventos entre serviços | listas, e streams com grupos de consumidores | 12 |
| um cache na frente do banco | políticas de expulsão feitas para isso | 14 |

O sinal de que você está nesse caso: **a operação é pequena, quente e perdoável**. A aula 13 mostrou
o que o Redis guarda depois de uma queda com cada tipo de persistência, e a aula 15 perdeu de
propósito uma escrita confirmada. Uma operação que aguenta essas perdas pertence aqui; uma que não
aguenta pertence ao banco que aguenta.

## Cassandra, quando as escritas passam de uma máquina ou de uma região

O Cassandra ganha com **um volume muito alto e constante de escritas, lidas de volta por chave e
tempo, em mais de um datacenter**: telemetria de dispositivos, eventos, mensagens, uma trilha de
auditoria numa escala em que um primário só não dá conta das escritas.

- **Volume de escrita**: todo nó recebe escritas, e acrescentar nós acrescenta capacidade (aula 16).
  É o primeiro item da lista da seção anterior, das coisas que o Postgres não faz tão bem.
- **Série temporal por chave**: uma partição por dispositivo e dia, agrupada por tempo, é a forma
  para a qual a aula 16 escreveu suas consultas.
- **Vários datacenters escrevendo ao mesmo tempo**: `LOCAL_QUORUM` em cada um, com replicação entre
  eles (aula 17). O segundo item daquela lista.

O sinal: **você consegue escrever todas as consultas antes da primeira tabela, e a lista não muda com
frequência**. As aulas 16 e 18 mostraram quanto custam uma consulta nova e um padrão cheio de
deletes; um sistema cujas perguntas ainda estão sendo descobertas paga esse preço todo mês.

## MongoDB, quando o documento é a unidade

O MongoDB ganha quando **a coisa lida e escrita é um documento inteiro, a forma dele varia entre
documentos, e transações entre documentos são a exceção**: um catálogo de produtos em que um monitor
e um cabo têm atributos diferentes, conteúdo com seções aninhadas, uma configuração por cliente.

- O documento é lido inteiro e escrito inteiro, então uma operação toca um lugar só (aula 6).
- Índices, agregação e um replica set estão lá quando a forma estiver assentada o bastante para
  precisar deles (aulas 7 a 9), e sharding quando o tamanho pedir (aula 10).

O sinal: **do contrário você guardaria uma coluna `jsonb` e quase não consultaria mais nada**. A
seção anterior mostrou o Postgres fazendo isso bem, então o argumento a favor do MongoDB é mais forte
quando os documentos são a aplicação inteira e a escala deles, ou a familiaridade da equipe com o
MongoDB, desempata, e não quando são uma tabela entre vinte.

## E o argumento para ficar

Se nenhum desses sinais é claramente verdadeiro, **a resposta honesta é o banco relacional que você
já opera**: um backup, um failover, um conjunto de habilidades de plantão, transações sobre tudo, e
as perguntas do ano que vem respondíveis com uma consulta que ninguém planejou. Isso não é falta de
ambição. É o que a tabela por operação da aula 1 diz para a maioria das operações da maioria das
aplicações.
