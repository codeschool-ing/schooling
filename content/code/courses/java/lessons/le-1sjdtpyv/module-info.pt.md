---
title: Um módulo e o arquivo que o declara
version: 1
---

A lição 14 deu a uma classe quatro níveis de acesso, e o mais amplo, `public`, queria dizer **qualquer
um, em qualquer lugar**. Para um programa sozinho, isso bastava. Para uma biblioteca, é um problema:
uma biblioteca são vários pacotes, as classes dela precisam se chamar de um pacote para outro, então
essas classes têm de ser `public`, e aí todo programa que usa a biblioteca também consegue chamá-las.
Nada na linguagem dizia "público para os meus pacotes, e privado para todo o resto". O Java 9
acrescentou um nível acima do pacote para dizer exatamente isso: o **módulo**, um grupo de pacotes com
nome que declara quais deles o resto do mundo pode ver.

## Dois módulos, um arquivo cada

Um módulo é um diretório com um `module-info.java` na raiz. Esta biblioteca tem dois pacotes, um feito
para quem chama e outro para ela mesma, e a declaração exporta só o primeiro:

```java
// src/com.example.library/module-info.java
module com.example.library {
    exports com.example.library.api;
}
```

```java
// src/com.example.library/com/example/library/api/Catalogue.java
package com.example.library.api;

import com.example.library.internal.Index;

public class Catalogue {
    private final Index index = new Index();

    public String titleOf(String isbn) {
        return index.lookup(isbn);
    }
}
```

```java
// src/com.example.library/com/example/library/internal/Index.java
package com.example.library.internal;

import java.util.Map;

public class Index {
    private final Map<String, String> titles = Map.of(
            "978-0-13-468599-1", "Effective Java",
            "978-0-596-00920-5", "Java Concurrency in Practice");

    public String lookup(String isbn) {
        return titles.getOrDefault(isbn, "unknown");
    }
}
```

O `Index` é `public`, porque o `Catalogue` está em outro pacote e precisa usá-lo. **Antes dos módulos,
isso o tornava parte da interface da biblioteca, quisesse o autor ou não.** Agora quem decide é o
módulo: `exports com.example.library.api` e mais nada.

O programa que a usa é um segundo módulo, que diz do que precisa com `requires`:

```java
// src/com.example.app/module-info.java
module com.example.app {
    requires com.example.library;
}
```

```java
// src/com.example.app/com/example/app/Main.java
package com.example.app;

import com.example.library.api.Catalogue;

public class Main {
    public static void main(String[] args) {
        Catalogue catalogue = new Catalogue();
        System.out.println(catalogue.titleOf("978-0-13-468599-1"));
    }
}
```

Cinco arquivos, debaixo de um diretório `src` com um diretório por módulo, com o nome dele:

```
ana@vm:~/modules$ find src -name "*.java" | sort
src/com.example.app/com/example/app/Main.java
src/com.example.app/module-info.java
src/com.example.library/com/example/library/api/Catalogue.java
src/com.example.library/com/example/library/internal/Index.java
src/com.example.library/module-info.java
```

## Compilando e rodando no module path

O `javac` compila os dois módulos de uma vez quando lhe dizem onde estão os fontes, com
`--module-source-path`, e que módulos construir, com `-m`. O `java` então roda uma classe **dentro de
um módulo**, nomeada como `módulo/classe`, achando os módulos no **module path** e não no class path:

```
ana@vm:~/modules$ javac -d out --module-source-path src -m com.example.library,com.example.app
ana@vm:~/modules$ find out -name "*.class" | sort
out/com.example.app/com/example/app/Main.class
out/com.example.app/module-info.class
out/com.example.library/com/example/library/api/Catalogue.class
out/com.example.library/com/example/library/internal/Index.class
out/com.example.library/module-info.class
ana@vm:~/modules$ java --module-path out -m com.example.app/com.example.app.Main
Effective Java
```

O compilador escreveu um diretório por módulo, cada um com o seu `module-info.class`. A declaração do
módulo é compilada como qualquer classe, e a JVM a lê para saber o que cada módulo exporta e requer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Dois módulos. com.example.app requer com.example.library. A biblioteca exporta o pacote com.example.library.api, que o Main pode usar. O pacote com.example.library.internal não é exportado, então o código do módulo app não o alcança, nem na compilação nem por reflexão.\"><defs><marker id=\"jv40-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com.example.app</text><text x=\"170\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">requires com.example.library</text><rect x=\"40\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.app.Main</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com.example.library</text><text x=\"550\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exports com.example.library.api</text><rect x=\"420\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.library.api</text><rect x=\"420\" y=\"150\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">com.example.library.internal</text><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">classes públicas, não exportadas</text><path d=\"M300 100 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv40-a)\"></path><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pode usar</text><path d=\"M170 120 V180 H360\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">x</text><text x=\"250\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">public deixou de bastar: uma classe é alcançável quando é pública e o pacote dela é exportado</text></svg>", "caption": "Um módulo diz quais pacotes seus os outros módulos podem ver. O resto fica dentro do muro, público ou não."}
```

## O que o módulo recusa

O `Shortcut` pula a API e usa o `Index` direto, o que no class path seria perfeitamente válido:

```java
// src/com.example.app/com/example/app/Shortcut.java
package com.example.app;

import com.example.library.internal.Index;

public class Shortcut {
    public static void main(String[] args) {
        System.out.println(new Index().lookup("978-0-13-468599-1"));
    }
}
```

```
ana@vm:~/modules$ javac -d out --module-source-path src -m com.example.library,com.example.app
src/com.example.app/com/example/app/Shortcut.java:4: error: package com.example.library.internal does not exist
import com.example.library.internal.Index;
                                   ^
src/com.example.app/com/example/app/Shortcut.java:8: error: cannot find symbol
        System.out.println(new Index().lookup("978-0-13-468599-1"));
                               ^
  symbol:   class Index
  location: class Shortcut
2 errors
ana@vm:~/modules$ rm src/com.example.app/com/example/app/Shortcut.java
```

**Para o módulo app, o pacote não existe.** Ele está lá, no disco, compilado um instante antes, e o
`javac` responde como se não estivesse, porque um pacote não exportado não faz parte do que a
biblioteca oferece. Apague o arquivo de novo; ele já mostrou o que tinha de mostrar.

## Um módulo num jar

Um módulo é distribuído num jar como qualquer biblioteca, com o `module-info.class` na raiz. O `jar`
consegue ler a declaração de volta:

```
ana@vm:~/modules$ mkdir -p lib && jar --create --file lib/library.jar -C out/com.example.library .
ana@vm:~/modules$ jar --describe-module --file lib/library.jar
com.example.library jar:file:///home/ana/modules/lib/library.jar!/module-info.class
exports com.example.library.api
requires java.base mandated
contains com.example.library.internal

```

`exports` e `contains` são as duas metades: um pacote que qualquer um pode usar e um que é só da
biblioteca. `requires java.base mandated` é uma linha que ninguém escreveu. **Todo módulo depende de
`java.base`**, onde moram `String`, `Object` e as coleções, então ele entra em toda declaração, diga o
arquivo ou não.

O mesmo arquivo vai também num projeto Maven, como `src/main/java/module-info.java`, e o Maven então
compila o projeto como um módulo. O projeto `library` da lição 18 não tem nenhum, e a seção 05 diz por
que esse é o estado normal das coisas.
