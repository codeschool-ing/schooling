---
title: "jOOQ e MyBatis: o SQL continua seu"
version: 1
---

Um ORM parte dos objetos e deduz o SQL. O jOOQ e o MyBatis partem da outra ponta: **o banco e o seu
SQL vêm primeiro**, e os objetos Java são aquilo em que as linhas de uma consulta se transformam.
Nenhum dos dois guarda os seus objetos num contexto de persistência, e o SQL que roda é SQL que
alguém da equipe escreveu, então a maior parte da conta da tabela da primeira seção nunca chega.
Onde os dois discordam é sobre onde esse SQL mora.

## jOOQ: SQL escrito em Java

O **jOOQ** gera Java a partir do esquema. O gerador de código dele se conecta ao banco, ou lê os
scripts que o criam, e escreve uma classe para cada tabela, `BOOK` e `AUTHOR` no caso do bookshop,
com um campo tipado para cada coluna: `BOOK.TITLE` é um `TableField<BookRecord, String>`. Uma
consulta passa a ser Java que se lê como o SQL que ela produz. Os títulos de um autor da aula 11,
como esboço que **não foi rodado para este curso**:

```java
List<TitleAndPrice> books = ctx
        .select(BOOK.TITLE, BOOK.PRICE_CENTS)
        .from(BOOK)
        .join(AUTHOR).on(AUTHOR.ID.eq(BOOK.AUTHOR_ID))
        .where(AUTHOR.NAME.eq("Machado de Assis"))
        .orderBy(BOOK.TITLE)
        .fetch(Records.mapping(TitleAndPrice::new));
```

**O compilador confere a consulta contra o esquema**, do jeito que o gerador o viu pela última vez:
remova a coluna `price_cents`, gere de novo, e toda consulta que cita `BOOK.PRICE_CENTS` para de
compilar, antes de algum teste rodar e antes de alguém publicar. Comparar `BOOK.PRICE_CENTS` com uma
string falha do mesmo jeito, porque o campo sabe que guarda um `Integer`. E nada no SQL fica
escondido: o que roda é o `SELECT ... JOIN ... WHERE` que você lê no Java, sem plano de busca para
adivinhar e sem associação esperando para disparar um segundo comando.

Ele também alcança o que o JPQL deixa atrás das consultas nativas. Funções de janela, expressões de
tabela comuns (CTEs), o `ON CONFLICT` e o `RETURNING` do PostgreSQL são todos métodos do mesmo
builder.

Os custos estão no build e na licença. O gerador precisa do esquema, então o build precisa de um
banco para ler, ou dos scripts de migração que a aula 13 apresenta, e as classes geradas têm de ser
geradas de novo sempre que o esquema muda. E a edição de código aberto do jOOQ, sob a licença Apache
2.0, cobre bancos de código aberto como PostgreSQL e MySQL; Oracle, SQL Server e os outros bancos
comerciais precisam de uma edição paga. O Spring Boot tem um starter para ele,
`spring-boot-starter-jooq`, que entrega à aplicação um `DSLContext` pronto, o `ctx` acima.

## MyBatis: SQL num mapper

O **MyBatis** mantém o SQL como texto e lhe dá uma casa. Um **mapper** é uma interface Java cujos
métodos carregam cada um um comando, escrito numa anotação ou num arquivo XML que fica ao lado dela.
O MyBatis implementa a interface para você: liga os argumentos do método aos marcadores `#{...}` e
mapeia cada linha para o tipo de retorno. A mesma consulta, de novo um esboço que não foi rodado:

```java
@Mapper
public interface BookMapper {

    @Select("""
            SELECT b.title, b.price_cents
            FROM book b JOIN author a ON a.id = b.author_id
            WHERE a.name = #{name}
            ORDER BY b.title""")
    List<TitleAndPrice> titlesBy(String name);
}
```

Onde o MyBatis justifica o XML é no **SQL dinâmico**, um comando cujas cláusulas dependem de quais
argumentos chegaram. Uma busca com dois filtros opcionais é um único `<select>` no XML do mapper:

```xml
<select id="search" resultType="com.example.look.TitleAndPrice">
  SELECT title, price_cents FROM book
  <where>
    <if test="title != null">title ILIKE '%' || #{title} || '%'</if>
    <if test="maxPrice != null">AND price_cents &lt;= #{maxPrice}</if>
  </where>
  ORDER BY title
</select>
```

`<where>` escreve `WHERE` só se alguma condição sobrou, e tira o `AND` da frente da segunda quando a
primeira não sobrou. Montar esse comando juntando strings em Java é exatamente por onde entra a
injeção de SQL da aula 9; aqui todo valor continua viajando por `#{...}`, um parâmetro ligado.

O custo é que o SQL volta a ser uma string. Uma coluna escrita errado só aparece quando o comando
roda pela primeira vez, e um arquivo XML e uma interface têm de concordar em nomes que nenhum
compilador compara. O mapeamento também fica por sua conta: a configuração
`mapUnderscoreToCamelCase` do MyBatis é o que transforma `price_cents` em `priceCents`. Você
encontra o MyBatis em sistemas corporativos de longa vida, no Spring Boot pelo
`mybatis-spring-boot-starter` (publicado pelo projeto MyBatis, não pelo Spring), e por todo o
ecossistema Java da China, onde o **MyBatis-Plus** é construído sobre ele.
