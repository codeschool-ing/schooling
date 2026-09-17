---
title: Uma tabela é um conjunto de fatos sobre um tipo de coisa
version: 1
---

Uma tabela parece uma planilha e não é, e as diferenças são a razão de ela conseguir o que a
planilha não conseguia.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    name   text    NOT NULL,
    email  text    NOT NULL,
    city   text
);
```

Quatro linhas, e cada uma delas é uma promessa que o banco vai cumprir por você. Antes das
promessas, porém, o formato.

## Uma tabela, um tipo de coisa

`customers` guarda clientes. Não clientes e seus pedidos; não clientes e os produtos de que eles
gostam. **Uma tabela é sobre um tipo de coisa**, e o teste é conseguir terminar a frase *"cada
linha é um ______"* com um substantivo só.

Isso soa como preferência de estilo. Não é — é o que faz o apontamento funcionar. Se uma linha
fosse um cliente *e* um pedido, não haveria um único lugar que é "o cliente", e nada poderia
apontar para ele.

## Uma linha é um fato, e ela é inteira

Cada linha diz uma coisa que é verdade:

> O cliente 1 se chama Ana Lopes, o email dela é ana@example.com, e ela está no Porto.

Uma linha não é uma posição numa lista. **Linhas não têm ordem.** Isso surpreende quem vem de
planilhas, onde a linha 4 está inequivocamente abaixo da 3 e você pode arrastá-la para outro lugar.
Uma tabela é um *conjunto* de linhas, e um conjunto não tem primeiro elemento. Quando você pede
linhas a um banco sem dizer como ordenar, você pode receber em qualquer ordem — e em sistemas
reais a ordem muda com o tempo, silenciosamente, conforme os dados crescem e o banco muda de ideia
sobre como buscá-los.

Duas consequências seguem imediatamente, e as duas pegam iniciantes:

- **Você nunca pode confiar na ordem em que as linhas voltam se não pediu uma ordem.** Uma consulta
  que funcionou por um ano pode começar a devolver linhas de outro jeito depois de uma mudança sem
  relação. Nada quebrou; você estava confiando em algo que ninguém prometeu.
- **Não existe "número da linha" para apontar.** O que identifica uma linha tem que estar *dentro*
  dela. Essa é a próxima seção, e é o coração desta aula.

## Uma coluna tem um tipo, e o tipo é imposto

Numa planilha uma célula guarda o que você digitar. Uma coluna numa tabela guarda um tipo de valor,
e o banco recusa qualquer outro:

```sql
INSERT INTO customers (id, name, email, city)
VALUES ('banana', 'Ana Lopes', 'ana@example.com', 'Porto');
```

```
ERROR:  invalid input syntax for type integer: "banana"
LINE 2: VALUES ('banana', 'Ana Lopes', 'ana@example.com', 'Porto');
                ^
```

Isso é uma coisa pequena que se acumula enormemente. Uma coluna declarada `date` não pode guardar
`"terça que vem"`, `"03/04/2026"` nem uma string vazia, então todo valor nela é uma data de verdade
e pode ser comparado com todos os outros. Uma coluna de planilha que *parece* conter datas
normalmente contém quatro formatos diferentes e dois pedaços de texto, e você descobre quando tenta
ordenar.

Os tipos comuns, e os que vale conhecer no primeiro dia:

| tipo | guarda | a armadilha |
|---|---|---|
| `integer`, `bigint` | números inteiros | `integer` para perto de 2,1 bilhões — pouco para ids de linha numa tabela movimentada |
| `numeric(10,2)` | decimais exatos | **dinheiro vai aqui**, nunca em `real` ou `double` |
| `real`, `double precision` | decimais aproximados | `0.1 + 0.2` não é `0.3`; serve para medições, é errado para dinheiro |
| `text`, `varchar(n)` | caracteres | no PostgreSQL `text` não é mais lento que `varchar(n)`; o limite de tamanho é uma regra, não uma otimização |
| `boolean` | verdadeiro / falso | e `NULL`, que não é nenhum dos dois — veja adiante nesta aula |
| `date`, `timestamptz` | um dia, um instante | `timestamptz` guarda um instante real; `timestamp` guarda dígitos sem fuso e é um bug esperando |

**Dinheiro em coluna de ponto flutuante é o erro de tipo mais caro desta tabela**, e merece uma
linha própria. `real` e `double precision` guardam aproximações em binário, e décimos de centavo
não são representáveis em binário, do mesmo modo que um terço não é em decimal. Some mil faturas e
o total está errado por alguns centavos — pequeno o bastante para ninguém notar por um ano, e
grande o bastante para um contador acabar notando. Use `numeric`.

## Colunas contra linhas, e qual delas cresce

Esta é a decisão de formato que as pessoas mais erram, então encontre-a agora.

Suponha que clientes possam receber marcadores: `vip`, `atacado`, `newsletter`. O instinto de
planilha é uma coluna por marcador, ou uma coluna guardando `"vip, newsletter"`.

Os dois estão errados, e a razão é a mesma nos dois casos: **um marcador novo mudaria o formato da
tabela.** Acrescentar um quarto marcador significa acrescentar uma coluna, o que significa revisar
toda consulta que nomeava as colunas. E uma coluna guardando `"vip, newsletter"` é uma lista
escondida dentro de um texto — para perguntar "quantos VIPs" você estaria procurando texto dentro
de texto, o que também acha `"nao-vip"`.

A resposta relacional é que marcadores são *coisas*, então ganham uma tabela, e a ligação entre um
cliente e um marcador também é uma coisa, então ganha outra. Essa é a seção de muitos-para-muitos,
mais adiante nesta aula. O que importa aqui é o princípio:

> **Dados crescem em linhas. Estrutura cresce em colunas.** Se acrescentar mais um de algo
> significaria acrescentar uma coluna, o formato está errado.

## O que a tabela não guarda

Uma última coisa, e é sobre o que está deliberadamente ausente.

A tabela `customers` não guarda pedidos, nem totais, nem quantas vezes a Ana comprou algo. A
contagem não é guardada porque não é um fato sobre a Ana — é um fato sobre os pedidos dela, e pode
ser calculada a partir deles no momento em que alguém perguntar.

Guardá-la significaria mantê-la correta: todo pedido novo teria que lembrar de aumentá-la, todo
cancelamento de diminuí-la, e no dia em que um deles esquecer, o número está errado sem nada com
que comparar. Essa é a mesma falha das três cópias de um email, vestindo sua terceira roupa.

Existem razões reais para guardar um valor calculado mesmo assim — chama-se desnormalização, é uma
decisão de desempenho, e tem uma seção inteira na aula 2. O padrão, porém, e o que se deve buscar
até você ter medido uma razão para não fazê-lo: **guarde o que te disseram, calcule o que decorre
disso.**
