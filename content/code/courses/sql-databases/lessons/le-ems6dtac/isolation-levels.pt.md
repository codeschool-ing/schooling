---
title: Os quatro níveis de isolamento, e aquele em que você está
version: 1
---

O padrão define quatro níveis, e os define **por quais anomalias eles proíbem** em vez de por como
funcionam:

| nível | leitura suja | leitura não repetível | fantasma |
|---|---|---|---|
| `READ UNCOMMITTED` | possível | possível | possível |
| `READ COMMITTED` | impedida | possível | possível |
| `REPEATABLE READ` | impedida | impedida | possível |
| `SERIALIZABLE` | impedida | impedida | impedido |

É a tabela de todo livro-texto, e vale saber duas coisas sobre ela antes de usá-la.

**É um piso, não uma descrição.** Um nível diz o que um banco não pode permitir. Bancos
rotineiramente dão mais do que a linha exige, então dois bancos "no mesmo" nível se comportam
diferente.

**E atualização perdida e desvio de escrita não estão nela.** O padrão de 1992 nomeia três
anomalias, e as duas que você tem mais chance de encontrar numa aplicação não estão entre elas. Um
nível que proíbe tudo nesta tabela ainda pode deixar você perder uma atualização.

## Como definir

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- PostgreSQL
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;          -- antes das instruções, nos dois bancos
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;-- para toda transação desta conexão
```

E para descobrir onde você está, que é a instrução mais útil:

```sql
SHOW transaction_isolation;               -- PostgreSQL
SELECT @@transaction_isolation;           -- MySQL
```

## Os padrões não são iguais

**O PostgreSQL usa `READ COMMITTED` por padrão. O MySQL usa `REPEATABLE READ`.**

A mesma aplicação, implantada nos dois, roda em dois níveis diferentes — e um bug de concorrência
impossível num é rotina no outro, o que é um jeito genuinamente desagradável de descobrir isso.

## O que cada banco faz de fato

**PostgreSQL.** `READ UNCOMMITTED` existe como grafia e se comporta como `READ COMMITTED`: o
armazenamento guarda versões antigas da linha em vez de sobrescrever no lugar, então não existe
versão não confirmada para ler nem que você peça. Leitura suja não é uma coisa que possa acontecer
aqui.

`READ COMMITTED` dá a **cada instrução** uma visão nova do dado confirmado. É a explicação inteira
da leitura não repetível: duas instruções, duas visões.

`REPEATABLE READ` dá à **transação inteira** uma visão, tirada na primeira instrução. Isso impede
fantasmas também, o que é mais rigoroso do que a tabela exige, então o nível do meio do PostgreSQL é
isolamento por instantâneo e não o do padrão. Também significa que um `UPDATE` conflitante não pode
simplesmente esperar e seguir — a transação é abortada com *"could not serialize access due to
concurrent update"*, e espera-se que você a rode de novo.

`SERIALIZABLE` acrescenta o rastreio do que cada transação leu, e aborta uma de qualquer conjunto
cujo desfecho não poderia ter vindo de rodá-las uma depois da outra. É o único nível aqui que
impede desvio de escrita.

**MySQL com InnoDB.** O padrão `REPEATABLE READ` é baseado em instantâneo para leituras comuns, e
tem um comportamento que pega as pessoas: um `SELECT` simples lê o instantâneo, enquanto `UPDATE`,
`DELETE` e `SELECT … FOR UPDATE` leem a versão **confirmada mais recente**. Então uma transação pode
ler 10, atualizar a linha, e descobrir que escreveu a partir de um valor 12 que ela nunca viu.

Ele também toma bloqueios de intervalo — bloqueios no espaço entre entradas de índice — então uma
leitura com bloqueio nesse nível impede os inserts que seriam fantasmas. Isso o torna mais forte que
o padrão exige numa direção e mais fraco em outra, e é por isso que portar lógica de concorrência
entre MySQL e PostgreSQL merece uma leitura cuidadosa em vez de uma cópia.

**A Oracle** tem dois: `READ COMMITTED`, o padrão, e `SERIALIZABLE`, que é isolamento por
instantâneo e portanto permite desvio de escrita apesar do nome. Ela não tem `REPEATABLE READ` nem
`READ UNCOMMITTED`.

**O SQLite** tem um escritor por vez, então é serializável por padrão, e a questão da concorrência
vira uma questão de vazão.

## Qual escolher

**`READ COMMITTED` para quase tudo.** É o padrão na maioria dos lugares por bons motivos: nunca
mostra trabalho não confirmado, nunca aborta a sua transação por conflito, e as anomalias que
permite são tratáveis onde importam.

**`REPEATABLE READ` quando uma transação lê o mesmo dado mais de uma vez** e as respostas precisam
concordar — um relatório de várias consultas, uma exportação, uma conciliação. Uma visão para a
transação inteira é exatamente o que está sendo pedido.

**`SERIALIZABLE` quando uma decisão depende de uma condição sobre linhas que não são as que você
escreve.** Esse é o formato do desvio de escrita, é a próxima seção, e escolher este nível é
escolher escrever um laço de repetição.

E **o nível não substitui uma restrição**. Um índice único impede duas linhas com o mesmo e-mail em
qualquer nível de isolamento, em qualquer banco, inclusive naquele que o seu colega está usando de
um script. Recorra à declaração primeiro e ao nível depois.
