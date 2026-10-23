---
title: Beans que você não pode anotar, e o relógio
version: 1
---

A varredura de componentes encontra classes que você escreveu e etiquetou. `java.time.Clock` não é
nenhuma das duas coisas: pertence ao JDK, ninguém pode pôr `@Component` nele, e as suas instâncias
vêm de métodos estáticos como `Clock.system`, não de um construtor que o Spring possa chamar. Para um
objeto assim, a definição é um **método `@Bean`**, um método cujo valor de retorno vira um bean.

```schooling-example
{"language": "java", "file": "ClockConfig.java", "parts": [{"code": "package com.example.bookshop.config;\n\nimport java.time.Clock;\nimport java.time.ZoneId;\n\nimport org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\n"}, {"code": "@Configuration\npublic class ClockConfig {", "note": "`@Configuration` também é um estereótipo, então a varredura encontra esta classe e cria um bean dela, `clockConfig`. A função dela é guardar métodos `@Bean`."}, {"code": "\n    @Bean\n    public Clock clock() {\n        return Clock.system(ZoneId.of(\"America/Sao_Paulo\"));\n    }", "note": "O bean é o que o método devolve, o tipo é o tipo de retorno e o nome é o do método: `clock`. O Spring chama o método uma vez e guarda o resultado. Um método `@Bean` pode receber parâmetros, e o Spring os preenche como preenche os de um construtor."}, {"code": "}"}]}
```

O log dos beans, duas seções atrás, mostrou o que isso custa na inicialização. `clock` foi pego
primeiro, porque `catalogueReport` precisava dele, e criá-lo exigiu `clockConfig`, já que o método
pertence a uma instância dessa classe. `Wiring.java` fez o mesmo numa linha,
`new ClockConfig().clock()`.

A mesma ferramenta serve para qualquer objeto cuja construção seja mais que um `new`: um cliente
configurado a partir de propriedades, o builder de uma biblioteca, uma escolha entre duas
implementações feita na inicialização. A lição 15 declara as regras de segurança da aplicação como
métodos `@Bean` de uma única classe `@Configuration`.

## Por que o relatório recebe um relógio

`CatalogueReport` poderia ter chamado `LocalDate.now()`. Esse método lê o relógio e o fuso horário do
computador, um valor que toda classe alcança e que nenhum chamador consegue trocar, então a saída do
relatório dependeria do dia em que roda e nada que um teste fizesse mudaria isso. **Receber um `Clock`
como dependência transforma a hora atual numa entrada.** A aplicação recebe o relógio de verdade, no
fuso de São Paulo, e qualquer outro chamador pode passar um que nunca anda. Salve isto ao lado de
`Wiring.java`:

```java
// FixedClock.java: the same objects, with a clock that never moves.
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import com.example.bookshop.catalogue.BookService;
import com.example.bookshop.catalogue.CatalogueReport;
import com.example.bookshop.catalogue.InMemoryBookRepository;

void main() {
    var service = new BookService(new InMemoryBookRepository());
    var clock = Clock.fixed(Instant.parse("2026-01-01T12:00:00Z"), ZoneOffset.UTC);
    var report = new CatalogueReport(service, clock);
    report.run();
}
```

```
ana@vm:~/bookshop$ java -cp target/classes:$(cat target/classpath.txt) ~/FixedClock.java
19:16:25.572 [main] INFO com.example.bookshop.catalogue.CatalogueReport -- Catalogue opened on 2026-01-01 with 3 books
```

O relatório diz 1º de janeiro de 2026 em qualquer dia em que rode. O teste do serviço de pedidos da
lição 19 faz exatamente isso: monta o serviço com `Clock.fixed` e confere que o pedido criado carrega
aquele instante, o que seria impossível de verificar contra um relógio que anda.

O raciocínio vai além dos relógios. Qualquer coisa que uma classe buscaria no mundo à sua volta, como
uma fonte de números aleatórios, uma variável de ambiente ou um endereço de rede, pode ser injetada no
lugar, e então quem monta o objeto decide o que ela é.
