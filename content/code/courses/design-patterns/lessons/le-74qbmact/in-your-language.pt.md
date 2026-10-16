---
title: Fluxos na sua linguagem
version: 1
---

**Toda linguagem da trilha `backend` tem um jeito de empurrar valores, e elas diferem mais no que
fazem a respeito de backpressure.** O vocabulário desta lição, observable, operador, quente e frio,
as quatro estratégias, vale para todas elas. O que não vale é o padrão: algumas bibliotecas aplicam
backpressure por você, algumas deixam com você, e uma o deixa de fora de propósito.

| sua linguagem | fluxos push | backpressure |
|---|---|---|
| JavaScript / TypeScript | RxJS: `Observable`, `pipe`, uns cem operadores | nenhum no RxJS: operadores com perda, como `throttleTime` e `sampleTime`, no lugar. Os streams do Node.js têm: `write()` devolve `false` quando o buffer enche |
| Java | Reactor (`Flux`, `Mono`, por baixo do Spring WebFlux) e RxJava | demanda por `request(n)`, as regras de Reactive Streams, mais `onBackpressureBuffer`, `Drop` e `Latest` |
| Go | canais e goroutines; nenhum observable na biblioteca padrão | um canal com buffer bloqueia quem envia quando está cheio; `select` com `default` descarta |
| Python | filas do `asyncio` e geradores assíncronos; RxPY, o pacote `reactivex`, fora da biblioteca padrão | `asyncio.Queue(maxsize=n)` e `queue.Queue(maxsize=n)` bloqueiam |

## TypeScript: RxJS

O `operators.py` em RxJS é quase uma transliteração, porque o nosso `pipe` foi modelado nele:

```ts
import { from, filter, map, scan } from "rxjs";

from(returns).pipe(
  filter((r) => r.daysLate > 0),
  map((r) => r.daysLate * 50),
  scan((total, cents) => total + cents, 0),
).subscribe((total) => console.log(`fines so far: ${total} cents`));
```

**O RxJS não tem `request(n)`, e isso foi decidido de propósito.** A casa dele é o navegador, onde a
maioria das fontes é quente e não pode ser desacelerada: um usuário não clica mais devagar porque um
tratador está ocupado. Então as respostas dele são as estratégias com perda da seção anterior, com
nomes que descrevem tempo: `throttleTime(1000)` deixa passar um valor por segundo e descarta o resto,
e `sampleTime(1000)` emite o valor mais recente uma vez por segundo, que é *latest* com relógio. O
Angular usa RxJS do começo ao fim, então este é o primeiro código reativo que muita gente de
TypeScript encontra.

## Java: Reactor e as interfaces Flow

```java
Flux.fromIterable(returns)
    .filter(r -> r.daysLate() > 0)
    .map(r -> r.daysLate() * 50)
    .scan(Integer::sum)
    .subscribe(total -> System.out.println("fines so far: " + total + " cents"));
```

Java é onde o backpressure está mais completamente embutido. Reactive Streams define quatro
interfaces, `Publisher`, `Subscriber`, `Subscription` e `Processor`; o Java 9 as copiou para
`java.util.concurrent.Flow`, e Reactor e RxJava implementam o mesmo contrato pelo pacote original
`org.reactivestreams`. Entre estágios, um operador como `publishOn` pede à fonte um lote, 256 valores
por padrão, e só pede mais conforme o estágio de baixo consome, então um estágio lento desacelera a
fonte sem ninguém escrever uma fila. Uma lambda passada a `subscribe` pede tudo de uma vez; um inscrito
que quer ditar o próprio ritmo estende o `BaseSubscriber` do Reactor e chama `request(1)` ele mesmo.
O RxJava mantém dois tipos separados por esse motivo: `Flowable` respeita a demanda e `Observable`
não, e a documentação diz para usar `Observable` só com fontes que não podem ser desaceleradas, como
eventos de interface.

## Go: canais são a fila com limite

Go não tem observable, e a maioria das pessoas que programam em Go diria que não precisa. Uma
goroutine que lê de um canal e escreve em outro é um operador, e uma cadeia delas é um pipeline. Um
canal com buffer é exatamente a fila do `blocking.py`, com o bloqueio embutido na linguagem:

```go
scans := make(chan int, 3) // a send waits while three scans are queued

select {
case scans <- scan:
default:
	dropped++ // full: drop this scan and count it
}
```

Um `scans <- scan` simples é *block*. O `select` com caso `default` é *drop*, porque `default` roda
quando nenhum outro caso consegue andar. *latest* pede algumas linhas a mais: esvaziar o canal sem
bloquear, depois enviar. Os atores da lição 17 e a concorrência da lição 18 voltam às goroutines pelo
outro lado.

## Python: o que a biblioteca padrão oferece

O curso não usa pacotes, então esta lição construiu seu observable à mão. Em código Python de verdade,
as ferramentas push da biblioteca padrão são do `asyncio`: uma `asyncio.Queue(maxsize=n)` entre duas
corrotinas é o `blocking.py` sem threads, e um gerador assíncrono, consumido com `async for`, é uma
fonte pull cujos valores chegam depois. O RxPY, publicado no PyPI como `reactivex`, é o membro Python
da família ReactiveX, com os mesmos operadores do RxJS. É uma escolha razoável quando um programa é de
fato uma rede de fluxos de eventos, e maquinaria demais para um programa que tem uma fila.

## O que se leva daqui

Seja qual for a sua linguagem, as decisões desta lição são as mesmas quatro perguntas. A fonte
empurra ou pode ser puxada? Ela é quente ou fria? Quando o consumidor fica para trás, o produtor
espera ou um valor vai embora? E se um valor vai embora, quem o conta? As bibliotecas resolvem a
mecânica. Essas quatro respostas são o projeto, e pertencem à revisão de código seja qual for a
sintaxe em que estão escritas.
