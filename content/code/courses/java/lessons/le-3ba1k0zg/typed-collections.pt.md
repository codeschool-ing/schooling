---
title: O que os colchetes angulares compram
version: 1
---

Toda coleção das lições 31 a 34 foi escrita com um tipo entre colchetes angulares: `List<String>`,
`Map<String, Integer>`. Esses colchetes são os **generics**, e chegaram no Java 5, em 2004. Antes
disso uma `List` guardava `Object`, qualquer coisa, e cada elemento saía como um `Object` a ser
convertido de volta no que você esperava que ele fosse. **Os colchetes passam a esperança para o
compilador, onde ela vira uma verificação.**

O Java ainda compila a forma antiga, chamada **tipo cru** (raw type), para que o código de antes de
2004 continue compilando. Ela serve bem para mostrar o que os colchetes evitam. Salve isto num
diretório novo, `~/generics`:

```java
// Raw.java
import java.util.ArrayList;
import java.util.List;

public class Raw {
    static List titles() {
        List list = new ArrayList();
        list.add("Dune");
        list.add("Emma");
        list.add(1965);                 // a year, by mistake
        return list;
    }

    public static void main(String[] args) {
        List shelf = titles();
        for (Object o : shelf) {
            String title = (String) o;
            System.out.println(title.toUpperCase());
        }
    }
}
```

```
ana@vm:~/generics$ javac Raw.java
Note: Raw.java uses unchecked or unsafe operations.
Note: Recompile with -Xlint:unchecked for details.
ana@vm:~/generics$ javac -Xlint:unchecked Raw.java
Raw.java:8: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add("Dune");
                ^
  where E is a type-variable:
    E extends Object declared in interface List
Raw.java:9: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add("Emma");
                ^
  where E is a type-variable:
    E extends Object declared in interface List
Raw.java:10: warning: [unchecked] unchecked call to add(E) as a member of the raw type List
        list.add(1965);                 // a year, by mistake
                ^
  where E is a type-variable:
    E extends Object declared in interface List
3 warnings
ana@vm:~/generics$ java Raw
DUNE
EMMA
Exception in thread "main" java.lang.ClassCastException: class java.lang.Integer cannot be cast to class java.lang.String (java.lang.Integer and java.lang.String are in module java.base of loader 'bootstrap')
	at Raw.main(Raw.java:17)
```

Leia os três comandos em ordem. O `javac` simples compilou o arquivo e acrescentou duas linhas
`Note:`, fáceis de passar por cima. Com `-Xlint:unchecked` as notas viraram três avisos, um por
`add`: **o compilador não conseguiu conferir o que entrou numa lista crua**, e disse isso. Depois o
programa rodou, imprimiu dois títulos, e falhou no terceiro elemento com um `ClassCastException`.

A exceção aponta para a linha 17, a conversão no `main`. **O erro está na linha 10**, em outro método,
onde um ano entrou numa lista de títulos. Neste arquivo os dois estão a sete linhas de distância; num
programa de verdade podem estar em classes diferentes, escritas por pessoas diferentes, e o stack
trace só nomeia o lugar onde o estrago foi encontrado.

## O mesmo programa, com um tipo

O `Typed.java` é o mesmo programa com `<String>` escrito. Nada mais mudou:

```java
// Typed.java
import java.util.ArrayList;
import java.util.List;

public class Typed {
    static List<String> titles() {
        List<String> list = new ArrayList<>();
        list.add("Dune");
        list.add("Emma");
        list.add(1965);                 // a year, by mistake
        return list;
    }

    public static void main(String[] args) {
        for (String title : titles()) {
            System.out.println(title.toUpperCase());
        }
    }
}
```

```
ana@vm:~/generics$ javac Typed.java
Typed.java:10: error: incompatible types: int cannot be converted to String
        list.add(1965);                 // a year, by mistake
                 ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

**O programa não compila, e o erro está na linha 10**, no `add` errado, antes de qualquer coisa rodar.
Essa é a barganha inteira: o tipo entre colchetes é uma promessa sobre cada elemento, e o compilador
cobra essa promessa de cada linha do programa. A conversão sumiu também; o `for-each` recebe
`String`s porque o tipo da lista diz que é só isso que ela guarda.

Então a regra é curta. **Nunca escreva um tipo cru em código novo**, e trate a nota `unchecked` como
um aviso, e não como ruído: ela quer dizer que alguma linha do arquivo deixou um valor não conferido
entrar numa coleção.
