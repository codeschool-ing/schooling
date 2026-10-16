---
title: Escrevendo critérios de aceitação que quem testa consegue usar
version: 1
---

**Critérios de aceitação são as condições que uma história precisa cumprir para ser aceita pela dona do
produto.** Em geral são escritos pela dona do produto, muitas vezes com o time, e são a coisa mais próxima que
um time Scrum tem da base de teste da aula 9: a fonte dos resultados esperados.

A qualidade deles varia enormemente, e a diferença importa a quem testa mais que a qualquer um, porque um
critério que não pode ser conferido é um critério que ninguém consegue dizer que foi cumprido.

## Três versões do mesmo critério

Eis um critério para a história *idosos pagam meia*, escrito de três jeitos:

| versão | o critério | quem testa consegue usar? |
|---|---|---|
| vago | "o desconto para idosos funciona corretamente" | não: correto segundo o quê? |
| uma regra | "clientes maiores de 60 pagam meia" | em parte: é exatamente a frase que escondeu o defeito |
| exemplos | "um cliente de 59 paga R$ 36,00; de 60 paga R$ 18,00; de 61 paga R$ 18,00, numa sessão da noite" | sim: três conferências, com os resultados esperados |

A terceira versão é mais longa, e cada palavra é útil. Nomeia a borda dos dois lados, dá o preço esperado,
fixa a sessão para o preço não ser ambíguo. **Escrever um critério como exemplos força toda ambiguidade para a
luz**: a Joana não consegue escrever *60 paga R$ 18,00* sem decidir se sessenta conta.

## Um formato que ajuda

Muitos times escrevem critérios num formato fixo, emprestado do desenvolvimento guiado por comportamento:

> **Dado** um cliente de 60 anos numa sessão da noite de quinta,
> **quando** ele compra um ingresso,
> **então** paga R$ 18,00.

O *dado* monta a situação, o *quando* é a ação, o *então* é o resultado esperado. O formato não é mágico, mas
torna difícil deixar de fora uma coisa: o *então*, que é a parte de que quem testa mais precisa. A aula 16 trata
desse formato a fundo, e de rodar esses critérios como testes automaticamente.

## O que quem testa acrescenta aos critérios

Quando uma dona do produto escreve critérios de aceitação, a contribuição de quem testa são os casos em que ela
não pensou, escolhidos com os hábitos das aulas anteriores:

- **os dois lados de toda linha** da regra, da aula 6: 59 e 60, 11 e 12, 16:59 e 17:00;
- **as combinações**, também da aula 6: idosos numa quarta;
- **entradas que ninguém mencionou**: uma idade digitada como palavra, um horário escrito com um dígito;
- **o que acontece depois**, da aula 8: o desconto fica registrado com o pedido, para o relatório do contador
  poder mostrá-lo?

Nem toda sugestão vira critério. Algumas viram perguntas que a Joana responde diferente do que a Lia esperava;
algumas são julgadas sem valor de critério e deixadas para a exploração. O ponto é que a decisão é tomada antes
de o código ser escrito, numa conversa, e não descoberta depois num relato de defeito. Essa conversa tem nome e
formato próprios, os três amigos, e a aula 17 trata dela.
