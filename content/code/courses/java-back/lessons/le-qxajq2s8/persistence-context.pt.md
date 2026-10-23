---
title: O contexto de persistência, e uma alteração que ninguém salvou
version: 1
---

A imagem errada de um mapeador é um par de funções, uma que lê linhas para objetos e outra que
escreve objetos em linhas, cada uma chamada quando você pede. A certa tem um estado no meio. O
**contexto de persistência** é um mapa, mantido durante uma transação, da chave de cada entidade para o
único objeto que representa aquela linha, junto com uma cópia dos valores que a linha tinha quando foi
carregada. Dois comportamentos saem dele, e nenhum aparece no código que depende deles.

- **Um objeto por linha.** Pedir o livro 3 duas vezes dentro de uma transação roda um `SELECT` e
  devolve o mesmo objeto duas vezes. Na segunda, quem responde é o mapa.
- **Dirty checking.** Quando a transação faz commit, o Hibernate compara cada objeto gerenciado com a
  cópia que tirou ao carregá-lo. Todo objeto que mudou ganha um `UPDATE`, sem ninguém chamar um método
  de salvar. Mandar os comandos pendentes se chama **flush**, e um commit sempre faz o flush antes.

## Um desvio que você vai desfazer

O bookshop nunca altera um livro depois de acrescentá-lo, então isto é uma demonstração e não uma
funcionalidade. Acrescente um método a `Book`, logo depois de `getPriceCents()`:

```java
    public void reprice(int newPriceCents) {
        this.priceCents = newPriceCents;
    }
```

e crie `src/main/java/com/example/bookshop/catalogue/RepriceOnce.java`, uma tarefa de inicialização
como o relatório do catálogo:

```java
package com.example.bookshop.catalogue;

import jakarta.persistence.EntityManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Order(1)
public class RepriceOnce implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(RepriceOnce.class);

    private final EntityManager em;

    public RepriceOnce(EntityManager em) {
        this.em = em;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Book first = em.find(Book.class, 3L);
        Book second = em.find(Book.class, 3L);
        log.info("the same object twice: {}", first == second);
        first.reprice(3800);
        log.info("price changed in memory, nothing saved yet");
    }
}
```

O `run` é `@Transactional`, então tudo dentro dele divide um contexto de persistência. Ele carrega o
livro 3, Frankenstein, duas vezes, compara as duas referências com `==`, muda o preço numa delas e
retorna. Não há `persist`, nem `merge`, nem `save` em lugar nenhum. Compile, suba com o perfil `sql` e
leia o segundo terminal:

