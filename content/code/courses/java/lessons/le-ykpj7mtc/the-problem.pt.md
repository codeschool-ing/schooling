---
title: O que se pedia a um bloco finally
version: 1
---

Alguns objetos guardam algo que não é memória: um arquivo aberto, uma conexão com um banco de dados,
um socket. O coletor de lixo da lição 19 devolve memória no ritmo dele e **não devolve mais nada**,
então um programa que abre uma dessas coisas tem de fechá-la, em todo caminho de saída do código que a
usou. O `finally` da lição 36 era a ferramenta para isso, e esta seção mostra quanto ele custa.

O recurso aqui é inventado, para poder ser quebrado de propósito. Salve-o em `~/twr` como
`Resource.java`:

```schooling-example
{
  "language": "java",
  "file": "Resource.java",
  "parts": [
    {
      "code": "// Resource.java\npublic class Resource {\n    private final String name;\n    private final boolean failOnClose;",
      "note": "**Um substituto para qualquer coisa que precisa ser devolvida**: um arquivo, uma conexão com o banco, um socket. Guarda um nome para imprimir e uma chave que faz o fechamento falhar, para a lição poder quebrá-lo de propósito."
    },
    {
      "code": "\n    public Resource(String name, boolean failOnClose) {\n        this.name = name;\n        this.failOnClose = failOnClose;\n        System.out.println(\"open \" + name);\n    }",
      "note": "**Abrir é o construtor.** Da linha `open` em diante, algo fora do programa está preso, e alguém tem de soltá-lo."
    },
    {
      "code": "\n    public void use(boolean fail) {\n        System.out.println(\"use \" + name);\n        if (fail) {\n            throw new IllegalStateException(\"use of \" + name + \" failed\");\n        }\n    }",
      "note": "`use` é o trabalho. Recebendo `true`, ele lança, do jeito que uma leitura falha num disco cheio ou uma consulta numa conexão perdida."
    },
    {
      "code": "\n    public void close() {\n        System.out.println(\"close \" + name);\n        if (failOnClose) {\n            throw new IllegalStateException(\"close of \" + name + \" failed\");\n        }\n    }\n}",
      "note": "`close` devolve o recurso e avisa. **Fechar também pode falhar**: um arquivo cujos últimos bytes não podem ser gravados falha aqui, depois de o trabalho parecer terminado."
    }
  ]
}
```

## O vazamento

O primeiro programa abre, usa e fecha, nessa ordem, como faz a maioria das primeiras tentativas:

```java
// Leak.java
public class Leak {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", false);
        r.use(true);
        r.close();
    }
}
```

```
ana@vm:~/twr$ javac *.java
ana@vm:~/twr$ java Leak; echo "exit $?"
open loans.db
use loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Leak.main(Leak.java:5)
exit 1
```

`open`, `use`, e depois a exceção. **Não há linha `close`.** A exceção saiu do `main` na linha 5, e a
linha 6 nunca rodou. Aqui o processo terminou um instante depois, e o sistema operacional recolheu o
que ele segurava. Um servidor não termina: ele captura a exceção, atende a próxima requisição, e vaza
mais uma conexão cada vez que o `use` falha, até o pool esvaziar e toda requisição ficar esperando.

## O conserto, e o preço dele

O `finally` roda seja qual for o jeito de sair do bloco `try`, então o fechamento vai para lá:

```java
// Finally.java
public class Finally {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", false);
        try {
            r.use(true);
        } finally {
            r.close();
        }
    }
}
```

```
ana@vm:~/twr$ java Finally
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Finally.main(Finally.java:6)
```

O `close loans.db` está lá, e a exceção continua chegando a quem chamou. Isso está certo, e custou
quatro linhas e uma variável declarada fora do `try` para que o `finally` a enxergue. Com dois
recursos custa blocos `try` aninhados, porque o segundo precisa ser fechado mesmo quando fechar o
primeiro falha.

## A exceção mascarada

O conserto tem um buraco que só aparece quando o fechamento também falha. O `Masked` é o `Finally` com
o segundo argumento do recurso valendo `true`:

```java
// Masked.java
public class Masked {
    public static void main(String[] args) {
        Resource r = new Resource("loans.db", true);
        try {
            r.use(true);
        } finally {
            r.close();
        }
    }
}
```

```
ana@vm:~/twr$ java Masked
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: close of loans.db failed
	at Resource.close(Resource.java:22)
	at Masked.main(Masked.java:8)
```

Lendo o stack trace, você iria procurar no `close`. **A falha que começou tudo, `use of loans.db
failed`, sumiu.** Quando o `finally` lança, a exceção dele substitui a que já estava saindo, e nada
guarda a primeira. Quem ler esse log às três da manhã conserta a coisa errada. A seção 03 elimina o
código repetitivo, e a seção 04 mostra para onde vai a exceção perdida.
