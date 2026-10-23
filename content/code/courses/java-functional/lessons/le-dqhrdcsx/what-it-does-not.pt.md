---
title: O que o volatile não faz
version: 1
---

**O `volatile` torna cada leitura e cada escrita de um campo visíveis e ordenadas. Ele não transforma
uma leitura seguida de uma escrita num passo indivisível.** `count++` são três passos: ler `count`,
somar um, escrever `count`. Duas threads podem ler 41, as duas somar um e as duas escrever 42, e um
incremento se perde, embora cada leitura e cada escrita tenha sido perfeitamente visível:

```java
// LostUpdates.java: four threads incrementing a volatile counter
import java.util.ArrayList;
import java.util.List;

public class LostUpdates {
    static volatile long count = 0;

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 3; run++) {
            count = 0;
            List<Thread> threads = new ArrayList<>();
            for (int t = 0; t < 4; t++) {
                threads.add(Thread.ofPlatform().start(() -> {
                    for (int i = 0; i < 1_000_000; i++) {
                        count++;
                    }
                }));
            }
            for (Thread t : threads) {
                t.join();
            }
            System.out.println("run " + run + ": " + count + " of 4000000");
        }
    }
}
```

```
ana@vm:~/fp/volatile$ java LostUpdates.java
run 1: 1281588 of 4000000
run 2: 1190673 of 4000000
run 3: 1672481 of 4000000
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas threads incrementando count, que começa em 41. A thread 1 lê 41. A thread 2 lê 41. A thread 1 soma um e escreve 42. A thread 2 soma um e escreve 42. Dois incrementos rodaram e count subiu um.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread 1</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread 2</text><rect x=\"110\" y=\"30\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lê 41</text><rect x=\"260\" y=\"120\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lê 41</text><rect x=\"410\" y=\"30\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">escreve 42</text><rect x=\"560\" y=\"120\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">escreve 42</text><rect x=\"110\" y=\"180\" width=\"580\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">count: 41 antes, 42 depois de dois incrementos</text></svg>", "caption": "As duas leituras vieram antes de qualquer escrita: dois incrementos, um resultado.", "same": ["thread 1", "thread 2"]}
```

## Por que a contagem sai curta

Cada execução perdeu mais da metade dos seus quatro milhões de incrementos, um número diferente a cada
vez. **O `volatile` tornou as atualizações perdidas visíveis para todos; não as impediu.** Entre a
leitura e a escrita de uma thread, outras threads leram o mesmo valor e escreveram umas por cima das
outras. Essa forma, ler, decidir, escrever, tem nome, **read-modify-write** (ler-modificar-escrever),
e o bug também, uma **atualização perdida**. É a mesma condição de corrida que perdeu elementos do
`ArrayList` compartilhado na seção 04 da aula 9, um nível abaixo.

Duas ferramentas a resolvem, e são as próximas duas aulas:

- **um lock** (aula 14) faz os três passos rodarem uma thread por vez, para nenhuma outra thread se
  meter entre a leitura e a escrita;
- **um atômico** (aula 15), `AtomicLong.incrementAndGet()`, faz a leitura, a soma e a escrita como uma
  operação só do processador, e tenta de novo se outra thread chegou antes.

O compilador aceita `count++` num campo `volatile` sem aviso, e é por isso que esse erro é comum: a
palavra soa como "seguro para threads", e é só "visível para threads".
