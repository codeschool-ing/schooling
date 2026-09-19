---
title: Teclados, e qual deles escreve a sua própria língua
version: 1
---

Um teclado é uma grade de interruptores e uma tabela que diz qual interruptor significa qual
caractere. As duas metades podem estar erradas separadamente, e é por isso que "meu teclado
escreve as letras erradas" são dois problemas diferentes com dois consertos diferentes.

## Layout é software, e o que está impresso nas teclas não é

O **layout físico** é o formato: quantas teclas, onde fica o enter, se existe um teclado
numérico. O **layout lógico** é a tabela que o sistema usa para transformar a tecla número 41 num
caractere. Eles são definidos separadamente, e nada obriga os dois a concordarem.

Daí saem duas falhas distintas:

- **O impresso e o produzido discordam.** Você aperta `ç` e sai `;`. O teclado físico é
  brasileiro e o sistema foi informado de que ele é americano. Conserta-se nas configurações, não
  comprando nada.
- **O caractere não está no teclado.** Um teclado de layout US não tem tecla `ç`. Ajuste nenhum
  cria uma; o layout te dá um jeito de compor no lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas fileiras de quatro teclas cada, desenhadas como quadrados, comparando o canto direito da linha de descanso. A fileira de cima está rotulada ABNT2 e suas teclas trazem L, C-cedilha, til e circunflexo, e agudo e grave. A fileira de baixo está rotulada US e as mesmas quatro posições trazem L, ponto e vírgula, apóstrofo, e colchete de abertura. Notas à direita dizem que o ABNT2 tem uma tecla de cedilha só dela e uma tecla dedicada ao til e ao circunflexo, e que o US não tem cedilha alguma, então você digita apóstrofo e depois c.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">O canto direito da linha de descanso, onde os dois layouts se separam</text><text x=\"24\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">ABNT2</text><rect x=\"120\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">L</text><rect x=\"180\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">Ç</text><rect x=\"240\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"266\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">~ ^</text><rect x=\"300\" y=\"60\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"326\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">´ `</text><text x=\"24\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">US</text><rect x=\"120\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">L</text><rect x=\"180\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">;</text><rect x=\"240\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"266\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">'</text><rect x=\"300\" y=\"150\" width=\"52\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"326\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">[</text><text x=\"400\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Uma tecla para a cedilha,</text><text x=\"400\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma para o til e o circunflexo,</text><text x=\"400\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma para o agudo e o grave.</text><text x=\"400\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Cedilha nenhuma.</text><text x=\"400\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Na variante internacional você</text><text x=\"400\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">compõe com dois toques.</text><path d=\"M24 226 L696 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"24\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">As teclas estão nos mesmos lugares. O que cada uma produz é uma tabela, e a tabela é um ajuste.</text></svg>", "caption": "Quatro posições de tecla, duas tabelas. Tudo o que faz de um teclado brasileiro um teclado brasileiro está neste canto dele.", "same": ["ABNT2", "US"]}
```

## ABNT2, que é o que se compra aqui

`ABNT2` é o padrão brasileiro, e o que ele te dá além de um layout US vale nomear:

- uma **tecla `ç`** só dela, onde o layout americano tem `;`;
- **teclas mortas** para o agudo, o grave, o til e o circunflexo — aperte o acento, depois a
  vogal, e sai `á`, `à`, `ã`, `â`;
- **doze teclas** na fileira de baixo em vez de onze, a extra ficando à esquerda do shift
  direito;
- **`R$`** impresso e produzido, e uma `/` no teclado numérico, onde um teclado americano não tem
  nenhuma.

O layout US-Internacional compõe os mesmos acentos a partir das teclas de apóstrofo e aspas, o
que funciona e é mais lento, e tem um efeito colateral famoso: digitar um apóstrofo antes de uma
vogal vira silenciosamente uma vogal acentuada, então `don't` precisa de um espaço depois do
apóstrofo para sair certo.

## Membrana, mecânico, e o que de fato muda

- **Membrana** — uma folha de borracha sob as teclas fecha um circuito. Barato, silencioso, mole,
  e é o que quase todo teclado vendido é.
- **Mecânico** — um interruptor por tecla. Vida mais longa, um ponto definido em que a tecla
  registra, e mais barulhento a menos que os interruptores sejam escolhidos para não ser.
- **Tesoura** — o tipo achatado dos notebooks e dos teclados finos de mesa. Curso curto, estável,
  e sem conserto quando uma tecla falha.

Mecânico é genuinamente mais agradável de digitar por horas e genuinamente não é um ganho de
produtividade. Compre porque as suas mãos gostam.

## Dois recursos que não são propaganda

**Rollover de N teclas** é quantas teclas podem ser seguradas ao mesmo tempo e ainda assim todas
registrarem. Um teclado barato perde o terceiro ou o quarto toque simultâneo. Importa para jogos
e para quem digita rápido o bastante para sobrepor teclas.

**Antifantasma** é o mesmo problema dito ao contrário: apertar três teclas e sair uma quarta em
que você não encostou. Se um teclado promete um desses e não o outro, está prometendo a metade
fácil.
