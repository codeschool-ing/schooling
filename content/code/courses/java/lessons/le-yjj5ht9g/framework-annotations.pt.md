---
title: O que um framework faz com uma anotação
version: 1
---

As anotações da seção 02 são lidas pelo compilador e somem depois dele. As que você mais encontra em
código Java de verdade são o contrário. `@Test` no JUnit, `@GetMapping` no Spring, `@Entity` no JPA:
**o compilador não faz nada com elas além de guardá-las**, e uma biblioteca as lê com o programa
rodando. O `java-back` constrói um serviço web exatamente sobre isso. Esta seção mostra as duas peças
que fazem isso funcionar.

## Quanto tempo uma anotação vive

Todo tipo de anotação declara a sua **retenção**, até onde ela sobrevive: só no código-fonte, até o
arquivo de classe, ou até o programa rodando. Três anotações inventadas, uma de cada, na mesma classe:

```java
// Kept.java
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

public class Kept {
    @Retention(RetentionPolicy.SOURCE)
    @interface InSource {}

    @Retention(RetentionPolicy.CLASS)
    @interface InClassFile {}

    @Retention(RetentionPolicy.RUNTIME)
    @interface AtRunTime {}

    @InSource @InClassFile @AtRunTime
    static class Target {}

    public static void main(String[] args) {
        for (var a : Target.class.getAnnotations()) {
            System.out.println(a);
        }
    }
}
```

```
ana@vm:~/annot$ javac Kept.java && java Kept
@Kept.AtRunTime()
ana@vm:~/annot$ javap -v "Kept\$Target.class" | grep -A2 "Annotations:"
RuntimeVisibleAnnotations:
  0: #14()
    Kept$AtRunTime
RuntimeInvisibleAnnotations:
  0: #16()
    Kept$InClassFile
```

Três anotações foram para o `Target` e **o programa rodando viu uma**, a `@AtRunTime`. O arquivo de
classe mostra para onde foram as outras duas. O `javap -v` lista a `AtRunTime` em
`RuntimeVisibleAnnotations` e a `InClassFile` em `RuntimeInvisibleAnnotations`: gravada no arquivo de
classe, e não carregada pela JVM. A `InSource` não está em nenhuma das duas, porque o compilador a
descartou depois de compilar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Quanto vive cada retenção. Em Kept.java as três anotações estão presentes. O javac escreve Kept$Target.class com InClassFile e AtRunTime e descarta InSource. Quando java Kept roda, a JVM carrega só AtRunTime, a única que a reflexão enxerga.\"><defs><marker id=\"jv39-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kept.java</text><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o código-fonte</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kept$Target.class</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o arquivo de classe</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">java Kept</text><text x=\"610\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o programa rodando</text><path d=\"M200 120 H268\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv39-a)\"></path><text x=\"234\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">javac</text><path d=\"M450 120 H518\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv39-a)\"></path><text x=\"484\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">JVM</text><rect x=\"40\" y=\"88\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InSource</text><rect x=\"40\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InClassFile</text><rect x=\"290\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@InClassFile</text><rect x=\"40\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><rect x=\"290\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><rect x=\"540\" y=\"172\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@AtRunTime</text><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada passo guarda menos: SOURCE para no javac, CLASS para na JVM</text></svg>", "caption": "Três anotações entram no código-fonte e uma sai do outro lado. Só RUNTIME chega ao código que roda."}
```

| retenção | onde sobrevive | quem a lê |
|---|---|---|
| `SOURCE` | só no arquivo `.java` | o compilador e ferramentas de código-fonte: `@Override`, `@SuppressWarnings` |
| `CLASS` (o padrão) | no arquivo `.class`, não na JVM rodando | ferramentas que leem bytecode |
| `RUNTIME` | no programa rodando | código que usa reflexão: todo framework |

O arquivo de classe de `Target` se chama `Kept$Target.class`, como a lição 17 explicou para uma classe
aninhada, e as aspas e a barra invertida impedem o shell de ler `$Target` como uma variável.

## Um framework em vinte linhas

**Reflexão** é a parte da biblioteca que deixa um programa examinar classes enquanto roda: listar os
métodos de uma classe, pedir a um método as anotações dele, chamá-lo pelo nome. Um framework de testes
é quase só isso. Este roda todo método marcado com uma anotação `RUNTIME` chamada `@Check`:

```java
// Check.java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Check {}
```

As conferências, num pequeno validador de ISBN. Um ISBN de 13 dígitos termina num dígito verificador
calculado a partir dos outros doze, então um erro de digitação num dígito é pego:

```java
// LoanChecks.java
public class LoanChecks {
    static boolean validIsbn(String isbn) {
        String d = isbn.replace("-", "");
        int sum = 0;
        for (int i = 0; i < 12; i++) {
            sum += (d.charAt(i) - '0') * (i % 2 == 0 ? 1 : 3);
        }
        return d.length() == 13 && (10 - sum % 10) % 10 == d.charAt(12) - '0';
    }

    @Check
    public void acceptsEffectiveJava() {
        if (!validIsbn("978-0-13-468599-1")) throw new AssertionError("rejected 978-0-13-468599-1");
    }

    @Check
    public void rejectsATypo() {
        if (validIsbn("978-0-13-468599-2")) throw new AssertionError("accepted 978-0-13-468599-2");
    }

    @Check
    public void acceptsTheSecondBook() {
        if (!validIsbn("978-1-61729-136-8")) throw new AssertionError("rejected 978-1-61729-136-8");
    }

    public void helper() {
        System.out.println("helper ran");
    }
}
```

```java
// Runner.java
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class Runner {
    public static void main(String[] args) throws Exception {
        Class<?> type = Class.forName(args[0]);
        Object instance = type.getDeclaredConstructor().newInstance();
        for (Method m : type.getDeclaredMethods()) {
            if (m.isAnnotationPresent(Check.class)) {
                try {
                    m.invoke(instance);
                    System.out.println("passed: " + m.getName());
                } catch (InvocationTargetException e) {
                    System.out.println("FAILED: " + m.getName() + ": " + e.getCause().getMessage());
                }
            }
        }
    }
}
```

```
ana@vm:~/annot$ javac Check.java LoanChecks.java Runner.java && java Runner LoanChecks
passed: acceptsEffectiveJava
passed: rejectsATypo
FAILED: acceptsTheSecondBook: rejected 978-1-61729-136-8
```

O `Runner` recebeu só o nome da classe, como string, e achou sozinho os três métodos marcados; o
`helper` nunca foi chamado, porque não tem `@Check`. Esse é o truque inteiro por trás do JUnit, do
tamanho de uma lição. **A terceira conferência falhou, e falhou com razão.** O `978-1-61729-136-8` tem
um dígito verificador que não bate com os doze primeiros dígitos: foi inventado para os exemplos das
lições 37 e 38 e ninguém nunca o calculou. Uma conferência achou um erro de verdade nos dados do
próprio curso.

Dois detalhes da saída merecem um segundo olhar. Um método chamado por reflexão que lança tem a exceção
embrulhada numa `InvocationTargetException`, com a original como causa, da lição 38, então o `Runner`
relata o `e.getCause()`. E o `getDeclaredMethods()` não promete ordem nenhuma. Aqui eles saíram na
ordem em que foram escritos, e um framework que quer uma ordem tem de ordenar por conta própria.
