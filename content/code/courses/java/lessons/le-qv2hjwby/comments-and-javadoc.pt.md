---
title: Comentários, e os que viram documentação
version: 1
---

O Java tem três tipos de comentário, e dois deles são para as pessoas que leem o código. **O terceiro
é lido por uma ferramenta**, o `javadoc`, que o transforma nas páginas web com que toda biblioteca
Java é documentada, inclusive a do próprio JDK. Um programa com os três, em `~/syntax`:

```java
// Greeter.java
/**
 * Builds the greetings the library's front desk prints.
 */
public class Greeter {
    /*
     * The desk asked for a full stop at the end,
     * so every greeting ends with one.
     */
    private static final String END = ".";

    /**
     * Returns a greeting for one member.
     *
     * @param name the member's name, as it appears on their card
     * @return the greeting, ending with a full stop
     */
    public static String greet(String name) {
        return "Welcome, " + name + END; // END is defined above
    }

    public static void main(String[] args) {
        System.out.println(greet("Ana"));
    }
}
```

| comentário | começa e termina | lido por |
|---|---|---|
| de linha | `//` até o fim da linha | pessoas |
| de bloco | `/*` até `*/`, atravessando linhas | pessoas |
| de documentação | `/**` até `*/`, logo acima de uma classe, método ou campo | pessoas e `javadoc` |

O compilador joga os três fora. `java Greeter.java` imprime exatamente o que imprimiria sem eles:

```
ana@vm:~/syntax$ java Greeter.java
Welcome, Ana.
```

## Para que serve um comentário

**Um comentário diz por quê, e o código diz o quê.** O comentário de bloco acima de `END` é do tipo
útil: ninguém adivinharia pelo `"."` que o balcão de atendimento pediu isso, e a próxima pessoa que
quiser tirar o ponto final agora sabe a quem perguntar. O comentário de linha no fim de `greet`,
`// END is defined above`, é do tipo inútil, e está ali de propósito para você ver um. Ele repete o
que qualquer leitor enxerga, e no dia em que `END` mudar de lugar ele vira mentira.

## O `javadoc`, e as páginas que ele monta

Um comentário de documentação fica logo acima do que documenta. A primeira frase dele é o resumo que
as listas mostram, e **tags** começando com `@` descrevem as partes: `@param` para cada parâmetro,
`@return` para o resultado. O `javadoc` as lê e escreve um site:

```
ana@vm:~/syntax$ javadoc -quiet -d docs Greeter.java
Greeter.java:5: warning: use of default constructor, which does not provide a comment
public class Greeter {
       ^
Greeter.java:22: warning: no comment
    public static void main(String[] args) {
                       ^
2 warnings
ana@vm:~/syntax$ ls docs | head -5
Greeter.html
allclasses-index.html
allpackages-index.html
element-list
help-doc.html
ana@vm:~/syntax$ grep -o "Returns a greeting for one member." docs/Greeter.html | head -1
Returns a greeting for one member.
```

Dois avisos, e os dois são sobre o que **não** tem comentário de documentação. O `main` não tem, e
nem o construtor que o compilador escreveu para o `Greeter`, que a lição 1 viu na saída do `javap` e
que o `javadoc` documenta como qualquer outro membro público. Avisos não o interrompem: as páginas
estão em `docs`, com o `Greeter.html` entre elas, e a frase do comentário de `greet` está nessa
página. Abra `docs/index.html` num navegador e o layout é o que a documentação do próprio JDK usa.

O `-quiet` impediu o `javadoc` de imprimir o progresso, uma linha para cada passo e para cada página
que ele grava, e os avisos passaram mesmo assim, porque um aviso é sempre mostrado. **Esse é o uso do
`javadoc` num projeto: ele é a conferência de que cada parte pública tem a sua documentação**, e as
páginas são um efeito colateral.
