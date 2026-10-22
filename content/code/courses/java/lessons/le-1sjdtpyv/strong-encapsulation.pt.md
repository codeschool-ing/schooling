---
title: Encapsulamento forte, e reflexão que para no muro
version: 1
---

A lição 39 leu um campo por reflexão e notou que um campo `private` precisa antes de um
`setAccessible(true)`. **Durante vinte anos essa chamada abriu qualquer coisa**: campos privados das
suas classes, os de uma biblioteca, os do JDK. Frameworks a usavam, e também código que mexia dentro
de `String` ou nas entranhas de uma biblioteca porque era mais rápido que pedir. O muro de um módulo
barra isso também, e a regra tem nome: **encapsulamento forte**. Um pacote que o módulo não abre não
pode ser alcançado por reflexão, de lugar nenhum fora dele.

## Reflexão num pacote não exportado

O `Peek` mora no módulo app e tenta, pelo nome e em tempo de execução, o que o `Shortcut` não conseguiu
na compilação: carregar o `Index`, construir um, e ler o mapa privado `titles`:

```java
// src/com.example.app/com/example/app/Peek.java
package com.example.app;

import java.lang.reflect.Field;
import java.util.Map;
import java.util.TreeMap;

public class Peek {
    public static void main(String[] args) throws Exception {
        Class<?> type = Class.forName("com.example.library.internal.Index");
        Object index = type.getDeclaredConstructor().newInstance();
        Field titles = type.getDeclaredField("titles");
        titles.setAccessible(true);
        System.out.println(new TreeMap<>((Map<?, ?>) titles.get(index)));
    }
}
```

```
ana@vm:~/modules$ javac -d out --module-source-path src -m com.example.library,com.example.app
ana@vm:~/modules$ java --module-path out -m com.example.app/com.example.app.Peek
Exception in thread "main" java.lang.IllegalAccessException: class com.example.app.Peek (in module com.example.app) cannot access class com.example.library.internal.Index (in module com.example.library) because module com.example.library does not export com.example.library.internal to module com.example.app
	at java.base/jdk.internal.reflect.Reflection.newIllegalAccessException(Reflection.java:400)
	at java.base/java.lang.reflect.AccessibleObject.checkAccess(AccessibleObject.java:670)
	at java.base/java.lang.reflect.Constructor.newInstanceWithCaller(Constructor.java:492)
	at java.base/java.lang.reflect.Constructor.newInstance(Constructor.java:483)
	at com.example.app/com.example.app.Peek.main(Peek.java:11)
ana@vm:~/modules$ java --module-path out --add-opens com.example.library/com.example.library.internal=com.example.app -m com.example.app/com.example.app.Peek
{978-0-13-468599-1=Effective Java, 978-0-596-00920-5=Java Concurrency in Practice}
```

A primeira execução falhou antes de chegar ao `setAccessible`. Construir um `Index` pelo construtor já
exige que a classe seja acessível, e **a mensagem diz exatamente por que ela não é**: `module
com.example.library does not export com.example.library.internal to module com.example.app`. A
reflexão faz a mesma pergunta que o compilador fez, e recebe a mesma resposta.

A segunda execução passou `--add-opens`, que abre um pacote de um módulo para outro, só nesta execução,
pela linha de comando. Funcionou, e o mapa saiu, ordenado pelos ISBNs porque o `Peek` o copia num
`TreeMap`. **O `--add-opens` é a saída de emergência**, e uma saída deliberada. Quem inicia o programa
precisa digitar o módulo, o pacote e quem pode olhar, então um alcance nas entranhas de outra pessoa
fica escrito onde um operador vê, e não escondido numa linha de código. O módulo pode dizer o mesmo
sobre si próprio com `opens com.example.library.internal;` na declaração, que é o que uma biblioteca
faz quando um framework deve ler as classes dela por reflexão.

## O mesmo programa no class path

Módulos só amarram código que roda como módulo. Ponha os mesmos dois diretórios no class path e os
arquivos `module-info.class` são ignorados:

```
ana@vm:~/modules$ java -cp out/com.example.library:out/com.example.app com.example.app.Peek
{978-0-13-468599-1=Effective Java, 978-0-596-00920-5=Java Concurrency in Practice}
```

**Nenhuma opção, e o muro sumiu.** No class path todo pacote de todo jar é aberto a todos os outros,
como era antes do Java 9. Isso não é uma brecha que alguém esqueceu: é como quase todo software Java
ainda roda, e a seção 05 volta a isso.

## O muro que o JDK construiu em volta de si

O único muro que vale para todo mundo é o do JDK. Desde o Java 9 o próprio JDK é feito de módulos, e
desde o Java 17 ele mantém as entranhas fechadas por padrão, fora umas poucas deixadas abertas de
propósito, como o `sun.misc.Unsafe` que o aviso do Maven citou na lição 18. Este programa roda no class
path, a partir do fonte, sem módulo próprio, e pede o array privado de dentro de uma `String`:

```java
// Bytes.java
import java.lang.reflect.Field;

public class Bytes {
    public static void main(String[] args) throws Exception {
        Field value = String.class.getDeclaredField("value");
        value.setAccessible(true);
        System.out.println(((byte[]) value.get("loan")).length);
    }
}
```

```
ana@vm:~/modules$ java Bytes.java
Exception in thread "main" java.lang.reflect.InaccessibleObjectException: Unable to make field private final byte[] java.lang.String.value accessible: module java.base does not "opens java.lang" to unnamed module @1188e820
	at java.base/java.lang.reflect.AccessibleObject.throwInaccessibleObjectException(AccessibleObject.java:353)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:329)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:277)
	at java.base/java.lang.reflect.Field.checkCanSetAccessible(Field.java:179)
	at java.base/java.lang.reflect.Field.setAccessible(Field.java:173)
	at Bytes.main(Bytes.java:7)
```

`InaccessibleObjectException`, desta vez vinda do próprio `setAccessible`: `module java.base does not
"opens java.lang" to unnamed module`. O **módulo sem nome** é o que o class path é para o sistema de
módulos: toda classe que não está num módulo pertence a ele. O `@1188e820` depois dele identifica esse
objeto módulo e não é coisa para ler; pode mudar de uma execução para outra.

Esse é o erro que a maioria dos desenvolvedores Java encontra primeiro, sem nunca ter escrito um
`module-info.java`. Uma biblioteca antiga que faz reflexão no JDK falha com exatamente essa linha
quando o JDK debaixo dela é atualizado. A correção é uma versão mais nova da biblioteca, e o paliativo
é iniciar a JVM com o `--add-opens` que a mensagem sugere.
