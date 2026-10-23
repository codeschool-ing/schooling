---
title: Despacho dinâmico, no arquivo de classe
version: 1
---

A seção 02 disse que o objeto decide qual sobrescrita roda. Essa decisão precisa ser tomada em algum
lugar, por alguma coisa, e não é pelo compilador: o `javac` compilou o `Desk` uma vez, e o mesmo laço
compilado rodou três métodos diferentes. **A escolha é feita pela JVM, a cada chamada, a partir da
classe do objeto.** Isso é o despacho dinâmico, também chamado de ligação tardia, e o arquivo de
classe mostra onde ele acontece.

## O que o compilador escreveu

No mesmo `~/binding`, um método que recebe qualquer `Item`:

```java
// Say.java
public class Say {
    static String say(Item item) {
        return item.describe();
    }

    public static void main(String[] args) {
        System.out.println(say(new Book("978-85-359-0277-2")));
        System.out.println(say(new Dvd()));
    }
}
```

```
ana@vm:~/binding$ javac Say.java && java Say
a book
a DVD
ana@vm:~/binding$ javap -c Say | grep -A4 "say(Item)"
  static java.lang.String say(Item);
    Code:
         0: aload_0
         1: invokevirtual #7                  // Method Item.describe:()Ljava/lang/String;
         4: areturn
```

A linha 1 de `say` é a chamada, e o compilador anotou exatamente o que sabia: **`invokevirtual`, de
`Item.describe`**. Ele não escreveu `Book.describe` nem `Dvd.describe`; nem poderia, já que `say` é
compilado uma vez e chamado com os dois. A instrução nomeia um método pelo tipo declarado e deixa o
corpo em aberto. O `java Say` então rodou a sobrescrita do livro e a do DVD a partir dessa única
linha.

## O que a JVM faz com ela

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Despacho dinâmico. O ponto de chamada no arquivo de classe diz invokevirtual Item.describe. Em tempo de execução a JVM olha o objeto para onde a referência aponta, descobre a classe dele e procura describe na tabela de métodos virtuais dessa classe. A tabela de Item liga describe a Item.describe; a de Book liga describe a Book.describe e também tem isbn; a de Dvd liga describe a Dvd.describe. Para um objeto Book a chamada executa Book.describe.\"><defs><marker id=\"jv25-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">invokevirtual Item.describe</text><text x=\"150\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escrito uma vez, pelo compilador</text><rect x=\"20\" y=\"130\" width=\"260\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o objeto na pilha é um Book</text><text x=\"150\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a classe dele é lida na chamada</text><path d=\"M150 84 L150 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv25-a)\"></path><rect x=\"380\" y=\"20\" width=\"320\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de métodos de Item</text><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe()  →  Item.describe</text><rect x=\"380\" y=\"82\" width=\"320\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de métodos de Book</text><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe()  →  Book.describe</text><text x=\"540\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn()  →  Book.isbn</text><rect x=\"380\" y=\"166\" width=\"320\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de métodos de Dvd</text><text x=\"540\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe()  →  Dvd.describe</text><path d=\"M280 158 L378 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv25-a)\"></path><rect x=\"20\" y=\"220\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda Book.describe</text><text x=\"150\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mesma instrução, outros objetos, outros corpos</text><path d=\"M150 186 L150 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "O compilador nomeia o método; a classe do objeto escolhe o corpo. Cada classe tem uma tabela dos seus métodos sobrescrevíveis, e uma sobrescrita troca uma entrada."}
```

Quando o `invokevirtual` roda, a JVM pega o objeto para onde a referência aponta, lê a classe dele e
procura o método a partir dessa classe, subindo em direção a `Object`, e fica com o primeiro corpo que
encontra. **O HotSpot não faz essa busca toda vez**: cada classe carrega uma tabela dos seus métodos
sobrescrevíveis, montada quando a classe é carregada, onde uma sobrescrita simplesmente substitui a
entrada do pai. A chamada vira uma consulta na tabela da classe do objeto.

As quatro instruções que chamam um método dizem, cada uma, como essa escolha é feita:

| instrução | usada para | o corpo é escolhido |
|---|---|---|
| `invokevirtual` | um método de instância comum de uma classe | pela classe do objeto, na execução |
| `invokeinterface` | um método chamado por um tipo de interface, como o `Lendable` da lição 23 | pela classe do objeto, na execução |
| `invokestatic` | um método `static` | pelo compilador, a partir da classe nomeada na chamada |
| `invokespecial` | um construtor, e chamadas escritas como `super.m()` | pelo compilador: exatamente o nomeado |

O despacho custa pouco na prática. O compilador JIT da lição 1 observa cada ponto de chamada, e onde
só viu uma classe até então, consegue chamar aquele corpo diretamente, ou copiá-lo no lugar, e manter
uma conferência barata para o caso de outra classe aparecer depois. Então desenhar com métodos
pequenos e sobrescrevíveis não é uma decisão de desempenho; é uma decisão de desenho, e barata.
