---
title: What does not dispatch
version: 1
---

Dynamic dispatch covers one thing: **instance methods that can be overridden**. Everything else a
class has is bound by the compiler, from the declared type, and a subclass that declares something
with the same name does not replace it but hides it. The mistake this produces is a program that
prints the parent's value where you expected the child's, without an error anywhere.

## A parent and a child that both declare everything

In `~/binding/hiding`, a parent with one of each kind of member:

```java
// Parent.java
public class Parent {
    public String name = "parent field";

    public static String kind() {
        return "parent static";
    }

    public String who() {
        return "parent method";
    }

    public String callSecret() {
        return secret();
    }

    private String secret() {
        return "parent private";
    }
}
```

And a child that declares the same four names again:

```java
// Child.java
public class Child extends Parent {
    public String name = "child field";

    public static String kind() {
        return "child static";
    }

    @Override
    public String who() {
        return "child method";
    }

    private String secret() {
        return "child private";
    }
}
```

`@Override` sits on `who()` alone, because it is the only one of the four that overrides. Put it on
`kind()` or `secret()` and the compiler refuses, as lesson 24 showed for a typo.

## The same object, through two declared types

```java
// Hiding.java
public class Hiding {
    public static void main(String[] args) {
        Parent p = new Child();
        System.out.println(p.who());
        System.out.println(p.name);
        System.out.println(p.kind());
        System.out.println(p.callSecret());

        Child c = (Child) p;
        System.out.println(c.name);
        System.out.println(c.kind());
    }
}
```

```
ana@vm:~/binding/hiding$ javac *.java && java Hiding
child method
parent field
parent static
parent private
child field
child static
```

One object, a `Child`, read first through a `Parent` variable and then through a `Child` one:

| member | through `Parent p` | through `Child c` | bound by |
|---|---|---|---|
| `who()`, an instance method | `child method` | | the object, at run time |
| `name`, a field | `parent field` | `child field` | the declared type, at compile time |
| `kind()`, a `static` method | `parent static` | `child static` | the declared type, at compile time |
| `secret()`, a `private` method | `parent private` | | the class that calls it |

**Only the method followed the object.** The child has two fields called `name`, its own and the
one it inherited, and which one you read depends on the variable you read it through. The static
`kind()` belongs to a class, not to an object; calling it through `p` is legal but misleading, and
the compiler simply used `p`'s declared class.

## The bytecode says it plainly

```
ana@vm:~/binding/hiding$ javap -c Hiding | grep -E "getfield|invoke"
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: invokespecial #9                  // Method Child."<init>":()V
        12: invokevirtual #16                 // Method Parent.who:()Ljava/lang/String;
        15: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        22: getfield      #28                 // Field Parent.name:Ljava/lang/String;
        25: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        33: invokestatic  #32                 // Method Parent.kind:()Ljava/lang/String;
        36: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        43: invokevirtual #35                 // Method Parent.callSecret:()Ljava/lang/String;
        46: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        58: getfield      #38                 // Field Child.name:Ljava/lang/String;
        61: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        69: invokestatic  #39                 // Method Child.kind:()Ljava/lang/String;
        72: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
```

`who()` was compiled as `invokevirtual`, so the JVM chose the body. **The field reads are
`getfield Parent.name` and `getfield Child.name`**, two different fields named in the instruction
itself, and the static calls are `invokestatic` of `Parent.kind` and `Child.kind`. Nothing is left
for run time to decide.

The private method is the subtle one:

```
ana@vm:~/binding/hiding$ javap -c -p Parent | grep -A3 "callSecret()"
  public java.lang.String callSecret();
    Code:
         0: aload_0
         1: invokevirtual #19                 // Method secret:()Ljava/lang/String;
```

Since Java 11, `javac` calls even a private method with `invokevirtual`. It makes no difference to
the result: **a private method is invisible to every subclass, so it is never overridden**, and the
JVM selects `Parent.secret` because the method it names is private. `Child.secret` is a second,
unrelated method that happens to share the name, which is why `callSecret()` printed `parent
private`.

The rule to keep: if you want a subclass to change behaviour, give it an overridable instance
method. Fields stay private behind accessors, as lesson 22 argued, and a static method is called on
its class's name, never through a variable, so nobody reading the call is misled.
