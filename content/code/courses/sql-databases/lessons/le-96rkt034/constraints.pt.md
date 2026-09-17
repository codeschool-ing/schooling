---
title: Restrições: regras que o banco cumpre, não a aplicação
version: 1
---

Você já encontrou três restrições sem que fossem chamadas assim. `PRIMARY KEY`, `REFERENCES` e
`NOT NULL` são regras declaradas uma vez na tabela e impostas para sempre. Esta seção nomeia o
conjunto completo e apresenta o argumento para pôr regras aqui em vez de no seu programa.

```sql
CREATE TABLE products (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku          text          NOT NULL UNIQUE,
    name         text          NOT NULL,
    price        numeric(10,2) NOT NULL CHECK (price >= 0),
    stock        integer       NOT NULL DEFAULT 0 CHECK (stock >= 0),
    discontinued boolean       NOT NULL DEFAULT false
);
```

| restrição | o que ela recusa |
|---|---|
| `NOT NULL` | um desconhecido onde um valor é obrigatório |
| `UNIQUE` | uma segunda linha com o mesmo valor |
| `PRIMARY KEY` | as duas coisas acima, e nomeia a linha |
| `REFERENCES` | um ponteiro para algo que não está lá |
| `CHECK (…)` | qualquer coisa que torne a expressão falsa |
| `DEFAULT …` | nada — ela preenche um valor quando a inserção o omite |

`DEFAULT` está na tabela porque é escrito no mesmo lugar, mas não é uma regra; é uma conveniência.
As outras recusam.

## `CHECK` é a geral

`CHECK` aceita qualquer expressão sobre a linha e recusa o que a torne falsa:

```sql
CHECK (price >= 0)
CHECK (quantity > 0)
CHECK (ends_on > starts_on)
CHECK (status IN ('draft', 'placed', 'shipped', 'cancelled'))
CHECK (email LIKE '%@%')
```

Dois detalhes dessa lista merecem pausa.

`CHECK (ends_on > starts_on)` abrange **duas colunas da mesma linha**, o que é permitido e útil. O
que um `CHECK` não pode fazer é olhar outras linhas ou outras tabelas — "no máximo três reservas por
cliente" não é um `CHECK`, porque responder isso significa contar linhas em outro lugar.

E `CHECK` segue a lógica de três valores da seção anterior: ele recusa quando **falso**, não quando
"não verdadeiro". Se `ends_on` for `NULL`, a expressão é desconhecida, e desconhecido não é falso,
então a linha é **aceita**. Um `CHECK` numa coluna que aceita nulo não é a regra que você acha que
escreveu.

## A coluna de status, e uma decisão que você vai encontrar sempre

`CHECK (status IN ('draft', 'placed', 'shipped', 'cancelled'))` é uma de três maneiras de dizer a
mesma coisa, e a escolha aparece em todo esquema que alguém constrói:

| como | bom | ruim |
|---|---|---|
| `CHECK (… IN (…))` | uma linha, legível na tabela | acrescentar um valor altera a tabela |
| um tipo `ENUM` | a lista é reutilizável entre tabelas | alterá-la é específico do fornecedor e desajeitado |
| uma tabela `statuses` com chave estrangeira | um status novo é um `INSERT`; o status pode carregar rótulo, ordem, cor | mais uma tabela, mais uma junção |

**Para uma lista fixa que ninguém vai mudar — `CHECK`.** Quatro status de pedido, os dias da semana,
`'M'`/`'F'`/`'X'`. A lista é parte do projeto.

**Para uma lista que é dado — uma tabela.** Categorias de produto, países, prioridades de chamado. O
sinal é que alguém não técnico vai querer acrescentar um, ou que os valores precisam de propriedades
próprias. No momento em que você se pegar querendo guardar um nome de exibição ao lado de um status,
descobriu que era dado.

O erro a evitar não é nenhum desses: uma coluna `text` sem restrição nenhuma, que acaba guardando
`'shipped'`, `'Shipped'`, `'SHIPPED'` e `'shiped'`, e nenhuma consulta está certa de novo.

## Por que as regras vão no banco

Este é o argumento de fato da seção, e é um que você vai ter que fazer para alguém algum dia.

A objeção é razoável: *a aplicação já valida isso. Por que dizer duas vezes?*

**Porque "a aplicação" nunca é uma aplicação.** Quando um banco tem dois anos, já está sendo escrito
pelo site, por um job de segundo plano, por um script de importação, por uma API móvel, por um
console administrativo, por uma correção que alguém rodou de um terminal, e pelo que quer que a
equipe de dados tenha construído. Cada um deles é um lugar onde a regra pode ser esquecida, e a
regra é só tão forte quanto o mais fraco deles.

Mais três razões, em ordem crescente de quanto custam quando ignoradas:

**A aplicação valida o que consegue ver.** "Este email é único" é verificado selecionando e depois
inserindo. Duas requisições chegando no mesmo instante verificam, não acham nada, e inserem as duas.
A aplicação fez tudo certo e o dado está errado mesmo assim. Uma restrição `UNIQUE` não pode ser
vencida assim, porque a verificação e a escrita são uma operação só dentro do banco.

**Dado ruim sobrevive ao código que o criou.** Código de aplicação é trocado a cada poucos anos; os
dados são migrados adiante, defeitos e tudo. Uma restrição recusa a linha ruim no momento em que ela
é escrita, que é o único momento em que é barato consertar — quem causou ainda está lá, e é uma só.

**Uma restrição é documentação que não pode estar errada.** Um comentário dizendo "preço nunca é
negativo" pode ser falso. `CHECK (price >= 0)` é verdade de toda linha da tabela, inclusive das
escritas antes de você chegar, ou a tabela não as teria aceitado.

## E o custo honesto

Restrições não são de graça, e fingir o contrário enfraquece o argumento.

- **Custam um pouco na escrita.** Toda inserção as verifica. Na prática isso é muito menor do que se
  espera, e muito menor do que as consultas que o dado ruim te faria escrever.
- **Tornam carga em massa desajeitada.** Importar dez milhões de linhas com chaves estrangeiras
  verificadas uma a uma é lento; a resposta é carregar e depois acrescentar as restrições, o que
  valida a tabela inteira de uma vez.
- **Tornam alguns deploys mais difíceis.** Acrescentar `NOT NULL` a uma coluna que já tem nulos
  falha, e corretamente — mas falha no pior momento, a menos que alguém tenha verificado antes. Isso
  é assunto de migrações e é a aula 11.
- **São uma recusa de verdade.** `RESTRICT` bloqueando uma exclusão que você queria não é um bug,
  mas é atrito, e alguém vai propor remover a restrição em vez de perguntar por que a exclusão
  estava errada.

A troca vale quase sempre, e a razão de conhecer os custos é para você fazê-la deliberadamente em
vez de como slogan.

## Por onde começar

Uma regra para o primeiro esquema que você projetar, que não vai te levar para o lado errado:

> Toda coluna `NOT NULL` a menos que você consiga descrever a vazia. Toda tabela com chave primária.
> Toda referência declarada. Um `CHECK` onde quer que você se pegue escrevendo um comentário sobre o
> que a coluna pode guardar.

Você sempre pode relaxar uma restrição depois, numa tabela que a obedeceu. Você não pode acrescentar
uma depois numa tabela que vem caladamente quebrando ela há dois anos — não sem uma limpeza que
ninguém orçou, que é como essas coisas são puladas em primeiro lugar.
