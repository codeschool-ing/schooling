---
title: Primeira forma normal: um valor por célula
version: 1
---

A tabela de matrículas de duas seções atrás já está na primeira forma normal, o que faz dela um
exemplo ruim. Então aqui está o formato que a 1FN proíbe, e é o que as pessoas de fato escrevem:

| enrolment_id | student_email | courses | grades |
|---|---|---|---|
| 1 | ana@ex.com | SQL101, NET200 | 17, 15 |
| 2 | bruno@ex.com | SQL101 | 14 |

Uma linha por aluno, com os cursos numa lista. É compacto, lê bem, e cada coisa nisso é um
problema.

## O que dá errado

**Achar qualquer coisa significa procurar dentro de texto.** "Quem faz SQL101?" vira uma busca
pelos caracteres `SQL101` dentro de uma string, que também casa com um curso chamado `SQL1010`. Não
há noção de valor inteiro para comparar, porque o valor não é inteiro.

**As duas listas são unidas por posição e nada garante isso.** `17` é a nota de SQL101 da Ana
porque é a primeira de uma lista e SQL101 é o primeiro da outra. Insira um curso no meio de uma
lista e esqueça a outra, e toda nota depois dela passa a pertencer ao curso errado. Nada reclama.
É a mesma falha que o formato de conteúdo deste repositório recusa — *nada se une por posição* — e
é por isso.

**Acrescentar um curso significa reescrever uma string.** Ler a linha, acrescentar, escrever de
volta. Duas matrículas no mesmo segundo e uma se perde.

**Nenhuma restrição alcança lá dentro.** `REFERENCES courses (code)` não pode ser declarado sobre
um fragmento de string, então nada garante que `NET200` é um curso que existe. A ferramenta mais
forte da aula 1 simplesmente não está disponível.

**Sem tipo.** `17, 15` é texto. Não pode ser somado, comparado nem promediado sem ser desmontado
antes, e desmontar é algo que alguém tem que escrever corretamente toda vez.

## O conserto, e é o único

Cada valor ganha a própria linha:

```sql
CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email),
    course_code   text NOT NULL REFERENCES courses  (code),
    grade         integer,
    PRIMARY KEY (student_email, course_code)
);
```

| student_email | course_code | grade |
|---|---|---|
| ana@ex.com | SQL101 | 17 |
| ana@ex.com | NET200 | 15 |
| bruno@ex.com | SQL101 | 14 |

Todo problema acima sumiu, e nenhum deles foi endereçado individualmente. `WHERE course_code =
'SQL101'` compara valores inteiros. A nota fica na linha a que pertence, então nada é casado por
posição. Uma matrícula nova é um `INSERT` que não pode perder outro. As duas referências são
declaráveis e impostas. `grade` é inteiro e pode ser promediado.

**E a chave primária é o par**, que é a tabela de ligação da aula 1 chegando com outro nome. Um
muitos-para-muitos entre alunos e cursos precisa de uma terceira tabela; que ela também seja o que
a 1FN produz a partir de uma lista numa célula não é coincidência, porque uma lista numa célula é
um muitos-para-muitos que alguém tentou não modelar.

## O enunciado formal, agora que você já viu

> **Uma tabela está na primeira forma normal quando toda célula guarda um valor único e
> indivisível, e não há grupos repetidos de colunas.**

A segunda metade nomeia o outro jeito de quebrá-la, que é uma coluna por item:

| student_email | course_1 | grade_1 | course_2 | grade_2 | course_3 | grade_3 |
|---|---|---|---|---|---|---|

É a mesma falha vestida de estrutura, e a aula 1 já deu o teste: **dados crescem em linhas,
estrutura cresce em colunas.** Um aluno fazendo um quarto curso precisaria de um `ALTER TABLE`, que
é o sinal. Também desperdiça as colunas que ninguém usa, faz "quais alunos fazem SQL101" virar uma
busca em três colunas, e não te dá como dizer que um aluno não pode se matricular duas vezes no
mesmo curso.

## Onde "indivisível" é discutido

Duas complicações honestas, porque a 1FN é onde o livro-texto e o banco de dados real mais
discordam.

**Um nome completo numa coluna.** `'Ana Lopes'` é um valor ou dois? Depende de algo no seu sistema
alguma vez precisar das partes separadas. Se você ordena por sobrenome, ou chama as pessoas pelo
primeiro nome, são dois fatos numa coluna e deveriam ser duas colunas. Se você só imprime, é um
valor. **A pergunta não é "pode ser dividido" — tudo pode. É "alguma coisa precisa das partes?"**

**Arrays e colunas JSON.** PostgreSQL tem `text[]` e `jsonb`, e eles guardam vários valores numa
célula por projeto. Uma leitura estrita diz que quebram a 1FN, e a leitura estrita está certa sobre
o que custam: nenhuma chave estrangeira para um elemento, restrições mais fracas, e consultas que
precisam de operadores especiais.

Ainda assim às vezes são corretos — para um blob genuinamente opaco, para um payload da API de
outra pessoa que você guarda como chegou, para um conjunto de rótulos a que nada se junta. O que
os torna erro é usar um para evitar criar uma tabela para algo que é uma coisa no seu sistema. Se
você algum dia quiser perguntar "quantos alunos fazem cada curso", os cursos eram uma tabela.

A regra que sobrevive: **busque uma tabela primeiro, e use um array quando você conseguir dizer o
que está abrindo mão.**
