---
title: Risco é probabilidade vezes impacto
version: 1
---

**Um risco é algo que pode dar errado, julgado pela chance de acontecer e pelo estrago que faria.** O teste reduz o
risco achando os defeitos antes dos clientes, então as áreas com mais risco recebem mais teste. Isso se chama **teste
baseado em risco**, e é como a maioria dos times de teste prioriza, chame isso assim ou não.

## Dando notas

Probabilidades precisas raramente estão disponíveis, então os times dão notas às duas metades numa escala pequena,
muitas vezes de 1 a 3, e multiplicam:

| nota | probabilidade | impacto |
|---|---|---|
| 1 | baixa: código antigo, simples, sem mudança | baixo: um incômodo com contorno |
| 2 | média: mudado, ou moderadamente complexo | médio: um cliente é incomodado ou alguém da equipe perde tempo |
| 3 | alta: novo, complexo, ou mudado às pressas | alto: perde-se dinheiro, a lei é descumprida, ou as vendas param |

As seis áreas do Cine Aurora, com notas do Rafael e do Tomás para probabilidade e da Joana para impacto:

| área | probabilidade | impacto | risco |
|---|---|---|---|
| regra de preço | 3 | 3 | 9 |
| cupons | 3 | 2 | 6 |
| pedidos | 2 | 3 | 6 |
| reembolsos | 2 | 2 | 4 |
| mapa de assentos | 1 | 2 | 2 |
| relatório noturno | 1 | 1 | 1 |

A regra de preço tem a maior nota nas duas: mudou nesta sprint, teve mais defeitos que qualquer outra coisa, e um
preço errado é dinheiro perdido em cada ingresso. O relatório noturno tem a menor: uma coluna nova num relatório com
que ninguém age na hora, onde um erro é percebido na manhã seguinte e não custa nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 300\" role=\"img\" data-fig=\"l20-matrix\" aria-label=\"Uma matriz de risco de três por três, probabilidade na horizontal de baixa a alta, impacto na vertical de baixo a alto. A regra de preço fica em probabilidade alta e impacto alto, marcada comece aqui. Pedidos: probabilidade média, impacto alto. Cupons: probabilidade alta, impacto médio. Reembolsos: médio e médio. Mapa de assentos: probabilidade baixa, impacto médio. Relatório noturno: baixo e baixo.\"><rect x=\"90.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"90.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"90.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">baixa</text><text x=\"82.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">baixa</text><text x=\"315.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">média</text><text x=\"82.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">média</text><text x=\"465.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">alta</text><text x=\"82.0\" y=\"58.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">alta</text><text x=\"315.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">probabilidade</text><text x=\"30.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">impacto</text><rect x=\"403.0\" y=\"46.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">regra de preço</text><rect x=\"403.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cupons</text><rect x=\"253.0\" y=\"46.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pedidos</text><rect x=\"253.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">reembolsos</text><rect x=\"103.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">mapa de assentos</text><rect x=\"103.0\" y=\"198.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">relatório noturno</text><text x=\"465.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">comece aqui</text></svg>", "caption": "As seis áreas do Cine Aurora antes de entrarem uso e histórico. O canto de cima à direita fica com mais horas."}
```

## Lendo a matriz

Postas numa grade, probabilidade na horizontal e impacto na vertical, as áreas caem em zonas. O canto de cima à
direita é onde o teste começa e para onde vai a maior parte das horas. O canto de baixo à esquerda recebe uma
conferência rápida e mais nada. Os outros dois cantos pedem reflexão:

- **impacto alto, probabilidade baixa**, como um mapa de assentos que vende o mesmo lugar duas vezes, é exatamente onde
  um time fica tentado a pular o teste porque "esse código nunca muda". Uma conferência curta é um seguro barato;
- **probabilidade alta, impacto baixo** é onde defeitos vão aparecer, e a maioria não vai importar muito. Achá-los
  ainda vale alguma coisa, mas não primeiro.

## As notas são uma conversa, não uma medição

Ninguém consegue medir que os cupons têm probabilidade exatamente 3. Os números são um jeito de fazer três pessoas
dizerem o que acreditam e verem onde discordam. Quando a Joana deu nota 2 aos reembolsos e a Célia disse que um
reembolso que falha na frente de um cliente no balcão seria a pior coisa que poderia acontecer a ela na semana, o
impacto virou 3 e a ordem mudou. Essa conversa é o valor; a multiplicação é só o registro dela.

Dois cuidados mantêm as notas honestas. **Escreva por quê** cada nota é o que é, para quem ler depois discordar do
motivo e não do número. E **dê as notas de novo** quando algo mudar: uma correção às pressas na véspera da entrega
aumenta uma probabilidade, seja qual for a que ela tinha na segunda.
