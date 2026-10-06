---
title: Erros tipo I e tipo II
version: 1
---

Um teste de hipótese termina com uma decisão, e a verdade sobre a qual ele decide é desconhecida. Ponha as
duas lado a lado e há quatro possibilidades:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 230\" role=\"img\" data-fig=\"l15-errors\" aria-label=\"Uma tabela dois por dois. Colunas: o teste rejeita a nula, ou não. Linhas: na verdade não há efeito, ou há. Sem efeito e rejeitada: um erro tipo I, um alarme falso, com probabilidade alfa. Sem efeito e não rejeitada: correto. Efeito real e rejeitada: correto, com probabilidade igual ao poder. Efeito real e não rejeitada: um erro tipo II, um efeito perdido, com probabilidade beta.\"><text x=\"297.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o teste rejeita a nula</text><text x=\"512.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o teste mantém a nula</text><text x=\"20.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na verdade, sem efeito</text><rect x=\"194.0\" y=\"40.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">erro tipo I</text><text x=\"297.5\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um alarme falso: α</text><rect x=\"409.0\" y=\"40.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"512.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">correto</text><text x=\"512.5\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">probabilidade 1 − α</text><text x=\"20.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na verdade, efeito real</text><rect x=\"194.0\" y=\"120.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">correto</text><text x=\"297.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o poder: 1 − β</text><rect x=\"409.0\" y=\"120.0\" width=\"207.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"512.5\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">erro tipo II</text><text x=\"512.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um efeito perdido: β</text></svg>", "caption": "Dois jeitos de acertar e dois de errar. α se escolhe; β depende do tamanho do efeito e de quantos dados existem."}
```

## O erro tipo I: um alarme falso

A hipótese nula é verdadeira — não há efeito — e o teste a rejeita mesmo assim. Isso é um **erro tipo I**,
e a probabilidade dele é **α**, o nível de significância. Com α = 0,05, um teste de uma nula verdadeira dá
alarme à toa uma vez em vinte. A simulação da aula 14 mostrou isso acontecendo: em 20.000 testes de
mudanças que não faziam nada, 4,7% saíram significativos.

O erro tipo I é o que o teste foi construído para controlar. Você escolhe a taxa dele de antemão.

## O erro tipo II: um efeito perdido

A hipótese nula é falsa — há um efeito real — e o teste não a rejeita. Isso é um **erro tipo II**, e a
probabilidade dele se escreve **β** (beta).

Ao contrário de α, β não se escolhe. Ele depende de coisas fora do controle do teste: **quão grande é o
efeito real**, **quão ruidosos são os dados** e **quantos dados existem**. Um efeito grande medido numa
amostra grande e silenciosa é difícil de perder; um efeito pequeno medido em poucas observações ruidosas é
fácil de perder.

## Qual erro é pior depende da decisão

- Um **alarme de fumaça** é regulado para ter muitos alarmes falsos e pouquíssimas falhas, porque um
  incêndio não detectado é uma catástrofe e um alarme falso é uma torrada queimada.
- Um **tribunal** é regulado ao contrário: condenar um inocente, um alarme falso, é tratado como pior que
  absolver um culpado, uma falha.
- **O teste de rotas da Horta**: um alarme falso significaria pagar por um sistema que não faz nada; uma
  falha significaria recusar um que economiza tempo em toda entrega. Qual custa mais é uma pergunta de
  negócio, e a resposta deveria moldar o teste.

## Os dois estão ligados

Para uma amostra fixa, baixar α sobe β. Um limite mais rigoroso torna os alarmes falsos mais raros e as
falhas mais comuns, porque a linha que separa "rejeitar" de "manter" se afasta da nula, e efeitos reais mas
modestos caem mais vezes do lado errado dela. A próxima seção desenha essa troca.
