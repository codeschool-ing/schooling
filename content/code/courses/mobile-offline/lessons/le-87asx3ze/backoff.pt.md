---
title: Recuo exponencial, e por que ele precisa de jitter
version: 1
---

**Espere mais depois de cada falha, dobrando a espera até um teto, e escolha um ponto aleatório
abaixo desse teto em vez do próprio teto.** O dobrar é o **recuo exponencial** (*exponential
backoff*). O ponto aleatório é o **jitter**, e a versão em que a espera vai de zero até o teto se
chama **jitter total** (*full jitter*). Os dois existem mais pelo servidor do que pelo cliente.

A imagem comum é a de que recuar é educação: um cliente pegando leve para não incomodar o servidor.
Um cliente não é o problema. Um servidor que caiu por um minuto volta para todo celular que tentou
durante aquele minuto, e **se todos esperam o mesmo tempo, todos voltam no mesmo milissegundo**. Isso
é uma segunda queda causada pela recuperação da primeira, e tem nome: a manada (*thundering herd*).

## Três celulares depois de uma queda

O `backoff.ts` tem as duas fórmulas. `ceiling` dobra de `base` até `cap`; `fullJitter` sorteia um
número abaixo do teto, de um gerador com semente para os números se repetirem. Este programa
pergunta a três celulares, sementes 1, 2 e 3, quanto esperariam em cada tentativa, ao lado do teto
que um celular sem jitter esperaria. Salve como `schedule.ts`:

```typescript
// schedule.ts: the waits three phones would choose after the same outage, with and without jitter.
import { seeded, ceiling, fullJitter } from "./backoff.ts";

const BASE = 1000, CAP = 60_000; // milliseconds
const phones = [1, 2, 3].map(seeded);
console.log("attempt  no jitter   phone 1   phone 2   phone 3");
for (let attempt = 1; attempt <= 8; attempt++) {
  const waits = phones.map((random) => fullJitter(attempt, BASE, CAP, random));
  console.log([attempt, ceiling(attempt, BASE, CAP), ...waits].map((n) => String(n).padStart(8)).join("  "));
}
```

```
ana@dev:~/planner/retry$ node schedule.ts
attempt  no jitter   phone 1   phone 2   phone 3
       1      1000       627       734       720
       2      2000         5       649        77
       3      4000      2109      1141      1824
       4      8000      7848      4303       599
       5     16000     15494     14004     12208
       6     32000      8995     20186     15397
       7     60000     36770     29952     29203
       8     60000     43244     21434      9708
```

A coluna `no jitter` é o que todo celular espera, então a segunda tentativa de todo celular cai em
um segundo, a terceira em três, a quarta em sete. Com jitter total, os três celulares se espalham.
Na tentativa 4 eles esperam 7848, 4303 e 599 milissegundos, mais de sete segundos de diferença, e
com mil celulares as requisições se espalham pela janela inteira em vez de chegar como um pico só. A
figura põe as quatro primeiras tentativas de cada um numa mesma linha do tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l09-herd\" aria-label=\"Uma linha do tempo de 0 a 16 segundos depois de uma queda. Sem jitter, todo celular tenta de novo aos 1, 3, 7 e 15 segundos, todos juntos. Com jitter total, o celular 1 tenta aos 0,6, 0,6, 2,7 e 10,6 segundos, o celular 2 aos 0,7, 1,4, 2,5 e 6,8, e o celular 3 aos 0,7, 0,8, 2,6 e 3,2: os mesmos celulares, espalhados.\"><path d=\"M170.0 30 L170.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"170.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M236.0 30 L236.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"236.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><path d=\"M302.0 30 L302.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"302.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><path d=\"M368.0 30 L368.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"368.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><path d=\"M434.0 30 L434.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"434.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><path d=\"M500.0 30 L500.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"500.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M566.0 30 L566.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"566.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><path d=\"M632.0 30 L632.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"632.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><path d=\"M698.0 30 L698.0 186\" stroke=\"var(--scan)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"698.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16</text><text x=\"434.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">segundos depois da queda</text><text x=\"160\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem jitter: todo celular</text><rect x=\"199.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"265.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"397.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"661.0\" y=\"38\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">celular 1</text><rect x=\"186.7\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"186.9\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"256.5\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"515.4\" y=\"78\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">celular 2</text><rect x=\"190.2\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"211.6\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"249.3\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"391.3\" y=\"118\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"160\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">celular 3</text><rect x=\"189.8\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"192.3\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"252.5\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"272.3\" y=\"158\" width=\"8\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect></svg>", "caption": "As mesmas quatro novas tentativas, a partir das esperas que o schedule.ts imprimiu. Sem jitter todo celular chega nos mesmos instantes; com ele, as chegadas se espalham pela janela."}
```

## O que os números custam

O jitter total deixa algumas esperas bem curtas: a segunda espera do celular 1 é de 5
milissegundos. Tudo bem. A espera média continua sendo metade do teto, o teto continua dobrando, e
uma espera curta de vez em quando é justamente o que espalha a carga. **O teto importa tanto quanto
o dobrar.** Sem ele, a oitava tentativa esperaria 128 segundos e a décima segunda mais de meia hora;
com um teto de 60 segundos, um celular que ficou offline a tarde toda tenta de novo menos de um
minuto depois de a rede voltar.

E as esperas não são temporizadores num celular que dorme. Uma drenagem esperando quarenta segundos
quando o sistema suspende o app não acorda quando os quarenta segundos acabam; ela roda de novo
quando o app roda, ou quando um trabalho em segundo plano é permitido. A aula 16 é o que os sistemas
permitem.
