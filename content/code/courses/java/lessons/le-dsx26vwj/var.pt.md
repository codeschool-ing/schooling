---
title: O `var`, e onde o tipo continua
version: 1
---

Desde o Java 10, uma variável local pode ser declarada com `var` em vez do tipo, e o compilador deduz
o tipo a partir do valor à direita. É fácil ler isso como o Java virando uma linguagem em que
variáveis não têm tipo. **É o contrário: o tipo é fixado exatamente como antes**, só que quem o escreve
é o compilador, não você. O `jshell` mostra o que ele escolheu, com as linhas de `vars.jsh`:

```
ana@vm:~/types$ cat vars.jsh
var title = "Dom Casmurro"
var year = 1899
var price = 39.90
var pages = 256L
var initial = 'D'
/vars
/exit
ana@vm:~/types$ jshell --feedback normal < vars.jsh
|  Welcome to JShell -- Version 25.0.4.1
|  For an introduction type: /help intro

jshell> title ==> "Dom Casmurro"

jshell> year ==> 1899

jshell> price ==> 39.9

jshell> pages ==> 256

jshell> initial ==> 'D'

jshell> |    String title = "Dom Casmurro"
|    int year = 1899
|    double price = 39.9
|    long pages = 256
|    char initial = 'D'

jshell> |  Goodbye
```

O `/vars` lista cada variável com o tipo que o compilador deduziu, e cada um segue as regras de
literais da seção 02. `"Dom Casmurro"` é uma `String`, `1899` um `int`, `39.90` um `double`, `256L`
um `long` por causa do sufixo, e `'D'` um `char` por causa das aspas simples. Escreva
`var pages = 256` e `pages` é um `int`, não um `long`, seja lá o que você tinha em mente.

## Três coisas que o `var` recusa

```java
// VarMistakes.java
public class VarMistakes {
    public static void main(String[] args) {
        var title;
        var author = null;
        var year = 1899;
        year = "nineteenth century";
    }
}
```

```
ana@vm:~/types$ javac VarMistakes.java
VarMistakes.java:4: error: cannot infer type for local variable title
        var title;
            ^
  (cannot use 'var' on variable without initializer)
VarMistakes.java:5: error: cannot infer type for local variable author
        var author = null;
            ^
  (variable initializer is 'null')
VarMistakes.java:7: error: incompatible types: String cannot be converted to int
        year = "nineteenth century";
               ^
3 errors
```

As três vêm do mesmo fato, que **o tipo é decidido uma vez, na declaração, pelo valor dado ali**:

1. `var title;` não dá ao compilador valor nenhum para olhar, então não há de onde deduzir.
2. `var author = null;` dá a ele um valor sem tipo próprio. `null` cabe em qualquer tipo de objeto,
   então não diz qual se queria.
3. `year = "nineteenth century";` é o importante. `year` virou `int` na linha 6, e um `int` não guarda
   uma `String` na linha 7 nem em lugar nenhum. **O `var` não cria uma variável que muda de tipo**, e
   este é o mesmo erro que daria uma variável declarada `int year`.

O `var` funciona só para variáveis locais, as que ficam dentro de um método. Um campo de uma classe,
os parâmetros de um método e o tipo de retorno dele são sempre escritos por extenso, porque são o que
o resto do código lê.

## Quando ajuda, e quando esconde

O `var` vale a pena quando o tipo já está na tela, e é comprido:

```java
var members = new java.util.ArrayList<String>();
```

`ArrayList<String>` aparece uma vez, à direita, em vez de duas. Ele custa caro quando o lado direito
não mostra o tipo, como em `var total = calculate();`. Quem lê precisa achar o `calculate` para saber
se `total` é `int`, `long` ou `double`, e a seção 02 mostrou que a diferença importa nos dois bilhões.
**Use `var` quando o tipo é óbvio pela linha, e escreva o tipo quando não é.** Este curso escreve os
tipos por extenso na maior parte dos lugares, porque um curso é lido por gente aprendendo quais são os
tipos.
