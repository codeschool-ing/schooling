---
title: `break`, `continue` e rótulos
version: 1
---

Duas instruções mudam o rumo de um laço de dentro do corpo dele. **O `break` sai do laço na hora. O
`continue` pula o resto desta volta e segue para a próxima.** Cada um age sobre o laço mais interno à
sua volta, e esse laço mais interno é exatamente onde buscas aninhadas dão errado:

```java
// Search.java
public class Search {
    public static void main(String[] args) {
        int[] years = {1899, 1881, 1928, 1943};
        for (int y : years) {
            if (y < 1900) {
                continue;
            }
            System.out.println("20th century: " + y);
        }

        String[][] shelves = {
            {"Iracema", "O Guarani"},
            {"Dom Casmurro", "Quincas Borba"},
            {"Macunaíma"}
        };
        String wanted = "Dom Casmurro";

        for (int s = 0; s < shelves.length; s++) {
            for (int p = 0; p < shelves[s].length; p++) {
                if (shelves[s][p].equals(wanted)) {
                    System.out.println("break: found at " + s + "/" + p);
                    break;
                }
            }
            System.out.println("break: finished shelf " + s);
        }

        search:
        for (int s = 0; s < shelves.length; s++) {
            for (int p = 0; p < shelves[s].length; p++) {
                if (shelves[s][p].equals(wanted)) {
                    System.out.println("break search: found at " + s + "/" + p);
                    break search;
                }
            }
            System.out.println("break search: finished shelf " + s);
        }

        int copies = 0;
        while (true) {
            copies++;
            if (copies * 70 >= 300) {
                break;
            }
        }
        System.out.println(copies + " copies of 70 pages cover 300");
    }
}
```

```
ana@vm:~/loops$ java Search.java
20th century: 1928
20th century: 1943
break: finished shelf 0
break: found at 1/0
break: finished shelf 1
break: finished shelf 2
break search: finished shelf 0
break search: found at 1/0
5 copies of 70 pages cover 300
```

## `continue`

O primeiro laço imprimiu só os anos a partir de 1900. Para 1899 e 1881, o `continue` saltou direto
para a volta seguinte, passando por cima do `println`. É um jeito de dizer "este não" no topo de um
corpo, em vez de embrulhar o resto dele num `if`, e uma guarda curta como esta é onde ele fica mais
legível.

## O `break` sai de um laço, o mais interno

A segunda busca encontrou o livro na prateleira 1, **e depois seguiu para a prateleira 2**. O `break`
saiu do laço de dentro, sobre os lugares de uma prateleira, e o laço de fora, sobre as prateleiras,
continuou como se nada tivesse acontecido, imprimindo `finished shelf 1` e `finished shelf 2`. Numa
biblioteca de duzentas prateleiras, é uma busca que acha o livro e depois confere as outras cento e
noventa e oito.

## Um rótulo nomeia o laço de onde sair

A terceira busca pôs um **rótulo**, `search:`, na frente do laço de fora, e `break search` saiu desse
laço pelo nome. A saída para em `found at 1/0`: nada de `finished shelf 1`, nada de prateleira 2. Um
rótulo é qualquer nome seguido de dois-pontos, escrito logo antes de um laço, e `continue search`
funcionaria do mesmo jeito, indo para a próxima volta do laço de fora. Rótulos são raros, e tudo bem;
a alternativa aqui é um `boolean found` conferido pelo laço de fora, ou pôr a busca num método que dá
`return`, o que a lição 13 torna possível.

## `while (true)` com um `break`

O último laço não tem condição própria. Ele roda até o `if` lá dentro sair com `break`: depois de 5
cópias de 70 páginas, 350 cobrem 300. **Essa forma é honesta quando o teste só pode ser feito no meio
do corpo**, depois de algo ser lido ou calculado. Quando o teste cabe no cabeçalho do laço, ponha-o
ali, onde o leitor o procura.
