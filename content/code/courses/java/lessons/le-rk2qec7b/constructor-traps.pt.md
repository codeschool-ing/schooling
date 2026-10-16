---
title: O construtor que roda cedo demais
version: 1
---

A ordem da seção 03 tem uma consequência que ninguém espera da primeira vez. **Enquanto o construtor
da superclasse roda, os campos da subclasse ainda não foram definidos**, nem os que têm inicializador,
nem os `final`. Normalmente isso não importa, porque o construtor da superclasse não sabe nada sobre
a subclasse. Começa a importar quando o construtor da superclasse chama um método, e a subclasse
sobrescreve esse método.

Eis a armadilha. O construtor de `Item` imprime uma descrição do item que está construindo, chamando
`describe()`. `Book` sobrescreve `describe()` para usar os seus próprios campos:

```java
// Trap.java
class Item {
    Item() {
        System.out.println("Item() sees: " + describe());
    }

    String describe() {
        return "an item";
    }
}

class Book extends Item {
    private final String title;
    private int pages = 100;

    Book(String title) {
        super();
        this.title = title;
    }

    @Override
    String describe() {
        return title + ", " + pages + " pages";
    }
}

public class Trap {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro");
        System.out.println("afterwards: " + book.describe());
    }
}
```

Num diretório só dele, `~/init/trap`:

```
ana@vm:~/init/trap$ javac Trap.java && java Trap
Item() sees: null, 0 pages
afterwards: Dom Casmurro, 100 pages
```

**`null` num campo `final`, e 0 num campo inicializado com 100.** Siga pelos passos da seção 03. O
`new Book("Dom Casmurro")` chama `super()` primeiro, então o `Item()` roda antes de qualquer coisa de
`Book`. O `Item()` chama `describe()`, e como o objeto em construção *é* um `Book`, a chamada chega à
versão de `Book`, a que sobrescreve (a lição 25 trata dessa escolha). Essa versão lê `title` e
`pages`, que ainda guardam os valores padrão com que todo campo começa: `null` para uma referência e
0 para um `int`. Só depois que o `super()` retorna é que `pages = 100` e `this.title = title` rodam.

Um programa não para na linha errada; ele a imprime, segue em frente e depois está certo. Troque o
`println` por código que guarda a descrição, ou a valida, ou registra o objeto em algum lugar, e o
erro fica guardado. **A regra que decorre disso: um construtor não deve chamar um método que uma
subclasse possa sobrescrever.** Chame um método `private`, `static` ou `final`, que nenhuma subclasse
consegue substituir, ou faça o trabalho depois da construção.

## Código antes do `super(...)`, a partir do Java 25

Até o Java 25, a chamada `super(...)` tinha de ser a primeira instrução de um construtor, então uma
subclasse não conseguia definir um campo antes de a superclasse rodar. **O Java 25 permite instruções
antes do `super(...)`**, com uma condição: elas podem atribuir os campos do próprio objeto, mas não
podem lê-los nem chamar métodos dele, porque o objeto ainda não está construído. Isso basta para pôr
`title` no lugar antes de o `Item()` olhar para ele, e para conferir o argumento antes de qualquer
construção começar:

```java
// Early.java
class Item {
    Item() {
        System.out.println("Item() sees: " + describe());
    }

    String describe() {
        return "an item";
    }
}

class Book extends Item {
    private final String title;
    private int pages = 100;

    Book(String title) {
        if (title.isBlank()) {
            throw new IllegalArgumentException("a book needs a title");
        }
        this.title = title;
        super();
    }

    @Override
    String describe() {
        return title + ", " + pages + " pages";
    }
}

public class Early {
    public static void main(String[] args) {
        Book book = new Book("Dom Casmurro");
        System.out.println("afterwards: " + book.describe());
        new Book(" ");
    }
}
```

```
ana@vm:~/init/trap$ javac Early.java && java Early
Item() sees: Dom Casmurro, 0 pages
afterwards: Dom Casmurro, 100 pages
Exception in thread "main" java.lang.IllegalArgumentException: a book needs a title
	at Book.<init>(Early.java:18)
	at Early.main(Early.java:34)
```

**Metade resolvida, e a metade não resolvida ensina alguma coisa.** O `title` foi atribuído antes do
`super()`, então o `Item()` o viu. O `pages` continuou valendo 0, porque um inicializador de campo não
é uma instrução que você escreveu antes do `super()`: ele é o passo 5, e roda depois que o `super()`
retorna, como antes. Para ter `pages` no lugar cedo, ele também teria de ser atribuído no construtor,
acima da chamada.

O título em branco falhou antes de o `Item` entrar em cena. `Book.<init>` no stack trace é o
construtor de `Book`, como a JVM o chama, e a linha 18 é o `throw`. A lição 36 lê stack traces com
calma. Validar um argumento antes de a superclasse fazer qualquer trabalho exigia um método auxiliar
estático em volta do argumento; agora é um `if` no lugar óbvio.

**Isto é novo no Java 25 e não existe no 21.** Compile o mesmo arquivo para o 21 e o compilador diz
isso, pelo nome:

```
ana@vm:~/init/trap$ javac --release 21 Early.java
Early.java:20: error: flexible constructors is not supported in -source 21
        this.title = title;
        ^
  (use -source 25 or higher to enable flexible constructors)
1 error
```

O recurso se chama **corpos de construtor flexíveis** (flexible constructor bodies). Ele muda onde
você pode pôr código. Não muda a ordem da seção 03, e não torna seguro chamar um método sobrescrevível
num construtor: o que a subclasse define nos inicializadores de campo continua faltando naquele
momento.
