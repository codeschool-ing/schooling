---
title: Dimensionando o efeito com uma faixa
version: 1
---

"Deve ajudar" não é um efeito. **Uma recomendação diz quanto deve ajudar, na unidade do leitor, e com que
certeza.** O jeito honesto de dizer as duas coisas ao mesmo tempo é uma faixa.

## A conta

Se a mudança levar as primeiras entregas atrasadas na empresa inteira de 17,3% para 8%, e os clientes que
antes atrasavam passarem a cancelar como os do prazo, o número de clientes mantidos por ano é:

```localised
=2*6113*(1058/6113-0,08)*(439/1058-881/5055)
```

Dois semestres de 6.113 assinantes novos, vezes a fatia deles que deixa de atrasar, vezes a taxa de
cancelamento a mais que o atraso traz. O LibreOffice Calc responde **273,8**, então cerca de 274 clientes por
ano. Cada cancelamento precoce evitado mantém cerca de R$ 1.554 de margem ao longo da vida (aula 11), então o
efeito inteiro vale cerca de **R$ 426 mil por ano**.

## Por que uma faixa, e qual

Esse número supõe duas coisas que podem não valer:

- **Que o piloto chegue a 8%.** Pode chegar a 12%.
- **Que um cliente cuja primeira caixa chega no prazo se comporte como os clientes do prazo nos dados.**
  Parte da distância pode vir de outra coisa que os clientes atrasados têm em comum; a aula 10 testa a
  candidata óbvia e a aula 12 as menos óbvias.

Nenhuma das duas hipóteses tem número ainda, e é para isso que serve o piloto. Então a Marina dá uma faixa:
**o efeito inteiro como teto, metade dele como piso, de R$ 210 mil a R$ 430 mil por ano**, e diz numa frase
por que o piso é a metade. Isso é um julgamento, declarado como tal. Um leitor que acha um terço mais
realista pode dizer, e a conversa passa a ser sobre uma hipótese, e não sobre confiar ou não na analista.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 170\" role=\"img\" data-fig=\"l09-range\" aria-label=\"Uma escala horizontal de margem mantida por ano, de zero a R$ 500 mil. Uma barra grossa vai de cerca de R$ 210 mil, metade do efeito, a cerca de R$ 430 mil, o efeito inteiro. No zero, uma marca mostra o custo da opção recomendada: nenhum gasto novo.\"><path d=\"M60.0 110.0 L640.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 110.0 L60.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 0 mil</text><path d=\"M176.0 110.0 L176.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"176.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 100 mil</text><path d=\"M292.0 110.0 L292.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"292.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 200 mil</text><path d=\"M408.0 110.0 L408.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 300 mil</text><path d=\"M524.0 110.0 L524.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"524.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 400 mil</text><path d=\"M640.0 110.0 L640.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 500 mil</text><path d=\"M307.0 76.0 L554.0 76.0 L554.0 96.0 L307.0 96.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"307.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">metade do efeito: cerca de R$ 210 mil</text><text x=\"554.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">efeito inteiro: cerca de R$ 430 mil</text><path d=\"M60.0 70.0 L60.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"66.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">custo</text><text x=\"350.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">margem mantida por ano se o piloto for estendido</text></svg>", "caption": "A faixa é larga e o piso dela ainda supera o custo com folga, então a decisão não depende de qual ponta acabe certa."}
```

## O que a faixa faz pela decisão

O custo da opção recomendada é nenhum gasto novo. **Até o piso da faixa paga isso muitas vezes**, então a
decisão não depende de qual ponta está certa. Essa é a coisa mais útil que uma faixa pode mostrar: se a
incerteza importa. Quando a ponta mais baixa não justificaria o custo, a recomendação deve dizer isso, e
quase sempre virar um teste, que é a próxima seção.
