---
title: Uma restrição sua, @ValidIsbn
version: 1
---

Um ISBN-13 tem treze dígitos, e **o último é um dígito verificador** calculado a partir dos doze
primeiros, para que um único dígito digitado errado torne o número inválido em vez de apontar para
outro livro. A regra: multiplique os doze dígitos por 1 e 3, alternando, some os produtos, e o dígito
verificador é o que leva a soma até o próximo múltiplo de dez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"Os doze primeiros dígitos de 9786500000047, 9 7 8 6 5 0 0 0 0 0 0 4, multiplicados pelos pesos 1 3 1 3 e assim por diante, dão 9 21 8 18 5 0 0 0 0 0 0 12, que somam 73. (10 - 73 % 10) % 10 é 7, e o décimo terceiro dígito é 7, então o ISBN é válido.\"><text x=\"96\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dígito</text><text x=\"96\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">peso</text><text x=\"96\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">produto</text><rect x=\"112\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"128\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"128\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"128\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">9</text><rect x=\"152\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"168\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><text x=\"168\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"168\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">21</text><rect x=\"192\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"208\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"208\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><rect x=\"232\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"248\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"248\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"248\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">18</text><rect x=\"272\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"288\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"288\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><rect x=\"312\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"328\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"328\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"328\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"352\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"368\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"368\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"368\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"392\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"408\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"408\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"408\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"432\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"448\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"448\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"448\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"472\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"488\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"488\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"488\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"512\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"528\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"528\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"528\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"552\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"568\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"568\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"568\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">12</text><rect x=\"606\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"622\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><text x=\"622\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">verificador</text><line x1=\"112\" y1=\"124\" x2=\"584\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"112\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os produtos somam 9 + 21 + 8 + 18 + 5 + 12 = 73</text><text x=\"112\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">(10 - 73 % 10) % 10 = (10 - 3) % 10 = 7</text><text x=\"112\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">7 é o décimo terceiro dígito de 9786500000047, então o ISBN é válido</text></svg>", "caption": "O dígito verificador do ISBN-13 9786500000047, feito à mão: pesos 1 e 3 alternados, depois a distância até o próximo múltiplo de dez."}
```

`9786500000048` tem os mesmos doze primeiros dígitos, então o dígito verificador dele também deveria
ser 7, e ele termina em 8. Essa é a diferença que a seção anterior não conseguia ver.

Uma restrição sua tem três peças: a regra, a anotação que um record carrega, e um validador que liga
as duas.

## A regra

Crie `src/main/java/com/example/bookshop/catalogue/Isbn.java`:

```schooling-example
{
  "language": "java",
  "file": "Isbn.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\npublic final class Isbn {\n\n    private Isbn() {\n    }\n",
      "note": "Só métodos estáticos e um construtor privado: ninguém cria um `Isbn`, só faz uma pergunta a ele. Ele não sabe nada de Spring, e por isso a aula 18 consegue testá-lo sem nada rodando."
    },
    {
      "code": "    /** True when the text is thirteen digits whose last one is the ISBN-13 check digit. */\n    public static boolean isValid(String text) {\n        if (text == null || !text.matches(\"\\\\d{13}\")) {\n            return false;\n        }",
      "note": "Treze dígitos e mais nada. `matches` tem de cobrir o texto inteiro, então um hífen, um espaço ou um décimo quarto dígito falham aqui, antes de qualquer conta."
    },
    {
      "code": "        int sum = 0;\n        for (int i = 0; i < 12; i++) {\n            int digit = text.charAt(i) - '0';\n            sum += (i % 2 == 0) ? digit : digit * 3;\n        }",
      "note": "Pesos 1 e 3 alternados: os dígitos nas posições pares, contando do zero, valem uma vez, e os outros, três. `charAt(i) - '0'` transforma o caractere `'7'` no número 7."
    },
    {
      "code": "        int check = (10 - sum % 10) % 10;\n        return check == text.charAt(12) - '0';\n    }",
      "note": "A distância da soma até o próximo múltiplo de dez. O `% 10` de fora é para a soma que já termina em 0: a distância daria 10, e o dígito verificador é 0."
    },
    {
      "code": "}"
    }
  ]
}
```

## A anotação

Crie `ValidIsbn.java` ao lado dele:

```java
package com.example.bookshop.catalogue;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

