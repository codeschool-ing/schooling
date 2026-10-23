---
title: Imports, e as duas classes `Date`
version: 1
---

**Um import não carrega nada, não inclui nada e não deixa programa nenhum maior.** É uma promessa ao
compilador sobre nomes curtos: quando este arquivo diz `Book`, ele quer dizer
`com.example.library.Book`. Toda classe sempre pode ser chamada pelo nome completo, `java.util.List`,
sem import nenhum. Os imports existem para ninguém precisar fazer isso, e o arquivo de classe
compilado guarda os nomes completos de qualquer jeito.

## Os quatro tipos

| forma | exemplo | o que ela torna disponível |
|---|---|---|
| de um tipo (single-type) | `import java.util.List;` | uma classe, pelo nome curto |
| sob demanda (on-demand) | `import java.util.*;` | toda classe de um pacote, quando usada |
| estático | `import static java.lang.Math.max;` | um membro estático, chamado sem a classe |
| de módulo | `import module java.base;` | todo pacote que um módulo exporta, só no Java 25 |

E um import que ninguém escreve: **`java.lang` é importado em todo arquivo**. É por isso que
`String`, `System`, `Math` e `Integer` não precisaram de import em nenhuma lição até aqui.

O `*` não é um curinga sobre subpacotes. `import java.util.*;` traz `java.util.List` e não traz
`java.util.concurrent.ExecutorService`: para o compilador, `java.util.concurrent` é outro pacote, que
por acaso divide com o primeiro a parte inicial do nome.

## Quando dois pacotes têm o mesmo nome dentro

`java.util` tem uma classe chamada `Date`, e `java.sql` também. Um arquivo que importa os dois
pacotes sob demanda e depois diz `Date` pediu uma de duas classes:

```java
// src/com/example/library/app/Dates.java
package com.example.library.app;

import java.util.*;
import java.sql.*;

public class Dates {
    public static void main(String[] args) {
        Date start = new Date(0);
        System.out.println(start.getTime());
    }
}
```
```
ana@vm:~/pkgs$ javac -d out src/com/example/library/app/Dates.java
src/com/example/library/app/Dates.java:9: error: reference to Date is ambiguous
        Date start = new Date(0);
        ^
  both class java.sql.Date in java.sql and class java.util.Date in java.util match
src/com/example/library/app/Dates.java:9: error: reference to Date is ambiguous
        Date start = new Date(0);
                         ^
  both class java.sql.Date in java.sql and class java.util.Date in java.util match
2 errors
```

**`reference to Date is ambiguous`** (a referência a `Date` é ambígua), e o compilador nomeia as duas
candidatas. Ele acusou o erro duas vezes porque a linha diz `Date` duas vezes, uma no tipo da
variável e outra depois do `new`. Nada no programa está errado, a não ser o nome. Há duas correções, e
a primeira é a de sempre: **um import de um tipo vence um import sob demanda**, então acrescentar
`import java.util.Date;` resolve qual `Date` o arquivo quer. Esta versão faz isso, e acrescenta um
import estático:

```java
// src/com/example/library/app/Dates.java
package com.example.library.app;

import java.util.*;
import java.sql.*;
import java.util.Date;

import static java.lang.Math.max;

public class Dates {
    public static void main(String[] args) {
        Date start = new Date(0);
        System.out.println(start.getClass().getName() + " " + max(start.getTime(), 1));
    }
}
```
```
ana@vm:~/pkgs$ javac -d out src/com/example/library/app/Dates.java && java -cp out com.example.library.app.Dates
java.util.Date 1
```

O programa imprimiu a classe que de fato usou, `java.util.Date`, e o `max(...)` funcionou sem `Math.`
na frente por causa do `import static java.lang.Math.max;`. Um import estático compensa para poucos
nomes que um arquivo usa o tempo todo; um arquivo cheio deles deixa o leitor perguntando de onde veio
cada nome. A segunda correção para o conflito é abrir mão do nome curto e escrever o completo,
`java.sql.Date`, no único lugar que precisa dele, que é o que faz o código que usa as duas.

**A maioria dos editores escreve os imports para você**, e escreve imports de um tipo. Você vai ler
muito mais imports do que digitar, então a habilidade é lê-los: uma linha de import diz qual `Date`
este arquivo quer dizer, e é o primeiro lugar para olhar quando uma classe não se comporta como o
nome curto sugere.

## Importar um módulo inteiro: novidade do Java 25

A biblioteca do JDK é dividida em **módulos**, cada um um conjunto de pacotes; a lição 40 é sobre
eles. O Java 25 acrescentou um quarto tipo de import, que traz numa linha todo pacote que um módulo
exporta. `java.base` é o módulo com o núcleo da biblioteca, `java.util`, `java.io`, `java.nio.file` e
o resto:

```java
// Modules.java
import module java.base;

public class Modules {
    public static void main(String[] args) {
        List<String> titles = List.of("Effective Java", "Head First Java");
        Map<String, Integer> editions = Map.of("Effective Java", 3);
        Path home = Path.of(System.getProperty("user.home"));
        System.out.println(titles.size() + " " + editions.get("Effective Java") + " " + home);
    }
}
```
```
ana@vm:~/pkgs$ java Modules.java
2 3 /home/ana
ana@vm:~/pkgs$ javac --release 21 -d /tmp/m21 Modules.java
Modules.java:2: error: module imports are not supported in -source 21
import module java.base;
       ^
  (use -source 25 or higher to enable module imports)
1 error
```

`List`, `Map` e `Path` moram em três pacotes diferentes, e uma linha cobriu todos. **Isso não existe
antes do Java 25**: compilado com `--release 21`, o mesmo arquivo falha com uma mensagem que diz isso
e nomeia a versão de que precisa. É prático em programas curtos. Num projeto, os imports de um tipo
continuam sendo a regra, porque dizem exatamente qual classe um nome quer dizer, e o import de dois
módulos que exportam um `Date` cada um é a ambiguidade de cima, de novo.
