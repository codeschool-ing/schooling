---
title: Julgando com um modelo
version: 1
---

Quando as respostas são parafraseadas, nada tão simples quanto uma substring consegue dizer se estão
certas. A resposta comum é perguntar a outro modelo: dar a ele a pergunta, a resposta esperada e a
resposta dada, e perguntar se a resposta está correta. Isso se chama **LLM como juiz** (LLM-as-judge), e é
como a maioria das equipes mede a qualidade das respostas em escala.

**Não foi rodado aqui.** O extract-1 não consegue julgar nada; ele copia frases. Nenhum modelo real
estava ao alcance do laboratório. O que vem a seguir é o método, o prompt como alguém o escreveria, e os
cuidados, sem resultados. A aula 13 do `prompt-reliability` mediu juízes no laboratório dela e é o lugar
para ver um funcionando.

## Um prompt de juiz

Um prompt de juiz é curto, faz uma pergunta, e restringe a resposta a algo que um programa consegue ler:

```
You are checking an answer from a customer support assistant.

Question: {question}
Expected answer, from the documents: {expected}
Assistant's answer: {reply}

Does the assistant's answer state the same fact as the expected answer,
without adding anything that contradicts it? Ignore wording and length.
Reply with one word: CORRECT, INCORRECT or REFUSED.
```

A resposta esperada vem do conjunto de teste, e é por isso que toda pergunta ali deveria levar o trecho
que a responde, e não só algumas palavras. O juiz então compara significado com significado, que é a
comparação que um fato não consegue fazer.

## O que os juízes erram

Estudos de modelos juízes, e as medições do `prompt-reliability`, encontram sempre os mesmos vieses:

- **Posição**: pedido para comparar duas respostas, um juiz tende a preferir a primeira mostrada. Troque
  a ordem e pergunte de novo; só conte uma preferência que sobreviva à troca.
- **Tamanho**: respostas mais longas são julgadas melhores mais vezes do que merecem. Uma rubrica que
  diz *ignore o tamanho* ajuda e não cura.
- **Autopreferência**: um juiz avalia com mais boa vontade as respostas da família do próprio modelo.
- **Concordar com a confiança**: uma resposta errada e confiante é marcada como correta mais vezes que
  uma certa e hesitante.

Nada disso torna um juiz inútil. Torna-o um instrumento que precisa de calibração.

## Calibrando o juiz

**Rotule uma amostra à mão.** Cinquenta respostas marcadas como corretas ou não por uma pessoa que
conhece os documentos. **Rode o juiz nas mesmas cinquenta** e conte a concordância. Se o juiz concorda
com a pessoa na maioria delas, e as discordâncias não pendem para um lado, use-o; se pendem, conserte o
prompt e meça de novo. **Repita quando algo mudar**: um modelo juiz novo, um prompt novo, um tipo novo de
pergunta. Um juiz calibrado há um ano contra outro pipeline não mede nada em particular agora.

E mantenha as verificações baratas rodando ao lado. Um teste de fato que diz *errada* e um juiz que diz
*correta* são um desacordo que vale dois minutos de uma pessoa.
