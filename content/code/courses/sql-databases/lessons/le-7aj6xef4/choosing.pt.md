---
title: Escolher, e como isso acontece pouco
version: 1
---

Comece pela parte que ninguém diz em voz alta: **a maioria dos desenvolvedores nunca escolhe um
motor de banco de dados.** Você entra numa empresa e ele já está lá, com dez anos de dados dentro.
A habilidade útil é saber o que faz aquele que está na sua frente, e não qual você teria escolhido.

Então esta seção tem duas metades. A escolha, para as poucas vezes em que ela é sua, e o que fazer
quando não é.

## Quando é sua

**SQLite quando há um escritor e uma máquina.** Uma aplicação de desktop ou celular, uma ferramenta
de linha de comando com estado, uma suíte de testes, um dispositivo embarcado, um site de muita
leitura num servidor só, um conjunto de dados que você distribui. Escreva `STRICT` em toda tabela e
guarde dinheiro em centavos. Pare quando uma segunda máquina precisar escrever.

**PostgreSQL quando você não tem um motivo forte para outra coisa.** As seções sobre rigor são o
argumento: ele recusa o insert ruim, recusa o `GROUP BY` ambíguo, mantém decimais exatos, compara
texto do jeito que você escreveu, e põe o DDL dentro das suas transações. Cada uma dessas é uma
classe de bug que não consegue chegar em produção. Ele também tem o conjunto mais largo de tipos —
arrays, `jsonb`, ranges, geometria via PostGIS — e o mecanismo de extensões que os outros não têm.

**MySQL ou MariaDB quando algo apontar para eles.** O time os conhece. A hospedagem é mais barata
ou é a única oferecida. A aplicação que você vai implantar — WordPress, boa parte do software em
PHP — é escrita para eles. Galera ou Group Replication é a forma de que você precisa. Esses são
motivos de verdade e são os motivos pelos quais a maioria dos sistemas MySQL existe.

**E um motivo que não é um:** *"ele é mais rápido"*. Benchmarks entre estes motores em cargas
comuns de aplicação são próximos o bastante para a diferença ser menor que um índice faltando, e a
aula 9 é onde esses moram. O benchmark de alguém, de 2012, é a entrada menos útil para esta decisão.

## Quando não é sua

Que é a maior parte do tempo, e as perguntas são curtas:

**Qual motor e qual versão.** `SELECT version()` no PostgreSQL, `SELECT VERSION()` no MySQL e no
MariaDB, `SELECT sqlite_version()` no SQLite. A versão decide se funções de janela e CTEs existem,
se `RETURNING` existe, e metade do conselho que você vai achar na internet.

**Qual é o `sql_mode`, no MySQL ou no MariaDB.** Duas linhas de saída que dizem se o motor recusa um
valor ruim e um `GROUP BY` ambíguo, ou aceita os dois. Esta é a pergunta de maior valor da lista.

**Qual é a collation.** Se o `UNIQUE` sobre um endereço significa o que você acha, e se uma
comparação que você está prestes a escrever é sensível a caixa.

**Se as chaves estrangeiras são exigidas.** Sempre são no PostgreSQL e no InnoDB do MySQL. No
SQLite elas são **desligadas por padrão** — `PRAGMA foreign_keys = ON` por conexão, e um banco em
que se escreveu sem isso pode já conter linhas que apontam para nada.

Quatro perguntas, quatro comandos, e eles mudam como você lê toda tabela do esquema.

## O que atravessa, seja qual for a resposta

Olhe para o que esta aula de fato encontrou. As diferenças eram reais e nenhuma delas era sobre o
assunto deste curso. O modelo relacional não se mexeu. Uma junção não se mexeu. O `GROUP BY` se
mexeu apenas em com que rigor é fiscalizado. Transações mantiveram o significado; índices
mantiveram o deles; o plano manteve o seu.

> **O motor decide o que é recusado, como o texto é comparado, e como ele é operado. Ele não decide
> o que é uma consulta correta.** As aulas 1 a 11 são o mesmo assunto nos quatro, e no quinto
> também.

É o mesmo ponto que a aula 11 fez sobre ORMs, uma camada abaixo. O mapeador não é um jeito de não
precisar saber SQL, e o motor não é um jeito de não precisar saber o modelo. **As ferramentas
mudam; as perguntas não.**

Existe um quinto motor, e ele não cabe nesta comparação — não por faltarem recursos, mas porque o
que ele custa e como é comprado mudam a forma dos sistemas construídos sobre ele. A aula 13 é sobre
o Oracle e o mundo em que ele vive.