@Documented
@Constraint(validatedBy = IsbnValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidIsbn {

    String message() default "must be a valid ISBN-13";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
```

Cada linha tem uma função:

- **`@Constraint(validatedBy = IsbnValidator.class)`** é o que faz desta anotação uma restrição, e
  diz qual classe a confere.
- `message`, `groups` e `payload` são os três membros que o Bean Validation exige de toda restrição.
  `message` é o texto padrão de uma violação, o que você vai ver no log abaixo; `groups` e `payload`
  servem para selecionar e rotular restrições, e esta aula não precisa de nenhum dos dois.
- `@Retention(RetentionPolicy.RUNTIME)` mantém a anotação na classe compilada. O validador acha as
  restrições por reflexão enquanto a aplicação roda, e uma anotação que o compilador jogou fora é
  invisível para ele.
- `@Target` diz onde a anotação pode ser escrita. `RECORD_COMPONENT` a permite no componente de um
  record, e **`FIELD` é o que a faz funcionar**: o Java copia uma anotação escrita num componente para
  o campo privado por trás dele só se o `@Target` incluir `FIELD`, e o campo é onde o validador
  procura. Um desvio no fim desta seção tira o `FIELD`.

## O validador

Crie `IsbnValidator.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class IsbnValidator implements ConstraintValidator<ValidIsbn, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        return value == null || Isbn.isValid(value);
    }
}
```

`ConstraintValidator<ValidIsbn, String>` se lê como "confere `@ValidIsbn` numa `String`". O validador
responde a uma pergunta, e **um `null` não é a pergunta dele**: ele devolve `true` e deixa o `null`
para o `@NotNull`. Essa é a convenção de toda restrição padrão, `@Size` e `@PositiveOrZero` inclusive,
e quer dizer que cada regra quebrada produz exatamente um erro, como o ISBN ausente abaixo mostra.

A regra fica em `Isbn` e não dentro do validador porque é um fato sobre livros, não sobre HTTP. A aula
18 testa `Isbn` sozinho, sem Spring e sem requisição nenhuma.

## O record a carrega

Substitua `BookRequest.java` pela versão final:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull @ValidIsbn String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents) {
}
```

Compile, reinicie e envie o ISBN que passava antes:

```
ana@vm:~/bookshop$ curl -si -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000048","title":"Senhora","author":"José de Alencar","priceCents":3100}' localhost:8080/books
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:32:41 GMT
Connection: close

{"timestamp":"2026-10-16T23:32:41.978Z","status":400,"error":"Bad Request","path":"/books"}
```

```
2026-10-16T20:32:41.971-03:00  WARN 1347 --- [bookshop] [nio-8080-exec-1] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in public org.springframework.http.ResponseEntity<com.example.bookshop.catalogue.BookResponse> com.example.bookshop.catalogue.BookController.add(com.example.bookshop.catalogue.BookRequest): [Field error in object 'bookRequest' on field 'isbn': rejected value [9786500000048]; codes [ValidIsbn.bookRequest.isbn,ValidIsbn.isbn,ValidIsbn.java.lang.String,ValidIsbn]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [bookRequest.isbn,isbn]; arguments []; default message [isbn]]; default message [must be a valid ISBN-13]] ]
```

O erro de campo traz o código `ValidIsbn` e a mensagem da anotação. Uma requisição sem ISBN nenhum
quebra só o `@NotNull`, então recebe um erro e não dois:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"title":"Senhora","author":"José de Alencar","priceCents":3100}' localhost:8080/books
{"timestamp":"2026-10-16T23:32:42.601Z","status":400,"error":"Bad Request","path":"/books"}
```

```
2026-10-16T20:32:42.600-03:00  WARN 1347 --- [bookshop] [nio-8080-exec-2] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in public org.springframework.http.ResponseEntity<com.example.bookshop.catalogue.BookResponse> com.example.bookshop.catalogue.BookController.add(com.example.bookshop.catalogue.BookRequest): [Field error in object 'bookRequest' on field 'isbn': rejected value [null]; codes [NotNull.bookRequest.isbn,NotNull.isbn,NotNull.java.lang.String,NotNull]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [bookRequest.isbn,isbn]; arguments []; default message [isbn]]; default message [must not be null]] ]
```

E um dígito verificador de verdade passa:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000047","title":"Iracema","author":"José de Alencar","priceCents":2800}' localhost:8080/books
{"id":4,"isbn":"9786500000047","title":"Iracema","author":"José de Alencar","priceCents":2800}
```

O repositório em memória recomeçou junto com a aplicação, e por isso este livro é o número 4 outra
vez.

## Um desvio: uma restrição que ninguém confere

Tire `FIELD` do `@Target`, compile, reinicie e envie de novo o dígito verificador errado:

```
ana@vm:~/bookshop$ sed -i 's/ElementType.FIELD, //' src/main/java/com/example/bookshop/catalogue/ValidIsbn.java && grep -n '@Target' src/main/java/com/example/bookshop/catalogue/ValidIsbn.java
14:@Target({ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
ana@vm:~/bookshop$ mvn -q package
```

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000048","title":"Senhora","author":"José de Alencar","priceCents":3100}' localhost:8080/books
{"id":4,"isbn":"9786500000048","title":"Senhora","author":"José de Alencar","priceCents":3100}
```

O projeto compilou sem aviso, a anotação continua escrita no record, e a requisição foi aceita. Sem
`FIELD`, a cópia no campo nunca foi feita e o validador não tinha o que conferir. **Uma restrição que
nunca é conferida parece exatamente uma que sempre passa**, e o único jeito de distinguir as duas é uma
requisição que devia falhar. Enviar uma toda vez é trabalho de teste, e a aula 18 começa a escrevê-los.
Ponha `FIELD` de volta e compile de novo:

```
ana@vm:~/bookshop$ sed -i 's/@Target({ElementType.PARAMETER/@Target({ElementType.FIELD, ElementType.PARAMETER/' src/main/java/com/example/bookshop/catalogue/ValidIsbn.java && grep -n '@Target' src/main/java/com/example/bookshop/catalogue/ValidIsbn.java
14:@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
```
