---
title: Opções, não alarmes
version: 1
---

**Um risco apresentado sozinho pede a quem decide que se preocupe. Um risco apresentado com opções
pede que escolha, que é justamente o que essa pessoa está ali para fazer.** O engenheiro que relata
um risco e para por aí entregou a parte difícil, decidir o que fazer a respeito, para a pessoa menos
preparada para isso.

## Quatro respostas, e aceitar é uma delas

Todo risco tem as mesmas quatro respostas possíveis, seja qual for o nome que a metodologia dá a
elas:

1. **Evitar**: parar de fazer o que cria o risco. Parar de rodar o planejador de rotas no pico.
2. **Reduzir**: torná-lo menos provável ou menos caro. Uma réplica, limites de conexão, um alerta
   mais rápido.
3. **Transferir**: fazer outra pessoa carregá-lo. Um seguro, uma cláusula de contrato, um serviço
   gerenciado com multa por indisponibilidade.
4. **Aceitar**: decidir, de forma consciente, carregá-lo.

A quarta é a que engenheiros esquecem que é legítima. **Aceitar um risco é a decisão certa quando
reduzi-lo custa mais do que vale**, e só quem é dono do orçamento pode tomá-la. O que não é legítimo
é aceitá-lo por omissão, porque ninguém decidiu.

## Opções com o preço

A proposta de Lívia pôs as quatro alternativas da aula 2 numa linha cada, nas unidades que Caio usa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Quatro barras horizontais na mesma escala. A perda esperada de receita sem fazer nada é de R$ 561.600 por ano. O custo no primeiro ano de um servidor maior é R$ 108.000, de uma réplica de leitura R$ 96.000 e de um pool de conexões R$ 16.000.\"><defs><marker id=\"optionsbar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perda esperada, sem fazer nada</text><rect x=\"20\" y=\"40\" width=\"524.16\" height=\"18\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"534.16\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 561.600 por ano</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">servidor maior</text><rect x=\"20\" y=\"96\" width=\"100.8\" height=\"18\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"130.8\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 108.000</text><text x=\"20\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">réplica de leitura</text><rect x=\"20\" y=\"144\" width=\"89.6\" height=\"18\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"119.6\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 96.000</text><text x=\"20\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pool de conexões</text><rect x=\"20\" y=\"192\" width=\"14.933333333333334\" height=\"18\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"44.93333333333334\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 16.000</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">receita perdida por ano contra o custo no primeiro ano de cada correção</text></svg>", "caption": "Na mesma escala, toda correção é pequena perto da perda que ataca, e a decisão deixa de ser \"vale a pena?\" para virar \"qual correção dura mais?\". Só a perda crônica está desenhada; o risco de cauda somaria a ela."}
```

| opção | custo no primeiro ano | o que faz com a perda |
|---|---|---|
| não fazer nada | R$ 0 | a perda crônica continua e cresce; risco de cauda de 2 a 4 vezes por ano |
| servidor maior | R$ 108.000 (R$ 9.000 por mês) | as duas caem por cerca de um ano e voltam com o volume |
| pool de conexões | cerca de R$ 16.000 (duas semanas-engenheiro) | risco de cauda menor; a perda crônica quase toda continua |
| réplica de leitura | cerca de R$ 96.000 (seis semanas-engenheiro, R$ 4.000 por mês) | as duas eliminadas para o crescimento previsível |

A semana-engenheiro é calculada a R$ 8.000, o valor que o financeiro usa no planejamento, e o
documento diz isso. **Diante de uma perda esperada de R$ 560.000 por ano em receita, toda opção,
exceto não fazer nada, se paga**, e a comparação entre elas é sobre quanto tempo a correção dura.

Isso muda a conversa. Caio não precisa mais decidir se acredita que o banco está frágil. Ele decide
entre quatro opções com preço, uma delas a de graça, e pode escolher a de graça de olhos abertos.

## Riscos aceitos ficam por escrito

Se quem decide aceita um risco, a aceitação entra no registro de riscos com três coisas: **quem
aceitou, quando vai ser revista e o que dispararia uma revisão antecipada.**

> **Risco:** o banco do checkout fica sem conexões no pico. **Aceito** por Caio em 12 de fevereiro,
> enquanto se aguarda o trabalho de abril. **Revisão:** 31 de março. **Gatilho para revisão
> antecipada:** qualquer sexta em que as conexões passem de 95% do limite, ou qualquer queda do
> checkout.

Em 6 de março o gatilho disparou. Ninguém precisou discutir se a decisão devia ser reaberta: o
registro dizia que estava reaberta.

## A falha oposta

Dar alarme falso o tempo todo é o outro jeito de perder. O engenheiro que escala todo risco como crítico ensina os
diretores a dar pouco peso a todos, e o risco de verdade chega numa voz que ninguém escuta mais. **Guarde o
alarme para o risco cuja perda esperada o justifica**, diga com clareza quando um risco é pequeno, e
os grandes serão ouvidos.
