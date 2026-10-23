---
title: Constantes que carregam dados e comportamento
version: 1
---

O `Genre` da seção 02 era quatro nomes. Valores de verdade carregam mais que um nome: um tipo de
empréstimo tem uma duração em dias e uma multa por atraso, e o código que precisa disso costuma criar
um `switch` em cada método que pergunta. **Como um enum é uma classe, cada constante pode carregar
os próprios campos e responder os próprios métodos**, e o `switch` some para dentro do tipo.

Uma biblioteca empresta livros em três modalidades. O dinheiro está em centavos inteiros, como em
toda esta plataforma:

```schooling-example
{
  "language": "java",
  "file": "Loans.java",
  "parts": [
    {
      "code": "enum LoanType {\n    STANDARD(14, 50),\n    SHORT(3, 200),\n    REFERENCE(0, 0) {\n        @Override\n        long feeCents(int daysLate) {\n            throw new UnsupportedOperationException(\"reference books stay in the library\");\n        }\n    };",
      "note": "**Cada constante é escrita com argumentos, e cada lista de argumentos é uma chamada de construtor.** `STANDARD(14, 50)` constrói o objeto `STANDARD` com um empréstimo de 14 dias e 50 centavos por dia de atraso. `REFERENCE` acrescenta um corpo entre chaves: um corpo de classe específico da constante, que sobrescreve um método só para ela. O ponto e vírgula depois da última constante encerra a lista, e é obrigatório assim que algo vem depois dela."
    },
    {
      "code": "\n    private final int days;\n    private final int centsPerDay;",
      "note": "**Campos, como em qualquer classe.** `private final`, porque uma constante é compartilhada pelo programa inteiro e nada deveria conseguir mudá-la."
    },
    {
      "code": "\n    LoanType(int days, int centsPerDay) {\n        this.days = days;\n        this.centsPerDay = centsPerDay;\n    }",
      "note": "**O construtor é privado por regra**, escrito sem modificador ou com `private`, e nunca chamado com `new`. A JVM o chama uma vez por constante, a partir do inicializador da classe."
    },
    {
      "code": "\n    int days() {\n        return days;\n    }",
      "note": "Um método comum, que cada constante responde a partir dos próprios campos."
    },
    {
      "code": "\n    long feeCents(int daysLate) {\n        return (long) daysLate * centsPerDay;\n    }\n}",
      "note": "**Um método com uma resposta padrão**, que o `REFERENCE` substitui. O cast `(long)` faz a multiplicação acontecer em `long`, para que um número grande de dias não estoure um `int` (lição 6)."
    },
    {
      "code": "\npublic class Loans {\n    public static void main(String[] args) {\n        for (LoanType t : LoanType.values()) {\n            System.out.println(t + \": \" + t.days() + \" days\");\n        }\n        System.out.println(\"SHORT, 4 days late: \" + LoanType.SHORT.feeCents(4) + \" cents\");\n        System.out.println(LoanType.SHORT.getClass());\n        System.out.println(LoanType.REFERENCE.getClass());\n        LoanType.REFERENCE.feeCents(1);\n    }\n}",
      "note": "O `main` lista as constantes, cobra uma multa, imprime a classe de duas constantes e, por fim, pede ao `REFERENCE` uma multa."
    }
  ]
}
```

Em `~/enums/loans`:

```
ana@vm:~/enums/loans$ javac Loans.java && java Loans
STANDARD: 14 days
SHORT: 3 days
REFERENCE: 0 days
SHORT, 4 days late: 800 cents
class LoanType
class LoanType$1
Exception in thread "main" java.lang.UnsupportedOperationException: reference books stay in the library
	at LoanType$1.feeCents(Loans.java:7)
	at Loans.main(Loans.java:36)
ana@vm:~/enums/loans$ ls *.class
LoanType$1.class
LoanType.class
Loans.class
```

**`SHORT.feeCents(4)` dá 800**, quatro dias a 200 centavos, calculado a partir dos campos com que a
constante foi construída. Um tipo novo de empréstimo é mais uma linha na lista, com os seus números,
e nenhum método em outro lugar precisa mudar. Compare com a alternativa: `int days(String type)` com
um `switch` dentro, `long feeCents(String type, int daysLate)` com outro, e um tipo novo que precisa
ser acrescentado aos dois.

## Uma constante, uma classe própria

`STANDARD` e `SHORT` são objetos de `LoanType`. **O `REFERENCE` é um objeto de `LoanType$1`**, uma
subclasse anônima que o compilador criou para o corpo dele, e o `ls` encontrou o arquivo de classe.
A numeração `$1` é a da lição 17, para classes anônimas, e o stack trace também a cita: a exceção foi
lançada em `LoanType$1.feeCents`, linha 7, que é o `throw` dentro das chaves do `REFERENCE`.

Este é o lugar do comportamento que muda para uma ou duas constantes. Quando **toda** constante
precisaria de um corpo próprio, isso costuma indicar que os dados pertencem a campos, como `days` e
`centsPerDay` aqui.

Um livro de referência não pode ser emprestado, então pedir a multa dele é um erro, e o método recusa
com uma exceção em vez de devolver 0. Um 0 seria lido como "sem multa", e um relatório que somasse
as multas de todos os empréstimos sairia errado sem avisar. A lição 36 trata de exceções; aqui basta
que a recusa seja barulhenta.

## O que um enum não consegue fazer

Um enum não pode estender outra classe, porque já estende `java.lang.Enum`, e nada pode estender um
enum, porque ele é `final` (o `javap` da seção 02). Ele **pode** implementar interfaces, que é o
assunto da lição 23, e é assim que um enum participa de um projeto que também tem outras
implementações.
