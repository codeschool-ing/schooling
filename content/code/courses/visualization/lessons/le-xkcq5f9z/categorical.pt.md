---
title: Paletas categóricas
version: 1
---

Uma paleta categórica tem um trabalho: **deixar cada categoria fácil de distinguir sem sugerir que
alguma é mais importante**. Isso descarta o jeito óbvio de escolher as cores uma a uma num seletor.

## O que uma boa faz

- **Matizes distintos.** Cada cor fica bem separada dos vizinhos na volta do matiz.
- **Peso parecido.** Nenhuma cor é tão mais clara, escura ou saturada que as outras a ponto de parecer
  a importante. A aula 11 mostrou por que "a mesma luminosidade HSL" não consegue isso.
- **Segura para daltonismo.** As formas mais comuns tornam difícil separar vermelho de verde, então
  uma paleta que depende desse par falha para cerca de um homem em cada doze (aula 14).

A paleta da primeira fileira da figura anterior é a de **Okabe e Ito**, publicada em 2008 para figuras
científicas e desenhada para continuar distinta nas formas comuns de daltonismo. As oito cores dela
são um bom padrão sempre que uma ferramenta deixar você escolher:

| | hex | | hex |
|---|---|---|---|
| laranja | `#E69F00` | azul | `#0072B2` |
| azul-celeste | `#56B4E9` | vermelhão | `#D55E00` |
| verde-azulado | `#009E73` | roxo-avermelhado | `#CC79A7` |
| amarelo | `#F0E442` | preto | `#000000` |

## Quantas categorias

**Poucas.** As pessoas distinguem rápido uns seis a oito matizes e os casam com uma legenda com
segurança. Passando disso, as cores começam a se confundir e a legenda vira tabela de consulta. Com
mais categorias:

- **destaque as poucas que importam** e ponha o resto em cinza, que é o assunto da aula 13;
- **junte as pequenas** em "outros";
- **divida o gráfico** em pequenos múltiplos (aula 10), onde o título do painel substitui a cor.

## Mantenha as cores presas às categorias

Quando uma região ganha uma cor, **ela a mantém em todo gráfico do relatório**. Se o Nordeste é laranja
na página um e azul na página três, um leitor que aprendeu a primeira vai ler errado a segunda. A
aula 13 volta a isso como consistência.
