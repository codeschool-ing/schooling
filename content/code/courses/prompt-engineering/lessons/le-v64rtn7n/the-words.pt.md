---
title: As palavras, e o que cada uma abrange
version: 1
---

"IA" aparece nos anúncios como se fosse o nome de uma coisa só, em geral o assistente de chat mais
recente, e como se o próximo passo depois dele fosse óbvio. As duas metades enganam. **IA é um campo
com muitas partes, e um grande modelo de linguagem é um tipo de sistema dentro de uma delas.** AGI,
a palavra presa ao próximo passo, nomeia uma meta e não um sistema, e não existe teste combinado
para ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Quatro caixas, uma dentro da outra. A de fora é inteligência artificial, com o exemplo de um programa de xadrez cujas regras foram escritas à mão. Dentro dela, aprendizado de máquina, com um filtro de spam treinado com exemplos, e o toylm. Dentro desta, aprendizado profundo, com reconhecer objetos em fotografias. No centro, grandes modelos de linguagem, os modelos por trás dos assistentes de chat.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">inteligência artificial: programas que fazem tarefas que chamamos de inteligentes</text><text x=\"26\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um programa de xadrez com regras escritas à mão</text><rect x=\"40\" y=\"70\" width=\"640\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aprendizado de máquina: comportamento aprendido com exemplos</text><text x=\"56\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um filtro de spam treinado com exemplos</text><text x=\"664\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">toylm</text><rect x=\"70\" y=\"130\" width=\"580\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"86\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aprendizado profundo: redes neurais com muitas camadas</text><text x=\"86\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reconhecer objetos em fotografias</text><rect x=\"100\" y=\"190\" width=\"520\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">grandes modelos de linguagem</text><text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os modelos por trás dos assistentes de chat</text></svg>", "caption": "Cada termo é uma parte do que está em volta dele. Um grande modelo de linguagem é um tipo de aprendizado profundo, que é um tipo de aprendizado de máquina, que é uma abordagem da inteligência artificial. O toylm aprende com dados, então fica no aprendizado de máquina, fora do aprendizado profundo."}
```

## De fora para dentro

**Inteligência artificial** é o campo da computação que constrói programas para fazer tarefas que
as pessoas chamam de inteligentes: jogar um jogo, planejar uma rota, reconhecer fala, traduzir. O
nome vem dos anos 1950, e muito do que o campo construiu não aprende nada. Um programa de xadrez
cujas regras e pontuação foram escritas à mão é IA nesse sentido, e um planejador de rotas também.

**Aprendizado de máquina** (*machine learning*) é a parte da IA em que o comportamento é aprendido
com exemplos em vez de escrito como regras. Um filtro de spam treinado com mensagens que as pessoas
marcaram como spam é aprendizado de máquina. O `toylm` também: ninguém escreveu uma regra dizendo
que `hot` vem depois de `coffee is`; ele contou isso no corpus, o que é aprendizado na forma mais
simples que existe.

**Aprendizado profundo** (*deep learning*) é aprendizado de máquina com redes neurais de muitas
camadas, o tipo de modelo cujos parâmetros são pesos aprendidos (lição 8). Foi o que fez funcionar
bem o reconhecimento de objetos em fotos e a transcrição de fala, e é com ele que os grandes modelos
de linguagem são construídos.

**Grandes modelos de linguagem** são modelos de aprendizado profundo treinados para prever o
próximo token de um texto, numa escala muito grande: o laço da lição 1, com bilhões de pesos por
trás de cada nota. O assistente de chat é um deles, com treinamento adicional para responder em vez
de continuar (lição 1).

## Duas palavras que atravessam as camadas

**Generativo** descreve um modelo que produz conteúdo novo: texto, imagens, áudio, código. Um grande
modelo de linguagem é generativo, e os geradores de imagem também. Um filtro de spam não é: ele
devolve um rótulo, não conteúdo novo. "IA generativa" é, portanto, o tipo que produz, seja lá o que
produza.

**Estreito** (*narrow*) descreve um sistema feito para uma tarefa ou um tipo de tarefa. Um motor de
xadrez é estreito, um filtro de spam é estreito e, num sentido bem real, um modelo de linguagem
também. Ele faz uma coisa, prever o próximo token, e essa coisa acaba cobrindo um número enorme de
tarefas que podem ser escritas como texto. Essa amplitude é o que torna os modelos de linguagem
surpreendentes, e também é por ela que fica fácil esquecer o mecanismo único por baixo.

## AGI

**Inteligência artificial geral** (AGI, na sigla em inglês) é o nome usado para um sistema que
faria a maior parte das tarefas intelectuais que uma pessoa faz, em qualquer área, pelo menos tão bem
quanto uma pessoa. É uma meta, e vale guardar três coisas sobre ela:

- não existe definição combinada. As organizações que usam o termo o definem de jeitos diferentes,
  umas pela capacidade, outras pelo valor econômico, outras por aprender tarefas novas sem ter sido
  treinadas nelas;
- não existe teste combinado. Sem um, a afirmação de que algo "é AGI" ou "está perto da AGI" não
  pode ser conferida, só discutida;
- as previsões de quando ela vai chegar são previsões, feitas por pessoas com interesse na resposta.
  Este curso não faz nenhuma.

O que um grande modelo de linguagem comprovadamente é pode ser conferido, e você conferiu: um
previsor do próximo token cujas notas vêm de pesos aprendidos (lições 1 e 8). **Essa descrição
continua verdadeira por mais impressionante que a saída fique**, e é o ponto de partida certo para
ler qualquer afirmação, que é o assunto da próxima seção.
