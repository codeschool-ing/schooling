---
title: As ideias funcionais na sua linguagem
version: 1
---

**Nada nesta lição precisa de uma linguagem funcional, e nenhuma das quatro linguagens deste curso é
uma.** Cada uma tomou as ideias emprestadas num grau diferente, e cada uma tem um ponto onde o
empréstimo para. Saber onde fica esse ponto importa mais do que saber a sintaxe, porque é ali que um
projeto funcional naquela linguagem precisa de disciplina ou de uma biblioteca.

## Imutabilidade

| linguagem | um registro imutável | onde para |
|---|---|---|
| Python | `@dataclass(frozen=True)`, `NamedTuple`, `tuple`, `frozenset` | rasa: um objeto congelado que guarda uma lista ainda pode ter a lista mudada |
| Java | `record Loan(String title, LocalDate due)` (Java 16+), campos `final`, `List.of(...)` | `final` impede reatribuição, não a mutação do objeto para o qual o campo aponta |
| Go | nenhum; uma struct passada por valor é copiada, então quem recebe não muda a cópia de quem chamou | slices e maps dentro da struct são compartilhados pela cópia |
| TypeScript | propriedades `readonly`, `Readonly<T>`, `as const` | conferido só na compilação; em tempo de execução é um objeto comum |

O mesmo limite aparece nas quatro: **a imutabilidade é rasa, a menos que todo campo também seja
imutável.** O `List.of` do Java e a `tuple` do Python são as opções profundas; o Go precisa copiar
um slice à mão; o TypeScript pode congelar um objeto em tempo de execução com `Object.freeze`, que
também é raso.

## Funções como valores, e o encadeamento

As quatro passam funções como valores. O que muda é o quanto o encadeamento é agradável:

```java
long total = loans.stream()
        .filter(loan -> loan.daysLate(today) > 0)
        .mapToLong(loan -> loan.daysLate(today) * 50)
        .sum();
```

```ts
const total = loans
  .filter((loan) => daysLate(loan, today) > 0)
  .map((loan) => daysLate(loan, today) * 50)
  .reduce((a, b) => a + b, 0);
```

```go
total := 0
for _, loan := range loans {
	if d := daysLate(loan, today); d > 0 {
		total += d * 50
	}
}
```

Os streams do Java são preguiçosos e consumidos uma vez, como os iteradores do Python. Os métodos de
array do TypeScript montam um array novo a cada passo, o que é simples e aloca mais. O idioma do Go
continua sendo o laço: a linguagem tem closures desde o começo e genéricos só desde a 1.18, e a
comunidade nunca adotou map e filter como estilo. Um revisor de Go normalmente vai pedir o laço, e
isso é um fato cultural da linguagem, não uma falha do seu projeto.

## Erros como valores

| linguagem | o jeito de costume | um valor tipo resultado |
|---|---|---|
| Python | exceções | classes `Ok` e `Err` como na seção anterior, ou uma biblioteca |
| Java | exceções, verificadas e não verificadas | `Optional<T>` para ausência; um `Either` de uma biblioteca como a Vavr, ou uma interface selada |
| Go | `value, err` devolvidos pela função | essa *é* a convenção: erros são valores |
| TypeScript | exceções | uma união discriminada de `{ ok: true, value }` e `{ ok: false, error }` |

O Go é o caso interessante. Ele fez dos erros valores em 2009, por convenção e não por um tipo, e o
resultado aparece em todo arquivo Go: `if err != nil { return err }`. As exceções verificadas do
Java foram uma tentativa anterior de pôr a falha na assinatura, e a maior parte do Java moderno as
evita porque elas vazam por todas as camadas. A união discriminada do TypeScript é a mais próxima
das quatro do `Result` do Rust, porque o compilador estreita pelo campo `ok` assim como o mypy
estreita pelo `isinstance`.

## Pureza

Nenhuma linguagem aqui a confere. Nas quatro, uma função pura é uma que recebe tudo como argumento e
devolve tudo como valor, e um revisor vê isso lendo a assinatura e o corpo. **Núcleo funcional e
casca imperativa é um jeito de organizar um programa, e funciona em qualquer linguagem** com funções
e valores, o que inclui as quatro. A estrutura é o que você leva consigo; a sintaxe é a que a sua
linguagem oferecer.
