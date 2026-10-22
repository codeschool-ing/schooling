---
title: Quando um record é a ferramenta errada
version: 1
---

Quando os records ficam familiares, toda classe começa a parecer um. **Um record é certo para um
valor, e errado para uma coisa que muda enquanto continua sendo a mesma coisa.** A diferença aparece
no que o compilador não deixa um record fazer.

Um empréstimo tem um livro e um membro, e uma data de devolução que muda quando o membro o renova. A
tentativa óbvia acrescenta a data como um campo comum:

```java
// Loan.java
record Loan(String isbn, String member) {
    private String dueDate;
}
```

```
ana@vm:~/records/not$ javac Loan.java
Loan.java:3: error: field declaration must be static
    private String dueDate;
                   ^
  (consider replacing field with record component)
1 error
```

**Um record não tem campos de instância além dos componentes**, e a mensagem sugere a única entrada:
transformá-lo em componente. Campos estáticos são permitidos, e também métodos, estáticos e de
instância, tipos aninhados e interfaces implementadas. O que um record não pode ter é estado fora do
cabeçalho, porque o `equals`, o `hashCode` e o `toString` são construídos a partir do cabeçalho, e um
campo escondido faria dois empréstimos "iguais" serem diferentes.

Um record também não entra numa hierarquia de classes:

```java
// Special.java
record Item(String title) {
}

record Book(String title, int pages) extends Item {
}
```

```
ana@vm:~/records/not$ javac Special.java
Special.java:5: error: '{' expected
record Book(String title, int pages) extends Item {
                                    ^
1 error
```

O compilador para no `extends`, porque um record já estende `java.lang.Record` e a sintaxe não tem
espaço para mais nada. **Um record pode implementar interfaces, como a seção 04 fez, e não pode nem
estender nem ser estendido**, já que é `final`.

## Um valor, ou uma coisa com vida própria

Ponha o empréstimo de volta como componente, `record Loan(String isbn, String member, LocalDate
dueDate)`, e ele compila. Renová-lo agora quer dizer fazer um `Loan` novo com uma data posterior, e o
antigo continua existindo, sem mudança. Dois empréstimos com o mesmo livro, o mesmo membro e a mesma
data são `equals`, então a biblioteca não consegue distinguir o empréstimo desta semana de um idêntico
feito no ano passado e devolvido.

Para um ISBN isso é exatamente o certo: dois ISBNs iguais *são* o mesmo ISBN. Para um empréstimo é
errado, porque um empréstimo tem uma **identidade** que dura mais que os seus valores. Ele é o mesmo
empréstimo antes e depois de uma renovação, e um empréstimo diferente do do ano passado mesmo que
todos os campos coincidam. Isso pede a classe da lição 22: campos privados, métodos que os mudam
mantendo as regras, e um id próprio.

Um teste curto resolve a maioria dos casos:

| pergunta | record | classe |
|---|---|---|
| dois com campos iguais são a mesma coisa? | sim: um ISBN, um intervalo de datas, um preço | não: um empréstimo, um membro, uma conta |
| muda depois de construído? | nunca; uma mudança é um valor novo | sim, pelos seus próprios métodos |
| precisa de uma superclasse? | não pode ter uma | pode |

Frameworks que constroem objetos para você, como os mapeadores de banco de dados que o `java-back`
apresenta, costumam querer um objeto que possam criar vazio e preencher campo a campo. Um record não
pode ser esse objeto; os dois são feitos para trabalhos diferentes. Use records para os dados que
viajam entre as partes, e classes para as coisas que as partes guardam.
