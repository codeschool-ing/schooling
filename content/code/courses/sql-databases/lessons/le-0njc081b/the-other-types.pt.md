---
title: Os outros tipos, e quando cada um é a resposta certa
version: 1
---

Mais quatro que aparecem o tempo todo, e uma instrução sobre quando buscar cada um.

## `boolean`

```sql
discontinued boolean NOT NULL DEFAULT false
```

Verdadeiro, falso, e — a menos que você proíba — `NULL`. Um booleano de três estados é quase sempre
acidente, e `NOT NULL DEFAULT false` é como você fica com os dois estados que queria.

**E um booleano muitas vezes é uma data disfarçada.** `is_paid boolean` responde se; `paid_at
timestamptz` responde se *e quando*, numa coluna, sem custo extra. O segundo é estritamente mais
informação, e `WHERE paid_at IS NOT NULL` lê perfeitamente bem. Busque o timestamp sempre que o
marcador assinala algo que aconteceu num momento.

Onde um booleano é genuinamente certo: uma configuração que alguém liga e desliga, uma propriedade
sem evento por trás — `is_active`, `newsletter_opt_in`.

## `uuid`

```sql
public_id uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE
```

128 bits, efetivamente único sem coordenação. Dois usos, e são diferentes:

**Como identificador público ao lado de uma chave inteira pequena.** O ponto da aula 1:
`/orders/1004` avisa que `/orders/1003` existe e pertence a outra pessoa. Um UUID na URL não diz
nada. O inteiro continua sendo a chave primária porque é menor em todo índice e toda chave
estrangeira.

**Como a própria chave primária**, quando linhas são criadas por várias máquinas que não podem
consultar uma sequência central — clientes offline, sistemas fragmentados, dados fundidos de várias
origens. O custo é real: 16 bytes em vez de 4 ou 8 em todo índice, e UUIDs aleatórios espalham
inserções pelo índice inteiro em vez de acrescentar no fim, o que dói em tabelas grandes. O UUID v7,
ordenado por tempo, existe para consertar exatamente isso.

> Comece por uma chave inteira. Acrescente um UUID quando algo fora do banco precisa nomear uma
> linha, ou quando o banco não é o único que as cria.

## `enum` contra uma tabela

```sql
CREATE TYPE invoice_status AS ENUM ('draft', 'issued', 'paid', 'cancelled');
status invoice_status NOT NULL DEFAULT 'draft'
```

Um `ENUM` é compacto, legível, reutilizável entre tabelas, e ordena na ordem de declaração, o que é
genuinamente útil — `ORDER BY status` dá draft, issued, paid, cancelled.

O custo é que mudá-lo é desajeitado. Acrescentar um valor é fácil (`ALTER TYPE … ADD VALUE`);
**remover ou renomear um não é**, e acrescentar um valor não podia ser feito dentro de uma transação
até pouco tempo atrás, o que tornava migrações desagradáveis.

A aula 1 deu a decisão e ela não mudou — a terceira linha é a que merece nota:

| | quando |
|---|---|
| `CHECK (… IN (…))` | uma lista curta e fixa que é parte do projeto |
| `ENUM` | a mesma lista, necessária em várias tabelas, com uma ordem significativa |
| uma tabela com chave estrangeira | os valores são **dado**: alguém não técnico acrescenta um, ou eles precisam de rótulo, cor, ordem própria |

**O sinal do terceiro é querer guardar algo ao lado do valor.** No momento em que um status precisa
de um nome de exibição em dois idiomas, era uma tabela.

## `json` e `jsonb`

```sql
payload jsonb NOT NULL
```

`jsonb` é o que se deve usar — é analisado e guardado em forma binária, pode ser indexado, e é para
ele que todo operador foi escrito. O `json` puro mantém o texto original incluindo espaços e ordem
de chaves, o que importa só se você precisa devolver exatamente o que recebeu.

**É certo para dados genuinamente opacos**: um payload de webhook da API de outra pessoa, guardado
como chegou; um blob de preferências por usuário a que nada se junta; um registro de auditoria do
que uma requisição continha.

**É errado como jeito de evitar projetar uma tabela.** Os sintomas são específicos, e se algum
destes for verdade a coisa era uma tabela:

- você se pega indexando uma chave específica lá dentro;
- você quer uma chave estrangeira a partir de algo lá dentro;
- você quer perguntar "quantos X" através das linhas;
- dois escritores discordam sobre que chaves existem.

Uma coluna `jsonb` é um pequeno banco sem esquema dentro do seu esquema, sem nenhuma das garantias
que este curso passou três aulas construindo. É uma troca razoável para um payload e ruim para o
seu próprio domínio.

## Arrays

```sql
tags text[] NOT NULL DEFAULT '{}'
```

Os arrays do PostgreSQL são reais e úteis, e a aula 2 deu o teste: uma lista numa coluna é um
muitos-para-muitos que alguém escolheu não modelar.

Use um quando os elementos **não são coisas** — rótulos sem propriedades, um vetor fixo de números,
um conjunto a que nada mais se refere. Use uma tabela quando são, e o sinal é o mesmo do `jsonb`: no
momento em que você quer contá-los, juntá-los ou restringi-los, eles eram linhas.

## E uma regra que cobre os cinco

> **Busque o tipo mais específico que seja verdade sobre o valor.**

`text` guarda uma data, e uma coluna `date` recusa `'terça que vem'`. `jsonb` guarda um cliente, e
uma tabela recusa um sem nome. Cada passo na direção de um tipo mais estreito move uma classe de
erro de *achado num relatório meses depois* para *recusado no momento em que foi escrito*, que é a
única troca que esta aula inteira está fazendo.
