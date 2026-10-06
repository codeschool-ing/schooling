---
title: Onde a linha fica borrada
version: 1
---

A divisão não é absoluta, e três coisas que você vai encontrar na prática ficam em cima dela. Cada
uma resolve parte do problema e deixa o resto, e por isso nenhuma substituiu o warehouse.

## Uma réplica de leitura

O PostgreSQL consegue manter uma segunda cópia do banco, uma **réplica**, que repete cada mudança
que o primário faz, uma fração de segundo atrás. Os relatórios rodam na réplica e os caixas nem
percebem.

**Ela resolve a disputa por memória, disco e processadores** da seção 07, por completo. Não resolve
mais nada. A réplica tem o mesmo esquema normalizado, então o relatório ainda precisa de seis tabelas
e de um `coalesce`. Tem as mesmas linhas de estado atual, então o cliente 2123 continua no Paraná em
todo pedido que já fez. Uma réplica é o primeiro passo certo para uma rede pequena cujos relatórios
estão atrasando os caixas, e o último passo errado.

## Captura de mudanças

Em vez de copiar tabelas inteiras toda noite, uma ferramenta lê o próprio registro de mudanças do
banco, o write-ahead log no PostgreSQL, e envia cada insert, update e delete para outro lugar
conforme acontece. Isso é **change data capture**, CDC.

Ela muda *como* o warehouse é carregado: continuamente, e com cada estado intermediário de uma
linha, inclusive a cidade antiga antes do update. Isso a torna a melhor fonte que um warehouse pode
ter para o histórico. Não muda *o que* o warehouse é, e é em `pipelines-etl` que ela é construída.

## Um motor para as duas coisas

Alguns bancos dizem fazer as duas cargas ao mesmo tempo: **HTAP**, processamento híbrido
transacional e analítico. Em geral guardam os dados duas vezes dentro de um produto, uma por linha
para as transações e outra por coluna para a análise, e mantêm as duas em sincronia por conta
própria. O SingleStore e o TiDB são feitos assim, e a cópia colunar que a lição 8 mede é a ideia por
baixo.

**O que o HTAP remove é o pipeline entre dois bancos. O que ele não consegue remover é o modelo.** Um
cliente que se mudou continua sendo uma linha, e um relatório ainda precisa saber o que receita
significa. O modelo dimensional das lições 2 a 5 é uma decisão sobre *significado*, e é necessário
onde quer que os dados morem fisicamente.
