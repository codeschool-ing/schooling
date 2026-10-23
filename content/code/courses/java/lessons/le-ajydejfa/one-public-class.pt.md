---
title: Uma classe pública por arquivo
version: 1
---

A lição 3 apresentou a regra de que um arquivo tem o nome da sua classe pública. A outra metade dela
é que **um arquivo só pode ter uma classe pública**, e quantas classes não públicas quiser. Num
diretório novo, `~/catalogue`, aqui está um arquivo com duas classes públicas:

```java
// Catalogue.java
public class Catalogue {
    public static void main(String[] args) {
        Entry e = new Entry();
        e.title = "Grande Sertão: Veredas";
        System.out.println(e.title);
    }
}

public class Entry {
    String title;
}
```

```
ana@vm:~/catalogue$ javac Catalogue.java
Catalogue.java:10: error: class Entry is public, should be declared in a file named Entry.java
public class Entry {
       ^
1 error
```

O compilador não se opõe a `Entry` dividir o arquivo. Ele se opõe a `Entry` ser **pública** ali,
porque uma classe pública tem de ser encontrável pelo nome: quando outra classe, em qualquer lugar,
se refere a `Entry`, o compilador procura `Entry.java`. Duas saídas, então. Mover `Entry` para um
arquivo próprio, `Entry.java`, ou tirar o `public`. Tirando:

```java
// Catalogue.java
public class Catalogue {
    public static void main(String[] args) {
        Entry e = new Entry();
        e.title = "Grande Sertão: Veredas";
        System.out.println(e.title);
    }
}

class Entry {
    String title;
}
```

```
ana@vm:~/catalogue$ javac Catalogue.java && java Catalogue
Grande Sertão: Veredas
ana@vm:~/catalogue$ ls
Catalogue.class
Catalogue.java
Entry.class
```

**Um arquivo-fonte, dois arquivos de classe.** A JVM nunca vê arquivos `.java`; ela carrega um
`.class` por classe, e o `javac` escreveu um para cada. `Entry` agora é package-private, o nível da
seção 02, então só classes do mesmo pacote podem usá-la, o que é exatamente o certo para uma classe
auxiliar que existe só para servir `Catalogue`.

Na prática quase toda classe ganha um arquivo próprio, pública ou não, porque um arquivo com o nome
do que guarda é o que as pessoas encontram. Uma pequena auxiliar não pública no arquivo de quem a usa
é a exceção comum. A lição 17 mostra uma terceira opção, uma classe declarada dentro de outra.
