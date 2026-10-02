---
title: Soft prompts, que são números e não palavras
version: 1
---

Um prompt parece um trecho de texto em inglês ou português, e a suposição natural é que o modelo o
lê como você. **Ele lê números.** A lição 3 mostrou o primeiro passo: o texto é cortado em tokens,
e cada token é um id.

```
ana@lab:~/pe$ tok show "Answer in one word."
"Answer" " in" " one" " word" "."
17045 306 1001 2195 13
5 tokens, 19 characters (o200k_base)
```

O segundo passo acontece dentro do modelo. Cada id escolhe uma linha de uma tabela grande que o
modelo aprendeu no treinamento, e essa linha é uma lista de números chamada **embedding**: um vetor.
O `17045` não é usado como número; é um endereço, e o que o modelo usa nas contas é o vetor guardado
ali. Cinco tokens entram como cinco vetores.

A mesma frase passada por outro tokenizador sai com ids diferentes:

```
ana@lab:~/pe$ tok show "Answer in one word." -e cl100k_base
"Answer" " in" " one" " word" "."
16533 304 832 3492 13
5 tokens, 19 characters (cl100k_base)
```

Os pedaços são os mesmos e quatro dos cinco ids mudaram, porque cada id é um endereço na tabela
do seu próprio modelo; o ponto final calha de estar no `13` nos dois. Guarde isso: é o que decide
para onde um prompt aprendido pode ou não ser levado.

## Pulando as palavras

Quando você enxerga o prompt como uma fileira de vetores, surge uma pergunta. **Todo prompt escrito
é uma fileira de vetores tirados da tabela. Por que se limitar a eles?** Um vetor em algum ponto
entre as linhas, que nenhum token jamais produziria, poderia guiar o modelo melhor que qualquer
palavra.

Isso é o **prompt tuning**, batizado num artigo de 2021, "The Power of Scale for Parameter-Efficient
Prompt Tuning". Você põe um pequeno número de vetores extras na frente da entrada, um *soft prompt*
("prompt maleável"), e os treina:

1. Comece o soft prompt com números aleatórios, ou com os embeddings de algumas palavras comuns.
2. Passe um exemplo rotulado pelo modelo: o soft prompt, depois a entrada, e compare a saída com a
   resposta que você queria.
3. Calcule, por descida do gradiente, que pequena mudança nos números do soft prompt teria tornado
   a resposta certa mais provável, e aplique.
4. Repita sobre o conjunto de treino, muitas vezes.

**Os pesos do próprio modelo não mudam.** Eles ficam congelados; os únicos números que se mexem são
os do soft prompt. É isso que o torna barato em comparação com o fine-tuning (lição 9): o que você
treina e guarda é um punhado de vetores, e um único modelo congelado pode levar um soft prompt
diferente para cada tarefa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Quatro vetores aprendidos, o soft prompt, ficam na frente de cinco embeddings buscados para os tokens Answer, in, one, word e o ponto final. Os dois entram no modelo, cujos pesos estão congelados. A saída dele é comparada com a resposta desejada, e uma seta tracejada que sai dessa comparação volta só para os quatro vetores do soft prompt: o treino ajusta esses números e nada mais.\"><defs><marker id=\"soft-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s1</text><rect x=\"88\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"113\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s2</text><rect x=\"146\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s3</text><rect x=\"204\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"229\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s4</text><rect x=\"280\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"316\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Answer</text><rect x=\"360\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">in</text><rect x=\"440\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"476\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">one</text><rect x=\"520\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">word</text><rect x=\"600\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"636\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><text x=\"142\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">soft prompt: vetores aprendidos</text><text x=\"476\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a entrada: um embedding por id de token</text><path d=\"M142 104 L142 138\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><path d=\"M476 104 L476 138\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><rect x=\"30\" y=\"140\" width=\"642\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"351\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo: pesos congelados</text><path d=\"M556 190 L556 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><rect x=\"440\" y=\"212\" width=\"232\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">saída, contra a resposta desejada</text><path d=\"M440 229 L15 229 L15 87 L28 87\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#soft-ah)\"></path><text x=\"230\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o treino ajusta só estes números</text></svg>", "caption": "Prompt tuning. Alguns vetores aprendidos vão na frente dos embeddings da entrada; o modelo fica congelado, e o treino mexe só no soft prompt."}
```

## O que você ganha, e quanto custa

Um soft prompt treinado é uma lista curta de vetores. **Ele não é texto, e não pode ser lido de
volta como texto.** Você pode procurar o token cujo embedding está mais perto de cada vetor, e o que
volta não se lê como uma instrução, porque o vetor nunca foi nenhuma daquelas palavras. Você não
consegue revisá-lo, editá-lo à mão nem explicá-lo a um colega como faria com um prompt escrito.

Ele também fica preso a um modelo. Os vetores foram ajustados contra os pesos congelados daquele
modelo. A captura acima já mostra dois vocabulários dando endereços diferentes à mesma frase, e os
vetores por trás dos endereços também mudam de um modelo para outro: outro modelo lê os mesmos
números como algo completamente diferente.

E ele precisa de duas coisas que um prompt escrito não precisa:

- **os pesos do modelo**, para rodar o treino e pôr os vetores na entrada. Por uma API você envia
  texto, então não há onde pôr um vetor, nem contra o que calcular um gradiente;
- **um conjunto de treino**: exemplos rotulados da tarefa, o bastante para os vetores se
  acomodarem, e mais alguns guardados à parte para conferi-los.

O prompt tuning é um de uma família de métodos **eficientes em parâmetros** (*parameter-efficient*),
que treinam todos um número pequeno de números novos ao lado de um modelo congelado. O *prefix
tuning* põe vetores aprendidos na frente em cada camada do modelo, não só na entrada; os *adapters*
e o *LoRA* acrescentam pequenas peças treináveis dentro dele. Os detalhes mudam e a troca é a mesma:
muito menos para treinar do que o modelo inteiro, e muito mais para providenciar do que uma frase.
