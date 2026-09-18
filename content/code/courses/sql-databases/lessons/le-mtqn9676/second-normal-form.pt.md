---
title: Segunda forma normal: a chave inteira
version: 1
---

A primeira forma normal nos levou a um valor por célula. Eis onde isso deixou as matrículas:

| student_email | course_code | student_name | course_title | grade |
|---|---|---|---|---|
| ana@ex.com | SQL101 | Ana Lopes | Bancos de Dados | 17 |
| ana@ex.com | NET200 | Ana Lopes | Redes | 15 |
| bruno@ex.com | SQL101 | Bruno Sá | Bancos de Dados | 14 |
| celia@ex.com | SQL101 | Célia Reis | Bancos de Dados | 18 |

A chave é o par `(student_email, course_code)`. Toda célula é um valor único. E `Ana Lopes` está
escrito duas vezes, `Bancos de Dados` três.

## A pergunta, antes da regra

Faça a pergunta que esta aula não para de fazer: **o que pode dar errado aqui que não daria se
fosse dividida?**

A Ana casa e muda de nome. Duas linhas guardam o nome. Mude uma e o banco guarda dois nomes para
uma aluna, e nada diz qual é o certo — porque nada nesta tabela registra que as duas linhas são uma
pessoa. Essa é a anomalia de atualização, e ela voltou.

Depois pergunte *por que* o nome se repete, e a resposta é precisa: **`student_name` depende só de
`student_email`, que é metade da chave.** As linhas da tabela são mais finas que o fato. Há uma
linha por (aluno, curso) e um nome por aluno, então o nome é escrito uma vez por curso que ela faz.

O mesmo para `course_title`, que depende só de `course_code` — a outra metade.

E `grade` é diferente, que é o caso de controle. Ela depende das duas metades: você não sabe a nota
pelo aluno, e não sabe pelo curso. `grade` está exatamente onde pertence.

## A regra

> **Uma tabela está na segunda forma normal quando está na 1FN e nenhuma coluna não-chave depende
> só de parte da chave.**

Uma dependência de parte da chave se chama **dependência parcial**, e a 2FN é a remoção de todas
elas.

**Só pode ser quebrada por uma chave composta.** Se a chave é uma coluna, nenhuma coluna pode
depender de "parte" dela — não há partes. Então uma tabela cuja chave é um id gerado está na 2FN
automaticamente, que é a maioria das tabelas, que é por que a 2FN é a forma menos encontrada na
prática.

Essa também é uma razão para não buscar uma chave substituta como jeito de pular este passo. Pôr um
`id` na tabela de matrículas a deixaria tecnicamente na 2FN e não mudaria nada na repetição:
`student_name` continuaria escrito uma vez por matrícula. A dependência é da identidade *real* da
linha, e uma chave substituta a esconde em vez de removê-la.

## A divisão

Cada dependência parcial vira a própria tabela, chaveada pela parte de que dependia:

```sql
CREATE TABLE students (
    email text PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE courses (
    code    text PRIMARY KEY,
    title   text NOT NULL,
    teacher text NOT NULL,
    teacher_room text NOT NULL
);

CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email),
    course_code   text NOT NULL REFERENCES courses  (code),
    grade         integer,
    PRIMARY KEY (student_email, course_code)
);
```

Três tabelas. O nome da Ana está num lugar. `Bancos de Dados` está num lugar. `grade` ficou, porque
era a única coluna que genuinamente dependia da chave inteira.

**E as anomalias de inserção e exclusão foram junto**, sem serem mencionadas. CRY300 agora pode
existir sem ninguém matriculado — é uma linha em `courses`. Apagar a matrícula da Ana em NET200
apaga uma matrícula e mais nada, porque NET200 não está guardado dentro dela.

Esse é o padrão a notar: **você conserta a dependência e as quatro anomalias vão embora juntas**,
porque eram quatro sintomas de uma causa.

## Reconstruindo o que você tinha

Nada se perdeu. A tabela original são as três juntadas de volta, que é assunto da aula 5 e cujo
formato vale ver agora:

```sql
SELECT s.email, s.name, c.code, c.title, e.grade
FROM enrolments e
JOIN students s ON s.email = e.student_email
JOIN courses  c ON c.code  = e.course_code;
```

Esta é a troca sendo feita, dita claramente: **escrever ficou mais seguro e ler ficou mais longo.**
Toda pergunta que era uma tabela agora é uma junção. Esse custo é real, é do que tratam as duas
últimas seções desta aula, e quase sempre vale pagar — porque uma junção é trabalho que uma máquina
faz, e uma anomalia de atualização é trabalho que uma pessoa faz, mal, em algum momento no futuro.

## `courses` não terminou

Olhe a tabela `courses` acima. Ela está na 2FN — a chave é uma coluna, então não tem como não estar
— e ainda tem um problema.

`teacher_room` é escrito uma vez por curso. A Reis leciona três cursos, então `B-204` aparece três
vezes, e mudá-la para B-310 significa mudar três linhas de novo. A anomalia que acabamos de remover
voltou numa tabela menor.

A chave determina a professora, e a professora determina a sala. Essa é a dependência transitiva da
seção `depende de`, e removê-la é a terceira forma normal.
