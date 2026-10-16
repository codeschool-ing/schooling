---
title: Como você sabe que a resposta está certa?
version: 1
---

**Um oráculo de teste é aquilo que quem testa usa para decidir se um resultado está certo.** Rodar um teste produz um
resultado: um preço, uma mensagem, uma tela. O resultado não diz nada sozinho. Alguma coisa precisa dizer o que ele
*deveria* ter sido, e essa coisa é o oráculo. William Howden deu o nome em 1978, emprestando a palavra para uma fonte
de respostas que quem pergunta não consegue achar sozinho.

Todo teste deste curso teve um, em geral sem ninguém apontar para ele:

| teste | o resultado | o oráculo |
|---|---|---|
| aula 1: `python tickets.py 60 no thu 20:00` | R$ 36,00 | a regra da Joana, lida com o sentido do estatuto para *acima de 60* |
| aula 4: o pedido das 9:30 de domingo | R$ 108,00 | o preço na bilheteria, R$ 84,00 |
| aula 8: o pedido de sete ingressos | gravado com total 0 | a quarta frase da regra: um pedido tem de 1 a 6 ingressos |
| aula 17: o esboço | `R$ 9,00` para um estudante na quarta | os cartões verdes que a Joana combinou |

## O problema do oráculo

Para uma regra de preço com cinco frases, o oráculo é fácil de achar: calcule o preço à mão a partir da regra. Para a
maior parte do software real, não é. Como deve ficar o mapa de assentos quando duas pessoas reservam o mesmo assento no
mesmo instante? Quão rápido é rápido o bastante? Qual é a recomendação certa para um cliente que viu todos os filmes do
mês? Muitas vezes ninguém escreveu a resposta, e para algumas perguntas ninguém consegue.

Isso se chama **o problema do oráculo**: gerar entradas é fácil, e um computador faz isso o dia inteiro; saber qual
seria a saída certa é difícil, e não escala. Um teste sem oráculo não é um teste. É um programa sendo rodado, com uma
pessoa torcendo para perceber se algo estiver errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 220\" role=\"img\" data-fig=\"l19-oracle\" aria-label=\"Um teste desenhado como fluxo. Uma entrada, 60 anos numa sessão de quinta às 20:00, entra no programa, que dá um resultado, R$ 36,00. Separadamente, um oráculo, a regra, a bilheteria, a lei ou um exemplo, diz qual deveria ser o resultado. Os dois são comparados, e o veredito é: errado, segundo o estatuto, que diz R$ 18,00.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"38.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">entrada</text><text x=\"70.0\" y=\"51.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">60, qui 20:00</text><path d=\"M131.0 45.0 L169.0 45.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"20.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o programa</text><path d=\"M301.0 45.0 L339.0 45.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"340.0\" y=\"20.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"38.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">resultado</text><text x=\"400.0\" y=\"51.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">R$ 36,00</text><rect x=\"340.0\" y=\"140.0\" width=\"120.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"160.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">oráculo</text><text x=\"400.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a regra, a bilheteria,</text><text x=\"400.0\" y=\"185.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a lei, um exemplo</text><path d=\"M461 45 C 500 45, 500 85, 520 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M461 173 C 500 173, 500 135, 520 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"495.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comparar</text><rect x=\"522.0\" y=\"78.0\" width=\"110.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"577.0\" y=\"97.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">veredito</text><text x=\"577.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">errado, segundo</text><text x=\"577.0\" y=\"122.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o estatuto: R$ 18,00</text></svg>", "caption": "Rodar o programa dá um resultado. Só o oráculo o transforma num veredito, e o veredito o nomeia.", "same": ["R$ 36,00"]}
```

## Por que isso importa a quem testa

Três hábitos vêm de levar oráculos a sério.

- **Saiba que oráculo você está usando.** Quando a Lia diz que um preço está errado, ela diz *errado segundo o quê*: a
  regra, a bilheteria, o exemplo combinado, a lei. Um relato de defeito que nomeia seu oráculo pode ser discutido; um
  que só diz "errado", não.
- **Procure um oráculo antes do teste.** Um teste planejado sem oráculo produz um resultado que ninguém consegue
  julgar. Na aula 6, todo caso tinha o preço esperado escrito ao lado antes de qualquer coisa rodar; aquela coluna era
  o oráculo.
- **Tenha mais de um.** Todo oráculo pode estar errado, e as próximas seções mostram como. Um resultado em que dois
  oráculos independentes concordam vale mais que um que só um deles conferiu.

O resto desta aula trata dos tipos de oráculo disponíveis quando o resultado esperado não está simplesmente escrito, e
de um tipo que consegue achar defeitos sem saber a resposta certa.
