---
title: Compilando para um diretório, e executando a partir dele
version: 1
---

A lição 1 compilou o `Hello.java` e deixou o `Hello.class` ao lado dele. Isso funciona para um
arquivo e vira bagunça a partir do terceiro. **Projetos de verdade separam o código-fonte das classes
compiladas**, e aí o `java` precisa saber onde as classes estão. Essa informação é o **class path**
(caminho de classes), e a maioria dos problemas de "compila mas não roda" é um class path apontando
para outro lugar.

O programa desta lição recebe da linha de comando os nomes que cumprimenta. Salve-o num diretório
novo, `~/life`:

```schooling-example
{
  "language": "java",
  "file": "Greet.java",
  "parts": [
    {
      "code": "public class Greet {\n    public static void main(String[] args) {",
      "note": "**O `args` guarda as palavras digitadas depois do nome da classe**, uma string cada. `java -cp out Greet Ana Bruno` entrega ao `main` um array de duas."
    },
    {
      "code": "        if (args.length == 0) {\n            System.err.println(\"usage: java Greet NAME...\");\n            System.exit(2);\n        }",
      "note": "**Sem nomes, ele reclama e para.** O `System.err` é o fluxo de erro, separado da saída normal, e `System.exit(2)` encerra a JVM com status 2, que o shell consegue ler."
    },
    {
      "code": "        for (String name : args) {\n            System.out.println(\"Hello, \" + name);\n        }\n    }\n}",
      "note": "Uma linha por nome, na saída padrão. O laço `for` sobre um array é assunto da lição 11; aqui ele se lê como *para cada name em args*."
    }
  ]
}
```

## `-d` para as classes, `-cp` para encontrá-las

```
ana@vm:~/life$ javac -d out Greet.java
ana@vm:~/life$ ls; ls out
Greet.java
out
Greet.class
ana@vm:~/life$ java -cp out Greet Ana Bruno
Hello, Ana
Hello, Bruno
```

O `javac -d out` gravou a classe em `out`, criando o diretório porque ele não existia, e o diretório
do código-fonte ficou só com o fonte. `java -cp out Greet` se lê nesta ordem: **procure classes em
`out`, inicie a classe chamada `Greet`, e passe a ela o que vier depois**. `-cp` é a forma curta de
`-classpath`, e o valor pode nomear vários diretórios e arquivos `.jar`, separados por `:` no Linux e
no macOS e por `;` no Windows. A lição 18 põe um projeto inteiro nele.

## O número com que um programa termina

Um programa diz duas coisas quando termina: o que imprimiu, e um número inteiro chamado **status de
saída**. Zero quer dizer sucesso e qualquer outro valor quer dizer falha, por uma convenção muito mais
velha que o Java. O shell guarda o último status em `$?`:

```
ana@vm:~/life$ java -cp out Greet; echo $?
usage: java Greet NAME...
2
ana@vm:~/life$ java -cp out Greet Ana > hello.txt; echo $?; cat hello.txt
0
Hello, Ana
```

Sem nomes, o `Greet` imprimiu a linha de uso e terminou com 2, o número que passou ao `System.exit`.
Com um nome, o `main` retornou normalmente e a JVM terminou com 0. A segunda linha também mostra por
que o `System.err` existe. **O `>` redirecionou a saída padrão para `hello.txt`**, e o fluxo de erro
ainda teria chegado à tela: uma mensagem de uso não é dado, então não deve cair no arquivo que alguém
está juntando.

Um programa que nunca chama `System.exit` termina com 0 quando o `main` retorna, e com 1 quando uma
exceção escapa do `main`, o que a lição 36 mostra. Scripts e ferramentas de build decidem o próximo
passo só por esse número, então um programa Java feito para ser executado por outros programas deve
escolhê-lo de propósito.

## Três jeitos de pedir a classe errada

Estes três erros imprimem a mesma primeira linha, e a diferença está no nome que ela cita:

```
ana@vm:~/life$ java Greet Ana
Error: Could not find or load main class Greet
Caused by: java.lang.ClassNotFoundException: Greet
ana@vm:~/life$ java -cp out Greet.class
Error: Could not find or load main class Greet.class
Caused by: java.lang.ClassNotFoundException: Greet.class
ana@vm:~/life$ java -cp out greet Ana
Error: Could not find or load main class greet
Caused by: java.lang.ClassNotFoundException: greet
```

1. **Sem `-cp`.** O class path é, por padrão, o diretório atual, e o `Greet.class` está em `out`, não
   aqui. O nome `Greet` está certo e o lugar está errado.
2. **`Greet.class`.** O `java` recebe um nome de classe, e leu o ponto como separador de pacote: foi
   procurar uma classe `class` dentro de um pacote `Greet`. A correção é tirar a extensão.
3. **`greet`.** Nomes de classe diferenciam maiúsculas de minúsculas, mesmo num sistema de arquivos
   que não diferencia, e nenhuma classe se chama `greet`.

Então, quando aparecer `Could not find or load main class`, **compare primeiro o nome citado com o
nome real da classe, e só depois olhe o class path**. Se o nome está exatamente certo, o class path
está errado.
