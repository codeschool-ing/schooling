---
title: O primeiro programa, linha por linha
version: 1
---

A lição 1 executou o `Hello.java` sem lê-lo. São cinco linhas, e quatro delas são cerimônia que um
iniciante fica tentado a copiar sem olhar. **Cada uma dessas linhas é uma regra da linguagem**, e todo
arquivo que você escrever neste curso segue as mesmas regras. Aqui está ele de novo, num diretório
para esta lição, `~/syntax`:

```schooling-example
{
  "language": "java",
  "file": "Hello.java",
  "parts": [
    {
      "code": "public class Hello {",
      "note": "**Toda linha de código Java vive dentro de uma classe.** `class Hello` declara uma, `public` deixa qualquer código usá-la, e as chaves guardam tudo o que pertence a ela. Uma classe pública precisa estar num arquivo com o nome dela, `Hello.java`, e a seção 03 mostra o erro quando não está."
    },
    {
      "code": "    public static void main(String[] args) {",
      "note": "**O ponto de entrada, e cada palavra dele é obrigatória.** `java Hello` procura um método exatamente com esta forma: `public` para o lançador poder chamá-lo, `static` para rodar sem um objeto (lição 15), `void` porque não devolve nada, e `String[] args` para a linha de comando, como a lição 2 usou."
    },
    {
      "code": "        System.out.println(\"Hello, Java\");",
      "note": "**Uma instrução, terminada por ponto e vírgula.** `System` é uma classe da biblioteca, `out` é o campo dela para a saída padrão, e `println` imprime uma linha. Os pontos caminham de um para o outro, e o texto entre aspas duplas é uma `String`."
    },
    {
      "code": "    }\n}",
      "note": "**Duas chaves de fechamento, a do método e a da classe.** A indentação é para pessoas: quatro espaços por nível é o estilo comum, e o compilador aceitaria o arquivo inteiro numa linha só."
    }
  ]
}
```

```
ana@vm:~/syntax$ java Hello.java
Hello, Java
```

## Instruções, blocos e o ponto e vírgula

Java é escrito em **instruções** (statements), e uma instrução termina com ponto e vírgula, não com o
fim da linha. Chaves agrupam instruções num **bloco**: o corpo de um método, de uma classe e, nas
lições 10 e 11, de um `if` ou de um laço. O compilador lê o arquivo como uma sequência de símbolos,
então quebras de linha e indentação não significam nada para ele. Essa liberdade tem um preço: um
ponto e vírgula esquecido é apontado num lugar onde uma pessoa não olharia primeiro:

```java
// Oops.java
public class Oops {
    public static void main(String[] args) {
        System.out.println("one")
        System.out.println("two");
    }
}
```

```
ana@vm:~/syntax$ javac Oops.java; echo $?
Oops.java:4: error: ';' expected
        System.out.println("one")
                                 ^
1 error
1
ana@vm:~/syntax$ ls
Hello.java
Oops.java
```

**O erro aponta para o fim da linha 4, onde o ponto e vírgula deveria estar**, e o acento `^` fica
logo depois do parêntese que fecha. O `javac` continuou lendo até a linha 5 e só então entendeu que a
linha 4 não tinha terminado, então indica o lugar onde esperava o `;`. Quando uma mensagem diz `';'
expected`, olhe o fim da linha que ela nomeia e, se essa linha parecer certa, a linha de cima. O
status de saída foi 1, e o `ls` não mostra nenhum `Oops.class`: **um arquivo com um único erro de
compilação não produz classe nenhuma**.

## Maiúsculas importam, em todo lugar

O Java distingue `System` de `system`, `Hello` de `hello` e `main` de `Main`. Troque uma letra do
programa que funciona e o compilador deixa de reconhecer o nome:

```
ana@vm:~/syntax$ mkdir -p case && sed 's/System.out/system.out/' Hello.java > case/Hello.java
ana@vm:~/syntax$ javac case/Hello.java
case/Hello.java:3: error: package system does not exist
        system.out.println("Hello, Java");
              ^
1 error
```

Para o compilador, `system.out` não era uma classe com erro de digitação. Um nome minúsculo seguido de
ponto podia ser um **pacote**, um grupo de classes que a lição 18 apresenta, então ele procurou um
pacote chamado `system`, não achou, e disse isso. A mensagem é exata e inútil ao mesmo tempo, e por
isso vale conhecê-la: **`package … does not exist` numa linha onde você não queria pacote nenhum
quase sempre quer dizer que uma maiúscula sumiu**.
