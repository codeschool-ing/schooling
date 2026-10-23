---
title: Métodos final e classes final
version: 1
---

A lição 20 apresenta a herança direito: uma classe pode **estender** (extend) outra, herdar os seus
atributos e métodos, e substituir um método por uma versão própria, o que se chama *sobrescrever*
(override). Dois usos do `final` existem para limitar isso, e é mais fácil vê-los antes de a herança
ficar familiar, só com a linha `class Dvd extends Item` para ler. Num diretório novo, `~/final2`:

```java
// Item.java
class Item {
    String title = "Untitled";

    final String label() {
        return "[" + title + "]";
    }
}
```

```java
// Dvd.java
class Dvd extends Item {
    String label() {
        return "DVD " + title;
    }
}
```

```
ana@vm:~/final2$ javac Dvd.java
Dvd.java:3: error: label() in Dvd cannot override label() in Item
    String label() {
           ^
  overridden method is final
1 error
```

**Um método `final` não pode ser sobrescrito.** O `Item` decidiu que o rótulo de todo item tem uma
forma só, e nenhuma subclasse pode mudá-la. Isso importa quando outro código de `Item` depende de o
`label()` se comportar exatamente como foi escrito: uma subclasse que o substituísse mudaria o
comportamento de métodos em que ela nunca tocou.

## Uma classe que ninguém pode estender

O `final` numa classe vai além: **nenhuma classe pode estendê-la.**

```java
// Isbn.java
final class Isbn {
    final String value;

    Isbn(String value) {
        this.value = value;
    }
}
```

```java
// FakeIsbn.java
class FakeIsbn extends Isbn {
    FakeIsbn() {
        super("000");
    }
}
```

```
ana@vm:~/final2$ javac FakeIsbn.java
FakeIsbn.java:2: error: cannot inherit from final Isbn
class FakeIsbn extends Isbn {
                       ^
1 error
```

(O `super("000")` chama o construtor de `Isbn`, o que a lição 20 explica; o compilador recusou a
classe antes de chegar lá.) O JDK faz o mesmo com classes que você usa todo dia:

```java
// MyString.java
class MyString extends String {
}
```

```
ana@vm:~/final2$ javac MyString.java
MyString.java:2: error: cannot inherit from final String
class MyString extends String {
                       ^
1 error
ana@vm:~/final2$ javap java.lang.String | head -2
Compiled from "String.java"
public final class java.lang.String implements java.io.Serializable, java.lang.Comparable<java.lang.String>, java.lang.CharSequence, java.lang.constant.Constable, java.lang.constant.ConstantDesc {
```

## Por que a `String` é final

A lição 7 mostrou que uma `String` nunca muda depois de criada. Essa promessa é a base do resto da
plataforma: strings são chaves de mapas, nomes de classes e de arquivos, partes de verificações de
segurança. Uma subclasse de `String` poderia acrescentar um método que mudasse os caracteres, e então
um valor conferido uma vez poderia estar diferente na hora do uso. **Tornar a classe final é o único
jeito de a promessa valer para toda `String` em todo programa**, porque uma promessa que uma subclasse
consegue quebrar não é promessa.

O custo é real: você não consegue acrescentar métodos próprios à `String`, e o que quiser fazer com
strings vai num método estático de outra classe, como o `Isbns` da lição 15. Para as suas próprias
classes, o conselho comum é torná-las final a menos que tenham sido pensadas para ser estendidas, e a
lição 20 mostra o que uma classe precisa acertar antes de poder ser estendida com segurança.
