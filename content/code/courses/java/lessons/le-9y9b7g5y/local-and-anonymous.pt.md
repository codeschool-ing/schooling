---
title: Classes sem nome, e classes dentro de um método
version: 1
---

Os dois últimos tipos de classe aninhada são declarados **dentro de um método**. Uma **classe local**
tem um nome que só aquele método pode usar. Uma **classe anônima** não tem nome nenhum: é declarada e
instanciada numa única expressão, no lugar onde é necessária, e foi o jeito de o código Java passar um
pedaço de comportamento para um método por quase vinte anos.

## Uma classe anônima: comportamento como argumento

`Arrays.sort` põe um array em ordem. Com strings, a ordem é pelo código dos caracteres, e toda letra
maiúscula vem antes de toda minúscula, o que põe no fim um título que começa com letra minúscula. Para
ordenar de outro jeito, você entrega ao `sort` um objeto que compara duas strings do seu jeito, um
`Comparator`. Escrever uma classe com nome para uma única comparação é cerimônia demais, então esta é
anônima:

```java
// Sorting.java
import java.util.Arrays;
import java.util.Comparator;

public class Sorting {
    public static void main(String[] args) {
        String[] titles = {"Head First Java", "effective Java", "Modern Java in Action"};
        Arrays.sort(titles);
        System.out.println(Arrays.toString(titles));

        Comparator<String> ignoringCase = new Comparator<String>() {
            @Override
            public int compare(String a, String b) {
                return a.compareToIgnoreCase(b);
            }
        };
        Arrays.sort(titles, ignoringCase);
        System.out.println(Arrays.toString(titles));
        System.out.println(ignoringCase.getClass().getName());
    }
}
```
```
ana@vm:~/nested$ javac Sorting.java && java Sorting
[Head First Java, Modern Java in Action, effective Java]
[effective Java, Head First Java, Modern Java in Action]
Sorting$1
ana@vm:~/nested$ ls Sorting*
Sorting$1.class
Sorting.class
Sorting.java
```

A primeira ordenação pôs `effective Java` por último, porque o `e` vem depois de toda maiúscula. A
segunda usou o comparador anônimo e o pôs em primeiro.

**`new Comparator<String>() { ... }` se lê como "um objeto novo de uma classe que implementa
`Comparator<String>` e tem este corpo".** `Comparator` é uma interface, então não pode ser
instanciada sozinha; as chaves depois dos parênteses fornecem o método que falta, `compare`, e a
expressão cria ali mesmo o único objeto dessa classe. A lição 23 é sobre interfaces, e o `@Override`
é da lição 24; por ora basta saber que `compare` é o método que o `sort` chama.

A classe não tem nome no código-fonte, então o compilador lhe deu um: **`Sorting$1`**, a primeira
classe anônima de `Sorting`. Foi isso que o `getClass().getName()` imprimiu e que o `ls` encontrou no
disco. Uma segunda classe anônima no mesmo arquivo seria `Sorting$2`.

**Este é o código que a lambda substituiu.** Desde o Java 8 o mesmo comparador cabe numa linha,
`(a, b) -> a.compareToIgnoreCase(b)`, e o curso seguinte a este, `java-functional`, começa por aí.
Você ainda vai ler classes anônimas em código mais antigo, e as regras abaixo valem sem mudança para
as lambdas.

## Uma classe local, e o que ela pode capturar

Uma classe local é declarada no meio dos comandos de um método, e pode usar as variáveis locais desse
método:

```java
// Overdue.java
public class Overdue {
    public static void main(String[] args) {
        int days = 14;
        class Notice {
            String text(String title) {
                return title + " is due back in " + days + " days";
            }
        }
        Notice notice = new Notice();
        System.out.println(notice.text("Effective Java"));
    }
}
```
```
ana@vm:~/nested$ javac Overdue.java && java Overdue
Effective Java is due back in 14 days
ana@vm:~/nested$ ls Overdue*
Overdue$1Notice.class
Overdue.class
Overdue.java
```

`Notice` leu `days`, uma variável local do `main`. O arquivo de classe é `Overdue$1Notice`: um número,
porque dois métodos poderiam declarar cada um o seu `Notice` local, e depois o nome.

Agora mude `days` depois de ele ter recebido valor, acrescentando uma linha, `days = 21;`, logo antes
de o aviso ser criado:

```
ana@vm:~/nested$ sed -i '/Notice notice = new Notice/i\        days = 21;' Overdue.java
ana@vm:~/nested$ javac Overdue.java
Overdue.java:7: error: local variables referenced from an inner class must be final or effectively final
                return title + " is due back in " + days + " days";
                                                    ^
1 error
```

O erro aponta para o uso dentro da classe, não para a atribuição. **Uma classe local ou anônima só
pode ler uma variável local se essa variável nunca muda depois de receber o primeiro valor**, o que o
Java chama de *effectively final* (final na prática): final de fato, esteja ou não escrita a palavra
`final`. A lição 16 dá ao termo uma seção própria.

O motivo é de novo o atributo escondido. A classe não volta a olhar as variáveis do `main` enquanto
roda; quando o objeto é criado, **o compilador copia o valor da variável para um atributo do
objeto**, do jeito que a seção 03 copiou o dono para `this$0`. Uma cópia de algo que depois mudou
seria uma segunda versão, velha, da mesma coisa, e o Java recusa em vez de deixar as duas discordarem.
Se o valor precisa mesmo mudar, ponha-o num atributo de um objeto, que os dois lados podem
compartilhar.

## Os quatro tipos, lado a lado

| tipo | declarada | presa a um objeto de fora | uso típico |
|---|---|---|---|
| aninhada estática | numa classe, com `static` | não | um tipo auxiliar que pertence a uma classe: `Map.Entry`, um builder |
| interna | numa classe, sem `static` | sim, por meio de `this$0` | um objeto que só faz sentido com o dono: a carteirinha e o sócio |
| local | entre os comandos de um método | sim, quando o método é de instância | um pequeno auxiliar usado por um método |
| anônima | numa expressão, com `new` | como a local | um objeto com uma tarefa, passado como argumento |
