---
title: Parâmetros, nunca strings coladas
version: 1
---

O `Jdbc.java` nunca pôs o nome do autor dentro do SQL. Ele escreveu um `?` e entregou o nome com
`setString`. A alternativa óbvia é montar a consulta como string, e muito código faz isso. Funciona
com todo nome que você testa enquanto escreve, e é por isso que sobrevive. Esta seção roda esse
jeito com o nome que o quebra.

Isto é um **desvio**: o `Unsafe.java` é o jeito errado, mantido só o tempo de vê-lo falhar. Salve-o
ao lado do `Jdbc.java`; ele difere em uma linha e em usar um `Statement` simples:

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Unsafe {

    public static void main(String[] args) throws SQLException {
        String url = "jdbc:postgresql://localhost:5432/bookshop";
        String sql = "SELECT id, title, price_cents FROM book WHERE author = '" + args[0] + "' ORDER BY title";
        System.out.println(sql);

        try (Connection connection = DriverManager.getConnection(url, "bookshop", "bookshop");
             Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(sql)) {
            while (rows.next()) {
                int cents = rows.getInt("price_cents");
                System.out.printf("%d  %-22s %d.%02d%n", rows.getLong("id"), rows.getString("title"), cents / 100, cents % 100);
            }
        }
    }
}
```

Ele imprime o SQL que montou antes de enviá-lo. Com um nome comum, funciona, e dá a mesma resposta
que o `Jdbc.java`:

```
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Unsafe.java 'H. G. Wells'
SELECT id, title, price_cents FROM book WHERE author = 'H. G. Wells' ORDER BY title
2  The Time Machine       29.50
3  The War of the Worlds  32.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Unsafe.java "Flannery O'Connor" 2>&1 | head -n 4
SELECT id, title, price_cents FROM book WHERE author = 'Flannery O'Connor' ORDER BY title
Exception in thread "main" org.postgresql.util.PSQLException: Unterminated string literal started at position 73 in SQL SELECT id, title, price_cents FROM book WHERE author = 'Flannery O'Connor' ORDER BY title. Expected  char
	at org.postgresql.core.Parser.checkParsePosition(Parser.java:1459)
	at org.postgresql.core.Parser.parseSql(Parser.java:1366)
```

Leia o SQL impresso como o banco o leria. A aspa depois de `author = ` abre uma string, e o apóstrofo
do nome **a fecha**, então a string é `'Flannery O'`. Aí `Connor` já não é dado; é uma palavra do
comando. A aspa depois dele abre uma string nova que nunca termina, e o driver, que lê o texto antes
de enviá-lo, parou ali: a posição 73 é essa última aspa. Ninguém digitou nada malicioso. Um
sobrenome de verdade transformou parte da entrada em SQL.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 254\" role=\"img\" aria-label=\"Em cima, a consulta concatenada: uma única string em que o nome do autor, Flannery O'Connor, fica dentro do SQL, e o apóstrofo dele fecha o texto entre aspas antes da hora. Embaixo, o prepared statement: o SQL com um marcador, $1, vai primeiro, e o nome vai separado, como valor.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Concatenado: o nome é colado no texto do SQL</text><rect x=\"20\" y=\"30\" width=\"660\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SELECT id, title, price_cents FROM book WHERE author = '<tspan fill=\"var(--amber)\">Flannery O'Connor</tspan>' ORDER BY title</text><text x=\"20\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o apóstrofo do nome fecha o texto entre aspas, e o resto é lido como SQL</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Um parâmetro: o comando e o valor vão separados</text><rect x=\"20\" y=\"144\" width=\"660\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SELECT id, title, price_cents FROM book WHERE author = $1 ORDER BY title</text><text x=\"668\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">comando</text><rect x=\"20\" y=\"206\" width=\"300\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$1 = <tspan fill=\"var(--amber)\">Flannery O'Connor</tspan></text><text x=\"336\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um valor, nunca lido como SQL</text><text x=\"308\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">valor</text></svg>", "caption": "A concatenação manda uma string só, e o servidor não sabe onde o dado termina. Um parâmetro viaja ao lado do comando e nunca é lido como SQL."}
```

## Por que um erro de sintaxe é o desfecho de sorte

Aqui o resultado foi uma exceção, porque o texto que vazou por acaso não era SQL válido. **Uma
entrada que vaza para dentro de um comando e É SQL válido roda**, e roda com as permissões do papel
da livraria: pode alargar um `WHERE` para linhas que a tela nunca deveria mostrar, ou terminar o
comando e começar outro. Isso é **injeção de SQL**, e ela está perto do topo de toda lista de
fraquezas de aplicações web há vinte anos, por um motivo só: dado e código dividem um canal.

Dobrar os apóstrofos antes de concatenar, do jeito que você digitou `'Flannery O''Connor'` no
`psql`, conserta este nome. Não conserta o método, porque toda consulta que monta texto precisa
aplicar a regra certinho, para todo tipo de valor, para sempre. A correção que se sustenta é
**manter o valor fora do texto**. Com `?` e `setString`, o driver do PostgreSQL manda o comando com
um marcador numerado, `$1`, e manda o valor ao lado. O servidor interpreta o comando antes de ver o
valor, então não há nada no valor que ele possa ler como SQL.

Duas consequências decorrem disso, e as duas aparecem em código de verdade:

- **Um parâmetro é um valor, nunca um nome.** Uma tabela, uma coluna ou uma direção de ordenação não
  pode ser um `?`, porque o servidor precisa delas para sequer entender o comando. Quando o usuário
  escolhe a coluna de ordenação, mapeie a escolha para uma lista fixa de nomes de coluna escrita no
  código; nunca cole o texto dele.
- **O `prepareStatement` só protege o que passa pelo `?`.** Uma string montada com `+` ou
  `String.format` e depois passada ao `prepareStatement` é tão insegura quanto o `Unsafe.java`. O
  nome do método não é a proteção; o marcador é.

Toda consulta no resto deste curso, inclusive as que o Spring e o Hibernate escrevem por você, usa
parâmetros. Apague o `Unsafe.java`; o trabalho dele terminou.
