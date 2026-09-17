---
title: Texto, e o limite de tamanho que não é otimização
version: 1
---

Três tipos guardam caracteres, e no PostgreSQL a escolha entre dois deles é bem menos interessante
do que se espera.

| tipo | o que é |
|---|---|
| `text` | qualquer tamanho |
| `varchar(n)` | no máximo `n` caracteres |
| `char(n)` | exatamente `n`, preenchido com espaços |

## `text` contra `varchar(n)`

**No PostgreSQL os dois têm desempenho idêntico.** Não há velocidade ganha declarando um limite nem
espaço economizado — o armazenamento é o mesmo, e um `varchar(n)` é `text` com uma verificação de
tamanho anexada.

Então a pergunta é só uma: **existe uma regra real sobre o tamanho?**

Um código de país tem dois caracteres porque a ISO 3166 diz — `varchar(2)` enuncia um fato.
`varchar(50)` no nome de uma pessoa não enuncia nada além de que alguém digitou 50, e no dia em que
um nome não couber, a inserção é recusada e uma pessoa real não pode ser registrada. Nomes no mundo
são mais longos do que você pensa.

> Use `text` por padrão. Use `varchar(n)` quando `n` vem de uma especificação, e saiba dizer qual.

**`char(n)` é armadilha e não deve ser usado.** Ele preenche com espaços até a largura declarada,
então `'PT'` num `char(5)` é `'PT   '` — e comparações, concatenações e a função de comprimento
passam a discordar entre si sobre os espaços estarem lá.

**E esta é a resposta do PostgreSQL, não do SQL.** No MySQL e no Oracle a escolha tem consequências
de desempenho e armazenamento, então esquemas escritos para eles e portados para cá carregam
`varchar(n)` em todo lugar por hábito. Aula 12.

## Igualdade não é tão simples quanto parece

Duas strings são iguais se os bytes são iguais, o que significa que estes são valores diferentes:

```
'Ana'   'ana'   'ANA'   'Ana '
```

Caixa diferente, e um espaço no fim que ninguém enxerga. Existe um quarto tipo que é pior e não
pode ser mostrado nesta página: **um `а` cirílico é um caractere diferente de um `a` latino e se
parece exatamente com um.** Cole um nome vindo de um documento e a consulta não acha nada, o valor
está na tela à sua frente, e as duas strings genuinamente não são iguais. `SELECT length(name),
octet_length(name)` é como você descobre — para texto todo ASCII os dois números batem, e para
aquele nome não batem.

**Caixa é a que chega em produção.** `WHERE email = 'Ana@Example.com'` não acha uma linha guardada
como `ana@example.com`. Três jeitos de lidar, em ordem crescente de quanto se sustentam:

```sql
-- 1. rebaixar na consulta: funciona, e não usa índice comum
WHERE lower(email) = lower('Ana@Example.com')

-- 2. rebaixar na escrita: a coluna guarda uma forma e comparar é trivial
email text NOT NULL UNIQUE CHECK (email = lower(email))

-- 3. citext, uma extensão cujas comparações ignoram caixa
CREATE EXTENSION citext;
email citext NOT NULL UNIQUE
```

O segundo normalmente é o certo para emails, e é o que faz o `UNIQUE` significar o que você queria:
sem ele, `Ana@example.com` e `ana@example.com` são duas linhas e a restrição está satisfeita.

## Collation, num parágrafo porque vai te surpreender uma vez

Ordenar texto depende de idioma, e o banco tem uma opinião:

```sql
SELECT name FROM people ORDER BY name;
```

Sob uma collation portuguesa, `Álvaro` ordena entre os As. Sob a collation `C` — ordem de byte —
ordena depois do `Z`, porque o byte é maior. Nenhuma está errada; respondem perguntas diferentes.
O padrão do banco vem de como ele foi criado, então **uma consulta que ordena certo no seu laptop
pode ordenar diferente em produção**, e o conserto é dizer o que você quer:
`ORDER BY name COLLATE "pt-BR"`.

## String vazia e NULL não são a mesma coisa

A aula 1 fez o ponto e vale repetir onde estão os tipos:

```sql
SELECT '' IS NULL;        -- falso
SELECT length('');        -- 0
SELECT length(NULL);      -- null
```

`''` é um valor: um texto sem nada dentro. `NULL` é a ausência de um. Uma tabela com os dois, para o
mesmo significado, precisa de duas condições em toda consulta que toca a coluna — e uma delas vai
acabar sendo esquecida.

**Escolha um e imponha.** Se vazio significa desconhecido no seu sistema, recuse a string vazia:

```sql
middle_name text CHECK (middle_name <> '')
```

O `CHECK` aceita `NULL` — desconhecido não é falso, da aula 1 — e recusa `''`. Agora há um jeito só
de dizer.
