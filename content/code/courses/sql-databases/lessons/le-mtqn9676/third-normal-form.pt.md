---
title: Terceira forma normal: nada além da chave
version: 1
---

A segunda forma normal deixou isto:

```sql
CREATE TABLE courses (
    code         text PRIMARY KEY,
    title        text NOT NULL,
    teacher      text NOT NULL,
    teacher_room text NOT NULL
);
```

| code | title | teacher | teacher_room |
|---|---|---|---|
| SQL101 | Bancos de Dados | Reis | B-204 |
| NET200 | Redes | Dias | A-110 |
| SEC300 | Segurança | Reis | B-204 |
| ALG150 | Algoritmos | Reis | B-204 |

Uma coluna na chave, então a 2FN vale e não tem como ser quebrada. E `B-204` está escrito três
vezes.

## A pergunta de novo

**O que pode dar errado aqui que não daria se fosse dividida?**

A Reis muda para B-310. Três linhas carregam a sala e as três precisam mudar juntas. Duas de três e
o banco diz que a Reis leciona em duas salas.

Depois, *por quê*: a sala não é um fato sobre o curso. **É um fato sobre a professora**, e está
sendo guardado numa tabela cujas linhas são cursos, então aparece uma vez por curso que ela por
acaso leciona.

A cadeia é a da seção `depende de`:

```
code  →  teacher  →  teacher_room
```

A chave determina a sala, mas **por meio de** outra coluna comum. Isso é uma **dependência
transitiva**, e é o último dos três tipos.

## A regra

> **Uma tabela está na terceira forma normal quando está na 2FN e nenhuma coluna não-chave depende
> de outra coluna não-chave.**

O que completa a frase:

> Toda coluna não-chave depende da chave, da chave inteira, e de **nada além da chave**.

`nada além da chave` é exatamente a proibição de passar por uma coluna intermediária.

## A divisão

A coluna intermediária vira a chave de uma tabela nova:

```sql
CREATE TABLE teachers (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    room text NOT NULL
);

CREATE TABLE courses (
    code       text    PRIMARY KEY,
    title      text    NOT NULL,
    teacher_id integer NOT NULL REFERENCES teachers (id)
);
```

A Reis é uma linha. A sala está escrita uma vez. Mudá-la é um `UPDATE` tocando uma linha, e não
existe estado em que o banco guarde duas respostas.

**Note que `teachers` ganhou uma chave substituta** enquanto `courses` manteve `code` e `students`
manteve `email`. Esse é o argumento da aula 1 chegando na prática: um código de curso é impresso no
catálogo e não muda, um email é pelo menos discutível, e o nome de uma professora é exatamente o
tipo de coisa que muda — então a que está sendo inventada aqui é a que precisava ser inventada.
Normalização diz *divida*; não diz qual deve ser a chave da tabela nova, e isso continua sendo
decisão sua.

## O teste que você pode aplicar sem o vocabulário

Uma vez achada a divisão, os nomes formais param de ser úteis e uma pergunta os substitui:

> **Esta coluna é um fato sobre a coisa de que esta linha trata?**

`title` é um fato sobre o curso. `teacher_id` diz qual professora, que é um fato sobre o curso.
`room` é um fato sobre uma *professora*, sentado numa linha que é um curso. Fora.

É o mesmo teste do *"cada linha é um ______"* da aula 1, aplicado uma coluna por vez, e pega quase
tudo que as três formas pegam sem precisar dizer "transitiva" em voz alta.

## Duas coisas que a 3FN não faz

**Ela não remove toda repetição.** `teacher_id` continua se repetindo — `1, 2, 1, 1` coluna abaixo
— e deve. Repetir uma *referência* é como o modelo funciona; o que a 3FN remove é repetir o *fato*.
Não mude nada sobre a sala da Reis e todo curso continua apontando para a única linha que a guarda.

A distinção merece precisão, porque é onde as pessoas aplicam demais as regras: valores repetidos
são normais quando são ponteiros, e são problema quando são cópias de algo que pode mudar
independentemente.

**Ela não torna o projeto correto.** Uma tabela pode estar na 3FN e ainda ser um mau modelo do
mundo — granularidade errada, um conceito faltando, uma coluna de status que deveria ser tabela.
Normalização remove uma classe específica de defeito. Não substitui saber o que você está
modelando, e o procedimento da aula 1 continua sendo como você acha as coisas em primeiro lugar.

## Por que quase todo mundo para aqui

Existem formas mais altas — FNBC, 4FN, 5FN — e a próxima seção diz o que são. Na prática a 3FN é
onde o retorno deixa de ser óbvio:

- As três anomalias sumiram. Nada além da 3FN remove uma anomalia de atualização, inserção ou
  exclusão do tipo com que esta aula abriu; as formas mais altas tratam de formatos mais raros.
- Cada divisão custa uma junção, para sempre, em toda leitura.
- Os formatos que precisam de FNBC são incomuns o bastante para encontrar um ser um evento notável
  em vez de uma terça-feira.

Então o padrão de trabalho, em quase todo sistema em que você vai mexer: **projete para a terceira
forma normal, saiba que as mais altas existem, e quebre a 3FN só onde você mediu uma razão.** As
duas metades dessa frase têm uma seção pela frente.
