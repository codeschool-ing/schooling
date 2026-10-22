---
title: O que o `new` faz, passo a passo
version: 1
---

`new Loan("Effective Java")` se lê como "chame o construtor", e o construtor é a última de três coisas
que acontecem. **Quando a primeira linha de um construtor roda, o objeto já existe, todo atributo já
tem um valor, e alguns já têm o valor final.** Um construtor termina um objeto; não o cria.

Crie um diretório para esta lição, `~/lifecycle`, e salve isto nele. O construtor imprime os
atributos antes de mexer neles:

```java
// Loan.java
public class Loan {
    private String title;
    private int days = 14;
    private boolean returned;

    Loan(String title) {
        System.out.println("constructor starts: title=" + this.title + " days=" + days + " returned=" + returned);
        this.title = title;
        System.out.println("constructor ends:   title=" + this.title);
    }

    public static void main(String[] args) {
        Loan loan = new Loan("Effective Java");
        System.out.println(loan.title + " for " + loan.days + " days");
    }
}
```
```
ana@vm:~/lifecycle$ javac Loan.java && java Loan
constructor starts: title=null days=14 returned=false
constructor ends:   title=Effective Java
Effective Java for 14 days
ana@vm:~/lifecycle$ javap -c Loan | grep -A6 "static void main"
  public static void main(java.lang.String[]);
    Code:
         0: new           #8                  // class Loan
         3: dup
         4: ldc           #40                 // String Effective Java
         6: invokespecial #42                 // Method "<init>":(Ljava/lang/String;)V
         9: astore_1
```

Leia a primeira linha da saída: **`title=null days=14 returned=false`**, impressa antes de o
construtor atribuir qualquer coisa. Três histórias diferentes numa linha:

1. **A memória veio primeiro, zerada.** A JVM reservou espaço para um `Loan` no heap e pôs em cada
   atributo o zero do seu tipo: `null` para uma referência, `0` para um número, `false` para um
   `boolean`. Foi daí que `returned` tirou o `false`, e é por isso que `title` ainda era `null`. A
   lição 5 chamou isso de valores padrão dos atributos.
2. **Depois rodaram os inicializadores dos atributos.** `days = 14` está escrito na declaração do
   atributo, e já tinha acontecido quando o construtor começou.
3. **Depois rodou o corpo do construtor**, que definiu `title`.

O bytecode mostra a mesma ordem do lado de quem chama. `new` é uma instrução própria, que aloca e
zera; o construtor é um método chamado `<init>`, executado sobre o resultado com `invokespecial`. O
`dup` entre os dois guarda uma segunda cópia da referência nova, porque a chamada do construtor
consome uma e o `astore_1` precisa da outra para guardá-la em `loan`.

**Não há como pegar o objeto entre o `new` e o `<init>`**, e é isso que faz de um construtor um lugar
seguro para estabelecer as regras que um objeto mantém a vida toda. A lição 27 acrescenta as peças
que faltam da ordem, os blocos inicializadores e as classes mãe, e a única armadilha dela: um
construtor que chama um método que uma subclasse sobrescreveu.
