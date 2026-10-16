---
title: Os quadrantes do teste ágil
version: 1
---

**Quando o teste acontece o tempo todo, um time precisa de um jeito de ver se está testando tudo o que
deveria, ou só as partes fáceis.** O mapa mais usado para isso são os **quadrantes do teste ágil**, propostos
por Brian Marick em 2003 e popularizados por Lisa Crispin e Janet Gregory em *Agile Testing*.

O mapa tem dois eixos:

- **esquerda e direita**: testes que **apoiam o time**, ajudando-o a construir a coisa certo enquanto
  constrói, contra testes que **criticam o produto**, descobrindo se o que foi construído é bom o bastante
  depois que existe;
- **cima e baixo**: testes voltados ao **negócio**, expressos em termos que uma dona do produto entende,
  contra testes voltados à **tecnologia**, expressos em termos de código e infraestrutura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l11-quadrants\" aria-label=\"Um quadrado dividido em quatro quadrantes. Colunas: apoiando o time à esquerda, criticando o produto à direita. Linhas: voltados ao negócio em cima, voltados à tecnologia embaixo. Em cima à esquerda, Q2: exemplos e testes de história. Em cima à direita, Q3: exploração, usabilidade, aceitação. Embaixo à esquerda, Q1: testes de unidade e de componente. Embaixo à direita, Q4: desempenho, carga, segurança.\"><text x=\"340.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">voltados ao negócio</text><text x=\"340.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">voltados à tecnologia</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">apoiando o time</text><text x=\"540.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">criticando o produto</text><rect x=\"153.0\" y=\"43.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Q2</text><text x=\"245.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exemplos, testes de história</text><rect x=\"343.0\" y=\"43.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Q3</text><text x=\"435.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exploração, usabilidade,</text><text x=\"435.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aceitação</text><rect x=\"153.0\" y=\"153.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Q1</text><text x=\"245.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">testes de unidade e de componente</text><rect x=\"343.0\" y=\"153.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Q4</text><text x=\"435.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">desempenho, carga,</text><text x=\"435.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">segurança</text></svg>", "caption": "Os quadrantes de Marick, como Crispin e Gregory os desenharam. Muitos bons testes nascem à direita, achados explorando, e ficam à esquerda, como um exemplo conferido a cada mudança."}
```

## Os quatro, no Cine Aurora

| quadrante | o que guarda | no Cine Aurora |
|---|---|---|
| **Q1**: voltado à tecnologia, apoiando o time | testes de unidade e de componente, escritos por desenvolvedores enquanto programam | um teste de que `price(60, …)` é 1800, rodado a cada mudança |
| **Q2**: voltado ao negócio, apoiando o time | exemplos e testes de história que dizem o que uma funcionalidade deve fazer, muitas vezes automatizados | "um estudante numa quarta paga R$ 18,00", escrito antes do código com a Joana |
| **Q3**: voltado ao negócio, criticando o produto | teste exploratório, usabilidade, demonstrações, aceitação do usuário | a Lia explorando o mapa de assentos; a Célia experimentando a loja no balcão |
| **Q4**: voltado à tecnologia, criticando o produto | desempenho, carga, segurança e outras características da aula 2 | trezentos compradores na noite de estreia de um sucesso |

Os quadrantes são numerados para referência, não para ordem. Um time não passa por Q1 e depois Q2; faz um
pouco dos quatro em todo ciclo, na proporção que o produto pede.

## Para que serve o mapa

Os quadrantes são uma **lista contra pontos cegos**, como as nove características da aula 2. Um time que
automatiza muito costuma ter Q1 e Q2 cheios e nada em Q3, porque explorar não produz um sinal verde. Um time
de testes manuais costuma ter Q3 movimentado e Q1 vazio, porque ninguém escreve testes de unidade. Desenhar
no mapa o teste que o time de fato faz, com honestidade, mostra o canto vazio.

Dois defeitos deste curso mostram o ponto. A soma de descontos da quarta foi achada pela Lia perguntando o
que a regra não dizia: isso é Q3, crítica, do lado do negócio. Guardada depois como um exemplo escrito com a
Joana, ela passa para Q2, onde apoia o time e é conferida a cada mudança. **Muitos bons testes nascem em Q3 e
terminam a vida em Q2 ou Q1**: achados explorando, mantidos automatizando.

## O que o mapa não é

Não é uma lista de quem faz o quê, embora seja muitas vezes lido assim. Desenvolvedores exploram, quem
testa escreve exemplos, donos do produto participam de Q3. E não é uma medida de qualidade: um time com
testes nos quatro quadrantes ainda pode testar as coisas erradas em cada um. É um desenho que torna
impossível não ver uma lacuna específica, uma categoria inteira de teste que ninguém está fazendo.