```
2026-10-22T19:22:47.111-03:00  INFO 30767 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 7.474 seconds (process running for 8.226)
2026-10-22T19:22:47.163-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:22:47.219-03:00  INFO 30767 --- [bookshop] [           main] c.e.bookshop.catalogue.RepriceOnce       : the same object twice: true
2026-10-22T19:22:47.220-03:00  INFO 30767 --- [bookshop] [           main] c.e.bookshop.catalogue.RepriceOnce       : price changed in memory, nothing saved yet
2026-10-22T19:22:47.235-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,title=? where id=?
2026-10-22T19:22:47.557-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id
2026-10-22T19:22:47.561-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:47.563-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:47.564-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:47.565-03:00 DEBUG 30767 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:47.566-03:00  INFO 30767 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

Leia na ordem. Há um `select`, para o primeiro `find`. O segundo `find` não rodou SQL e devolveu
exatamente o mesmo objeto, que é o que o `true` quer dizer. As duas linhas de log saem antes de
qualquer gravação: só quando o `run` retorna a transação faz commit, o commit faz o flush, e o
Hibernate compara Frankenstein com a cópia que tirou ao carregar. O preço é diferente, e sai um
`UPDATE` que ninguém escreveu. Ele grava todas as colunas mapeadas, e não só o preço, porque por
padrão o Hibernate usa um `UPDATE` por entidade para qualquer alteração. O `@Order(1)` fez esta tarefa
rodar antes do relatório do catálogo, cujos cinco comandos vêm em seguida; eles são o assunto da
próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Quatro passos. Primeiro find: um select é enviado e o preço 3500 fica guardado duas vezes, no objeto e numa cópia. Segundo find: nada é enviado, volta o mesmo objeto. reprice(3800): nada é enviado, o objeto diz 3800 e a cópia continua 3500. Commit: os dois diferem, então um update é enviado.\"><text x=\"16\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o código</text><text x=\"16\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL enviado</text><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o objeto</text><text x=\"16\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cópia ao carregar</text><text x=\"188.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"120\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"188.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">find(Book.class, 3L)</text><text x=\"188.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … where id=?</text><rect x=\"150\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"188.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3500</text><text x=\"188.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"334.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"266\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">find(Book.class, 3L)</text><text x=\"334.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada</text><rect x=\"296\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"334.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3500</text><text x=\"334.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"480.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"412\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">first.reprice(3800)</text><text x=\"480.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada</text><rect x=\"442\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3800</text><text x=\"480.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"626.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"558\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"626.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">run retorna: commit</text><text x=\"626.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">update book set …</text><rect x=\"588\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"626.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3800</text><text x=\"626.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"120\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">No commit, o Hibernate compara cada objeto gerenciado com a cópia dele.</text><text x=\"120\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Frankenstein mudou (3800 contra 3500), então ele envia um UPDATE.</text></svg>", "caption": "O que o contexto de persistência faz com a demonstração, passo a passo. O UPDATE vem da comparação entre o objeto e a cópia, não de chamada nenhuma."}
```

O preço está mesmo no banco, e o `psql`, da aula 9, confirma:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'SELECT id, title, price_cents FROM book WHERE id = 3'
 id |    title     | price_cents 
----+--------------+-------------
  3 | Frankenstein |        3800
(1 row)
```

Pare a aplicação e suba mais uma vez, sem mudar nada:

```
2026-10-22T19:22:55.017-03:00  INFO 31198 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.685 seconds (process running for 6.374)
2026-10-22T19:22:55.118-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:22:55.141-03:00  INFO 31198 --- [bookshop] [           main] c.e.bookshop.catalogue.RepriceOnce       : the same object twice: true
2026-10-22T19:22:55.141-03:00  INFO 31198 --- [bookshop] [           main] c.e.bookshop.catalogue.RepriceOnce       : price changed in memory, nothing saved yet
2026-10-22T19:22:55.415-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id
2026-10-22T19:22:55.424-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:55.429-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:55.433-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:55.434-03:00 DEBUG 31198 --- [bookshop] [           main] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:22:55.437-03:00  INFO 31198 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

**Desta vez, nenhum `UPDATE`.** O método pôs o preço em 3800 de novo, a linha já dizia 3800, e a
comparação não achou nada para gravar. O dirty checking compara valores; ele não conta chamadas.

## Tirando o desvio

Apague `RepriceOnce.java` e o método `reprice`, para que `Book.java` volte a ser o arquivo da seção
sobre entidades, e devolva Frankenstein ao preço dele:

```
ana@vm:~/bookshop$ rm src/main/java/com/example/bookshop/catalogue/RepriceOnce.java
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'UPDATE book SET price_cents = 3500 WHERE id = 3'
UPDATE 1
```

## Gerenciado, e depois não

Uma entidade que está no mapa é **gerenciada**: o Hibernate a vigia, e os campos lazy dela ainda
conseguem carregar. Quando a transação termina, o contexto de persistência fecha, e todo objeto que ele
guardava fica **desanexado** (*detached*). Ele mantém os valores que tinha, então ler `getTitle()`
continua funcionando. Mas ninguém o vigia mais: uma alteração num objeto desanexado nunca é gravada, e
um campo lazy que ele nunca carregou não pode mais ser carregado. O serviço da seção sobre o entity
manager devolve records montados dentro da transação justamente para que nenhuma entidade desanexada
saia dela. A última seção mostra o que acontece quando uma sai.
