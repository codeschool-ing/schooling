---
title: Modelos base e modelos ajustados
version: 1
---

Um modelo que só passou pelo pré-treino faz exatamente uma coisa: **continua texto**. Dê o começo
de uma frase e ele escreve o que plausivelmente vem depois. Dê uma pergunta e ele pode responder,
ou pode escrever mais três perguntas, porque no texto de onde aprendeu uma pergunta muitas vezes
vem seguida de outras. Isso é um **modelo base**.

O documento de formato de prompt da Meta mostra um, com uma entrada escrita pela Meta e a resposta
que o modelo base deu:

```
ana@desk:~/desk$ sources quote llama3.1-prompt-format '^<.begin_of_text.>Color|^ red, orange'
# meta-llama/llama-models@0e0b8c51 models/llama3_1/prompt_format.md
  31: <|begin_of_text|>Color of sky is blue but sometimes can also be
  36: red, orange, yellow, green, purple, pink, brown, gray, black, white, and even rainbow
      colors. The color of the sky can change due to various reasons such as time of day,
      weather conditions, pollution, and atmospheric phenomena.
```

Ninguém pediu uma lista de cores. O modelo viu o começo de uma frase e seguiu em frente, como
seguiria o fim de um parágrafo de enciclopédia. Ele fez o trabalho dele perfeitamente; o trabalho
dele não é responder a você.

## O que o ajuste acrescenta

Um modelo **ajustado para instruções** (a Llama chama de *Instruct*, outros provedores chamam de
*chat*) é a mesma rede treinada mais um pouco com conversas: um pedido, depois a resposta que um
assistente prestativo daria. Depois disso ele trata o seu texto como uma vez na conversa, responde
e **para**. Parar também é aprendido, e o documento diz como cada tipo termina:

```
ana@desk:~/desk$ sources quote llama3.1-prompt-format 'end_of_text...: Model|End of turn'
# meta-llama/llama-models@0e0b8c51 models/llama3_1/prompt_format.md
   7: - `<|end_of_text|>`: Model will cease to generate more tokens. This token is generated
      only by the base models.
  11: - `<|eot_id|>`: End of turn. Represents when the model has determined that it has
      finished interacting with the user message that initiated its response. This is used in
      two scenarios:
```

O modelo base termina quando o texto terminaria. O ajustado emite um token que quer dizer *a minha
vez acabou*, e quem está servindo o modelo para de gerar ali. Esse único token é a diferença entre
uma resposta e um falatório.

Um terceiro tipo apareceu desde então: os **modelos de raciocínio**, ajustados mais uma vez para
escrever o caminho antes de responder. As aulas 6 a 8 os encontram com o nome que cada provedor
dá. Para escolher, eles se comportam como um modelo ajustado que gasta mais tokens, e mais tempo,
em cada resposta.

## Qual deles você recebe

- **Toda API de chat serve modelos ajustados.** Quando a aula 16 manda o e-mail da Lantern Books
  para uma API, não há modelo base por trás. Você nunca precisa pensar nisso nas aulas de API.
- **Coleções abertas publicam os dois**, lado a lado, muitas vezes com o mesmo tamanho no nome.
  Num hub de modelos, um nome sem *Instruct*, *chat* ou *it* geralmente é o base, e baixar o
  errado é um primeiro erro comum: carrega, roda, e responde a um e-mail de suporte escrevendo
  outro e-mail de suporte.
- **Um modelo base é o que se usa no fine-tuning**, quando há fine-tuning (seção 07). O ajuste que
  o provedor fez é uma escolha para o caso geral; partir do base significa fazer essa escolha você
  mesmo.

**Para as três tarefas da ana**, classificar, extrair um número de pedido e rascunhar uma
resposta, um modelo ajustado é o único começo sensato. Todos os que ela avalia na aula 5 são.
