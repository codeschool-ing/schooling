---
title: Quando usar
version: 1
---

**Use `volatile` quando toda escrita no campo não depender do valor atual dele, e o campo valer
sozinho.** Essa regra, da discussão da palavra na especificação original, cobre os casos em que ele é
certo e exclui aqueles em que não é:

| uso | o `volatile` é | por quê |
|---|---|---|
| uma flag de parada ou um status escrito por uma thread e lido por outras | certo | cada escrita é uma atribuição simples |
| uma referência a um objeto imutável, trocada inteira | certo | o `PriceList` da seção 05 da aula 12 |
| uma flag "pronto" guardando dados escritos antes dela | certo | a entrega da seção 03 |
| um contador, um total, um máximo corrente | **errado** | o valor novo depende do antigo |
| dois campos que precisam mudar juntos, um mínimo e um máximo | **errado** | cada um é visível sozinho, nunca como par |

## Inicialização preguiçosa, feita uma vez

O único padrão conhecido que combina `volatile` com um lock é a inicialização preguiçosa de algo caro,
para que seja montado no primeiro uso e uma vez só:

```java
// Lazy.java: build an expensive object once, on first use, safely
public class Lazy {
    record Index(int entries) {}

    private static volatile Index index;

    static Index index() {
        Index local = index;
        if (local == null) {
            synchronized (Lazy.class) {
                local = index;
                if (local == null) {
                    System.out.println("building the index");
                    local = new Index(12);
                    index = local;
                }
            }
        }
        return local;
    }

    public static void main(String[] args) throws InterruptedException {
        Thread a = Thread.ofPlatform().start(() -> System.out.println("a got " + index()));
        Thread b = Thread.ofPlatform().start(() -> System.out.println("b got " + index()));
        a.join();
        b.join();
    }
}
```

```
ana@vm:~/fp/volatile$ java Lazy.java
building the index
b got Index[entries=12]
a got Index[entries=12]
```

O índice foi montado uma vez, e as duas threads o receberam. A primeira verificação, fora do lock,
mantém o caminho rápido livre de lock quando o objeto já existe; a segunda, dentro, impede que duas
threads que viram `null` montem as duas; e **o `volatile` é o que torna o objeto publicado seguro de
ler no caminho rápido**, pela promessa de ordem da seção 03. Sem ele, uma thread poderia ver a
referência antes dos campos do objeto, que é a publicação insegura da seção 05 da aula 12. A aula 14
explica o `synchronized`.

Costuma haver um jeito mais simples. Um campo estático de uma classe aninhada é inicializado pela JVM,
de forma preguiçosa e segura, na primeira vez que a classe é usada; e quando "caro" acaba significando
alguns milissegundos na inicialização, montar o objeto logo de cara é mais simples ainda. Use o padrão
acima quando tiver medido que precisa dele.
