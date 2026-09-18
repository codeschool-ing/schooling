---
title: Uma tabela, e tudo que pode dar errado nela
version: 1
---

A aula 1 terminou com um procedimento: nomeie as coisas, uma tabela cada, pergunte "vários?" nas
duas direções. Funciona, e é um hábito, não uma regra — então quando duas pessoas discordam sobre
um projeto, nenhuma delas consegue dizer quem está certo.

Normalização é esse conselho com uma prova anexada. Antes das regras, aqui está a tabela de que
elas tratam. Um sistema de matrículas, tudo num lugar só:

| enrolment_id | student_email | student_name | course_code | course_title | teacher | teacher_room | grade |
|---|---|---|---|---|---|---|---|
| 1 | ana@ex.com | Ana Lopes | SQL101 | Bancos de Dados | Reis | B-204 | 17 |
| 2 | bruno@ex.com | Bruno Sá | SQL101 | Bancos de Dados | Reis | B-204 | 14 |
| 3 | ana@ex.com | Ana Lopes | NET200 | Redes | Dias | A-110 | 15 |
| 4 | celia@ex.com | Célia Reis | SQL101 | Bancos de Dados | Reis | B-204 | 18 |

Toda pergunta feita a este sistema pode ser respondida a partir dela, e por um tempo nada dá
errado.

## Quatro coisas que podem dar errado, e elas têm nome

O propósito da normalização não é arrumação. É que uma tabela neste formato permite quatro
acidentes específicos, e uma tabela na terceira forma normal não permite. Aprenda os quatro e as
regras ficam óbvias em vez de decoradas.

**Anomalia de atualização.** A professora Reis muda para a sala B-310. Três linhas dizem `B-204` e
as três têm que mudar juntas. Mude duas e o banco passa a ter duas respostas para "onde a Reis dá
aula?", sem nada que diga qual é a certa. *Um fato, vários lugares, livres para discordar* — a
mesma falha do email da aula 1, e é a mesma porque é a mesma falha.

**Anomalia de inserção.** Um curso novo, CRY300, é criado e ninguém se matriculou ainda. Não há
onde colocá-lo. A linha da tabela é uma *matrícula*, então registrar um curso significa inventar um
aluno falso — ou esperar, e deixar a primeira matrícula trazer o curso à existência. Nenhuma das
duas é algo que alguém escolheu.

**Anomalia de exclusão.** A Ana tranca NET200 e a linha 3 é apagada. **O curso NET200 deixou de
existir**, junto com o fato de que a Dias o leciona e onde. Ninguém quis apagar um curso. Apagaram
uma matrícula, e um fato que só era guardado ao lado dela foi junto.

**Uma redundância que cresce.** `Bancos de Dados` está escrito três vezes, e será escrito uma vez
por matrícula para sempre. Isso é armazenamento, que é barato, e também são três chances de
digitar diferente, o que não é.

Os quatro vêm de uma coisa só, e vale dizer antes de qualquer definição formal:

> **A tabela é sobre mais de um tipo de coisa.** Uma linha é uma matrícula, um aluno, um curso e um
> professor ao mesmo tempo, então fatos sobre alunos, cursos e professores só podem ser guardados
> onde uma matrícula por acaso os coloca.

## O que a normalização de fato faz

Ela **decompõe**: divide uma tabela em várias, de modo que cada fato seja guardado uma vez, e faz
isso sem perder nada — a tabela original pode ser reconstruída juntando as peças de volta.

Essa última cláusula não é decoração. Uma divisão que perde informação não é normalização, é dano,
e as formas são definidas para que segui-las não possa causá-lo.

Três passos, cada um removendo um tipo de repetição:

| forma | remove | teste em uma linha |
|---|---|---|
| **1FN** | vários valores espremidos numa célula | toda célula tem um valor só? |
| **2FN** | fatos que dependem só de parte da chave | toda coluna precisa da chave *inteira*? |
| **3FN** | fatos que dependem de outra coluna comum | toda coluna depende da chave *diretamente*? |

Existe uma frase muito usada para as duas últimas, e é honestamente o melhor resumo que alguém
escreveu:

> **Toda coluna não-chave depende da chave, da chave inteira, e de nada além da chave.**

`da chave` é obra da 1FN. `da chave inteira` é a 2FN. `de nada além da chave` é a 3FN.

## O que esta aula não vai fazer

Não vai dar as definições de livro-texto primeiro e os exemplos depois. Essa ordem é a razão de a
maioria conseguir recitar "sem dependências parciais" e não conseguir usar.

Em vez disso, cada uma das três próximas seções pega a tabela acima e faz uma pergunta: **o que
pode dar errado aqui que não daria se fosse dividida?** As formas normais acabam sendo as
respostas. Você vai encontrar a definição formal no fim de cada seção, quando ela já será um nome
para algo que você viu, e não uma coisa para decorar.

E depois — porque é esta a metade que fica de fora da maioria do ensino — as últimas seções fazem o
oposto. Existem boas razões para quebrar a terceira forma normal de propósito, existe um teste para
saber se a sua é uma delas, e existe um caso que parece quebrá-la e não quebra.
