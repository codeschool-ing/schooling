---
title: A decomposição inteira, numa vista
version: 2
---

Uma tabela virou quatro, em três passos, cada um removendo um tipo nomeado de repetição. Aqui está
o percurso sem nada no meio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Quatro estágios de decomposição da esquerda para a direita. O estágio zero é uma tabela larga de oito colunas. A primeira forma normal separa uma lista em linhas. A segunda forma normal tira students e courses da tabela de matrículas. A terceira forma normal tira teachers de courses. O estágio final mostra quatro caixas: students, courses, teachers e enrolments, com a contagem de anomalias caindo de quatro para zero.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">0FN</text><rect x=\"14\" y=\"32\" width=\"134\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">enrolments</text><text x=\"24\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">student, name</text><text x=\"24\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cursos (uma lista)</text><text x=\"24\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">professor, sala</text><text x=\"24\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notas (uma lista)</text>\n<text x=\"196\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">1FN</text><rect x=\"196\" y=\"32\" width=\"134\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">enrolments</text><text x=\"206\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">student, name</text><text x=\"206\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">curso, título</text><text x=\"206\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">professor, sala</text><text x=\"206\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nota</text>\n<text x=\"378\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">2FN</text><rect x=\"378\" y=\"32\" width=\"134\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">students</text><rect x=\"378\" y=\"64\" width=\"134\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"74\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses</text><text x=\"388\" y=\"88\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">+ professor, sala</text><rect x=\"378\" y=\"100\" width=\"134\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enrolments</text>\n<text x=\"560\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3FN</text><rect x=\"560\" y=\"32\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">students</text><rect x=\"560\" y=\"60\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses</text><rect x=\"560\" y=\"88\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">teachers</text><rect x=\"560\" y=\"116\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enrolments</text>\n<path d=\"M152 80 L190 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M182 74 L190 80 L182 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<path d=\"M334 80 L372 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M364 74 L372 80 L364 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<path d=\"M516 80 L554 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M546 74 L554 80 L546 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<text x=\"81\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">listas em células</text>\n<text x=\"263\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nome e título repetem</text>\n<text x=\"445\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sala repete</text>\n<text x=\"633\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cada fato uma vez</text>\n<line x1=\"14\" y1=\"186\" x2=\"706\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"206\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">As quatro anomalias, em cada passo</text>\n<text x=\"14\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">atualização</text><text x=\"200\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"330\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"460\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">só a sala</text><text x=\"620\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sumiu</text>\n<text x=\"14\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">inserção</text><text x=\"200\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"330\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"460\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sumiu</text><text x=\"620\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sumiu</text>\n<text x=\"14\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exclusão</text><text x=\"200\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"330\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"460\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sumiu</text><text x=\"620\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sumiu</text>\n<text x=\"14\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">buscável</text><text x=\"200\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">não</text><text x=\"330\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"460\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"620\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text>\n<text x=\"14\" y=\"316\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Cada passo remove um tipo de repetição, e as anomalias que ela causava vão junto.</text>\n</svg>", "caption": "Quatro tabelas, três passos. A metade de baixo é a razão de cada um: uma anomalia que era possível antes dele e não é depois."}
```
## As quatro tabelas, escritas

```sql
CREATE TABLE teachers (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    room text NOT NULL
);

CREATE TABLE students (
    email text PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE courses (
    code       text    PRIMARY KEY,
    title      text    NOT NULL,
    teacher_id integer NOT NULL REFERENCES teachers (id) ON DELETE RESTRICT
);

CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email) ON DELETE RESTRICT,
    course_code   text NOT NULL REFERENCES courses  (code) ON DELETE RESTRICT,
    grade         integer CHECK (grade BETWEEN 0 AND 20),
    PRIMARY KEY (student_email, course_code)
);
```

Cada fato aparece uma vez. Cada ponteiro é imposto. `grade` aceita nulo de propósito — um aluno se
matricula antes de ser avaliado, e o teste da aula 1 passa: você consegue dizer em voz alta o que
uma vazia significa, que é *"ainda não avaliado"*.

## O que notar

**A tabela de ligação não apareceu no fim — ela estava lá desde a 1FN.** `enrolments` é o
muitos-para-muitos entre alunos e cursos, e chegou no momento em que a lista saiu da célula. As
formas seguintes tiraram coisas *dela* em vez de criá-la.

**`grade` nunca se mexeu.** Ao longo de três decomposições, a única coluna que dependia da chave
inteira ficou exatamente onde começou. É assim que se parece um fato corretamente posicionado, e
vale lembrar como a coisa que você busca: no fim, toda coluna está em algum lugar que não daria
para contestar.

**O formato é o mesmo da loja da aula 1.** Duas pontas e um meio guardando o par e o que pertence a
ele. Chegue nele pelo procedimento da aula 1 ou por três formas normais e você aterrissa no mesmo
lugar — que é o ponto desta aula. O procedimento estava certo, e agora há uma razão.

## Fazendo isso na ordem real

Ninguém constrói uma tabela na 0FN e depois normaliza três vezes. O que de fato acontece:

1. **Projete direto para a 3FN**, usando o procedimento da aula 1 e o teste de uma coluna — *esta
   coluna é um fato sobre a coisa de que esta linha trata?*
2. **Use as formas para conferir**, e principalmente para argumentar. Quando duas pessoas discordam
   sobre uma tabela, "isso é uma dependência transitiva" é uma afirmação sobre a qual alguém pode
   estar errado, e "parece mais limpo" não é.
3. **Use-as em tabelas que você herda**, que é onde elas se pagam. Lendo o esquema de outra pessoa,
   o valor repetido numa coluna é o que procurar, e as três formas te dizem qual divisão resolve.

As formas são um vocabulário para falar com precisão sobre um projeto mais vezes do que são um
procedimento para produzir um.
