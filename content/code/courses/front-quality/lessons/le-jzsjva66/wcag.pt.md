---
title: A WCAG, e como ela é construída
version: 1
---

**As Web Content Accessibility Guidelines são o padrão do W3C para uma página acessível, e a versão atual é
a WCAG 2.2, publicada em outubro de 2023.** Elas são escritas como afirmações testáveis, de modo que uma
página passa ou falha em cada uma, e é isso que faz delas um padrão e não um conselho.

Elas se organizam em quatro camadas:

1. **Quatro princípios**, conhecidos pela sigla em inglês POUR: uma página é **perceptível** (tudo pode ser
   captado por algum sentido), **operável** (tudo pode ser feito por algum meio), **compreensível** (o
   conteúdo e o comportamento fazem sentido) e **robusta** (funciona com as ferramentas que as pessoas usam
   para chegar a ela, tecnologia assistiva incluída).
2. **Treze diretrizes** abaixo deles, como *1.4 Distinguível* ou *2.1 Acessível por teclado*.
3. **Critérios de sucesso** abaixo de cada diretriz, as afirmações testáveis, numeradas por princípio e
   diretriz: *1.4.3 Contraste (Mínimo)*, *2.1.1 Teclado*, *3.3.2 Rótulos ou instruções*, o que a aula 3
   encontrou.
4. **Técnicas**, publicadas à parte, que mostram maneiras de atender a cada critério. São exemplos, não
   exigências: uma página pode atender a um critério de outro jeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-wcag\" aria-label=\"A WCAG 2.2 desenhada em quatro camadas, de cima para baixo. Quatro princípios: perceptível, operável, compreensível, robusto. Abaixo deles, treze diretrizes; abaixo de perceptível, por exemplo, a 1.4 Distinguível. Abaixo das diretrizes, 86 critérios de sucesso, cada um com um nível: abaixo da 1.4, o 1.4.3 Contraste (Mínimo) no nível AA e o 1.4.6 Contraste (Melhorado) no nível AAA. Abaixo dos critérios, as técnicas, que são exemplos de como atendê-los e não são exigidas.\"><defs><marker id=\"l10-wcag-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 princípios</text><rect x=\"200\" y=\"14\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">perceptível · operável · compreensível · robusto</text><path d=\"M99 56 L99 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"72\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">13 diretrizes</text><rect x=\"200\" y=\"72\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1.4 Distinguível</text><path d=\"M99 114 L99 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"130\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">86 critérios de sucesso</text><rect x=\"200\" y=\"130\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1.4.3 Contraste (Mínimo): AA · 1.4.6 Contraste (Melhorado): AAA</text><path d=\"M99 172 L99 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"188\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">técnicas</text><rect x=\"200\" y=\"188\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"453.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exemplos de como atender a um critério, não requisitos</text><text x=\"706\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">a camada testável</text></svg>", "caption": "Só a terceira camada é testada. Uma página atende ou falha em cada critério de sucesso, e o nível dele decide se uma página que falha nele ainda pode afirmar A ou AA."}
```

**A WCAG 2.2 tem 86 critérios de sucesso.** Ela acrescentou nove aos 78 da WCAG 2.1, entre eles o 2.4.11
*Foco não encoberto* e o 2.5.8 *Tamanho do alvo (Mínimo)*, que as aulas 11 e 13 usam, e removeu um, o 4.1.1
*Análise sintática*, porque os navegadores não tropeçam mais na marcação para a qual ele foi escrito. A
versão 2.2 é compatível com as anteriores: uma página que a atende atende também a 2.1 e a 2.0.

## Lendo um critério

A página de cada critério no w3.org tem as mesmas partes, e três delas importam quando você está corrigindo
uma página: o **critério em si**, uma ou duas frases, que é a exigência; o **Understanding**, que diz por
que ele existe e a quem ajuda; e o **How to Meet**, as técnicas e as falhas comuns. Leia o primeiro para
saber o que precisa ser verdade, e o segundo antes de decidir que o seu caso é uma exceção.
