---
title: A chave primária: o que faz de uma linha aquela linha
version: 1
---

Linhas não têm ordem nem posição, então se você quer falar de uma linha e não de outra, a própria
linha precisa carregar algo que nenhuma outra carrega. Esse algo é a **chave primária**.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    ...
);
```

`PRIMARY KEY` diz duas coisas ao mesmo tempo, e vale separá-las porque elas falham de modos
diferentes:

1. **Esta coluna é única.** Duas linhas não podem ter o mesmo valor. Uma inserção que tente é
   recusada.
2. **Esta coluna nunca está vazia.** Ela não pode ser `NULL`.

Juntas significam: dado um valor, existe exatamente uma linha, ou nenhuma. Nunca duas, nunca
"provavelmente aquela".

## Veja a recusa

```sql
INSERT INTO customers (id, name, email) VALUES (1, 'Ana Lopes', 'ana@example.com');
INSERT INTO customers (id, name, email) VALUES (1, 'Bruno Sá', 'bruno@example.com');
```

```
ERROR:  duplicate key value violates unique constraint "customers_pkey"
DETAIL:  Key (id)=(1) already exists.
```

Leia o que aconteceu. A segunda linha **não** foi escrita e depois sinalizada; ela nunca foi
escrita. O banco recusou o comando e a tabela está exatamente como estava.

Essa é a diferença entre uma regra e um relatório. Uma planilha pode ser *verificada* quanto a
duplicatas depois, o que significa que existe uma janela — minutos, ou meses — durante a qual a
duplicata existe e tudo que lê a planilha recebe resposta errada. Uma chave primária significa que
**o estado ruim nunca existiu**. Não há janela.

## Chaves naturais e chaves substitutas

Algo nos seus dados pode já ser único. Um email, um CPF, um ISBN, um código de país. Usar um desses
como chave primária se chama **chave natural**: o identificador vem do mundo.

Inventar um número que não significa nada e não pertence a ninguém é uma **chave substituta**: o
identificador vem do banco.

Chaves naturais são tentadoras porque economizam uma coluna e porque `WHERE email = ...` lê melhor
que `WHERE id = 4471`. Ainda assim costumam ser a escolha errada, e aqui está o argumento.

**Uma chave natural precisa ser única, e precisa nunca mudar.** Quase nada no mundo é as duas
coisas.

- Emails são únicos — até alguém mudar o seu. Agora toda linha que apontava para o endereço antigo
  aponta para nada, e você está editando a chave em todas as tabelas que a referenciavam.
- Um CPF é único por país, e o seu segundo país tem a própria numeração.
- Um ISBN identifica uma edição, não um livro, e um livro pode ser reeditado.
- Até número de passaporte é reaproveitado depois de décadas suficientes.

A falha é específica e cara: **uma chave que muda tem que ser mudada em todo lugar para onde foi
copiada**, que é exatamente o problema que o modelo relacional existe para eliminar. Uma chave
substituta não pode mudar, porque nunca significou nada — não existe fato sobre o mundo capaz de
tornar `4471` errado.

Então o padrão:

> Dê a cada tabela uma chave primária substituta. Ponha a unicidade natural numa restrição `UNIQUE`
> ao lado dela.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    email  text    NOT NULL UNIQUE,
    name   text    NOT NULL
);
```

Agora `id` identifica a linha para sempre, `email` continua garantidamente único, e no dia em que a
Ana mudar de endereço você atualiza uma coluna numa linha e mais nada no banco percebe.

## De onde vem o número

Ninguém digita chaves primárias à mão. O banco as gera:

```sql
CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email  text    NOT NULL UNIQUE,
    name   text    NOT NULL
);

INSERT INTO customers (name, email) VALUES ('Ana Lopes', 'ana@example.com');
```

`GENERATED ALWAYS AS IDENTITY` é a grafia do padrão. Você também vai encontrar `SERIAL` em
PostgreSQL mais antigo, `AUTO_INCREMENT` em MySQL e MariaDB, e `INTEGER PRIMARY KEY` em SQLite, que
fazem o mesmo trabalho com palavras diferentes. A aula 12 é sobre essas diferenças; por ora, saiba
que a coluna se preenche sozinha.

**Duas coisas sobre números gerados que surpreendem.**

Eles têm buracos. Uma transação que pega um número e depois é desfeita não devolve o número, então
`1, 2, 5, 6` é uma tabela saudável e não sinal de que linhas foram apagadas. Contar linhas olhando
o maior id está errado.

E eles são adivinháveis. Se `/orders/1004` é um endereço válido na sua aplicação, `/orders/1003`
também é, e pertence a outra pessoa. Isso é um problema de autorização, não de chave — o conserto é
verificar quem está pedindo, não esconder o número — mas é a razão de sistemas públicos muitas vezes
carregarem um segundo identificador aleatório (um `UUID`) para uso em URLs, mantendo o inteiro
pequeno internamente.

## Chaves feitas de mais de uma coluna

Uma chave primária pode ser várias colunas. Isso é uma **chave composta**, e diz que a *combinação*
é única mesmo que nenhuma das colunas seja:

```sql
CREATE TABLE seat_bookings (
    flight_id integer NOT NULL,
    seat      text    NOT NULL,
    passenger text    NOT NULL,
    PRIMARY KEY (flight_id, seat)
);
```

O voo 431 aparece muitas vezes, o assento `12A` aparece muitas vezes, e `(431, '12A')` aparece uma
vez — que é exatamente a regra de que uma companhia aérea precisa. Tentar reservar um assento
ocupado é recusado pelo banco, sem uma linha de código de aplicação, e a recusa não depende de duas
pessoas clicarem no mesmo instante.

Chaves compostas são o formato natural das tabelas de ligação na seção de muitos-para-muitos mais
adiante. São menos confortáveis como chave de uma tabela comum, pela mesma razão que as chaves
naturais: tudo que aponta para a linha tem que carregar as duas colunas.

## O teste único

Se você guardar uma coisa desta seção, que seja a pergunta a fazer sobre qualquer chave candidata:

> **Duas coisas diferentes no mundo real poderiam alguma vez produzir o mesmo valor? E a mesma coisa
> poderia alguma vez produzir um valor diferente?**

Um "sim" na primeira significa que não é única. Um "sim" na segunda significa que não é estável. Uma
chave precisa de "não" nas duas, e um número que não significa nada é a única coisa que responde
"não" sem discussão.
