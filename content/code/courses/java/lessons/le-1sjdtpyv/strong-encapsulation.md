---
title: Strong encapsulation, and reflection that stops at the wall
version: 1
---

Lesson 39 read a field through reflection and noted that a `private` one needs `setAccessible(true)`
first. **For twenty years that call opened anything**: private fields of your own classes, of a
library's, of the JDK's. Frameworks used it, and so did code that reached into `String` or into a
library's internals because it was faster than asking. A module's wall stops that too, and the rule
has a name: **strong encapsulation**. A package the module does not open cannot be reached by
reflection, from anywhere outside it.

## Reflection into an unexported package

`Peek` lives in the app module and tries what `Shortcut` could not do at compile time, by name and at
run time: load `Index`, build one, and read its private `titles` map:

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

The first run failed before it reached `setAccessible`. Building an `Index` through its constructor
already needs the class to be accessible, and **the message says exactly why it is not**: `module
com.example.library does not export com.example.library.internal to module com.example.app`. Reflection
asks the same question the compiler asked, and gets the same answer.

The second run passed `--add-opens`, which opens one package of one module to another, for this run
only, from the command line. It worked, and the map came out, sorted by its ISBNs because `Peek` copies
it into a `TreeMap`. **`--add-opens` is the escape hatch**, and a deliberate one. Whoever starts
the program has to type the module, the package and who may look, so a reach into somebody else's
internals is written down where an operator sees it rather than hidden in a line of code. The module
can say the same thing about itself with `opens com.example.library.internal;` in its declaration,
which is what a library does when a framework is meant to read its classes by reflection.

## The same program on the class path

Modules only bind code that runs as modules. Put the same two directories on the class path and the
`module-info.class` files are ignored:

```
ana@vm:~/modules$ java -cp out/com.example.library:out/com.example.app com.example.app.Peek
{978-0-13-468599-1=Effective Java, 978-0-596-00920-5=Java Concurrency in Practice}
```

**No flag, and the wall is gone.** On the class path every package of every jar is open to every other,
as it was before Java 9. That is not a loophole somebody forgot: it is how nearly all Java software
still runs, and section 05 comes back to it.

## The wall the JDK built around itself

The one wall that applies to everybody is the JDK's. Since Java 9 the JDK itself is made of modules,
and since Java 17 it keeps its internals closed by default, apart from a few kept open on
purpose, such as the `sun.misc.Unsafe` that Maven's warning named in lesson 18. This program runs on the class path, from
source, with no module of its own, and asks for the private array inside a `String`:

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

`InaccessibleObjectException`, from `setAccessible` itself this time: `module java.base does not "opens
java.lang" to unnamed module`. The **unnamed module** is what the class path is to the module system:
every class that is not in a module belongs to it. The `@1188e820` after it identifies that module
object and is not something to read; it may differ from run to run.

This is the error most Java developers meet first, without ever having written a `module-info.java`.
An old library that reflects into the JDK fails with exactly this line when the JDK under it is
upgraded. The fix is a newer version of the library, and the stopgap is to start the JVM with the
`--add-opens` the message implies.
