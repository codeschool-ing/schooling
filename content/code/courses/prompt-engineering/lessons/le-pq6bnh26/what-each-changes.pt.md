---
title: O que cada um muda
version: 1
---

O ajuste fino (*fine-tuning*) tem fama de ser a versão adulta do prompt: quando um prompt não
basta, você treina o modelo com os seus dados e ele aprende o seu negócio. Isso erra a ordem e os
pontos fortes. **Um prompt muda a entrada; o ajuste fino muda os pesos.** Eles resolvem problemas
diferentes, e aquele pelo qual o ajuste fino é famoso, ensinar ao modelo os seus fatos, é justamente
o que ele faz pior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas linhas. Linha de cima, engenharia de prompt: o seu prompt entra no modelo, cujos pesos não mudam, e sai uma resposta; isso acontece a cada pedido. Linha de baixo, ajuste fino: os seus exemplos entram num treinamento, que produz um modelo novo com pesos mudados; depois um prompt mais curto entra nesse modelo novo e sai uma resposta.\"><defs><marker id=\"ft-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">engenharia de prompt: muda a entrada, a cada pedido</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o seu prompt</text><path d=\"M170 68 L268 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"40\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"355\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pesos iguais</text><path d=\"M440 68 L538 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"540\" y=\"40\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resposta</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">ajuste fino: muda os pesos, uma vez por treinamento</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os seus exemplos</text><path d=\"M170 188 L268 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"160\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um treinamento</text><path d=\"M355 216 L355 238\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"240\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um modelo novo</text><text x=\"355\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pesos mudados</text><text x=\"95\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um prompt mais curto</text><path d=\"M170 265 L268 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><path d=\"M440 265 L538 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"540\" y=\"240\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resposta</text></svg>", "caption": "Onde cada mudança cai. Um prompt é texto novo a cada pedido, e o modelo continua o mesmo; o ajuste fino muda o modelo uma vez, e cada pedido seguinte vai para o modelo mudado."}
```

A lição 8 mostrou que os pesos não se mexem enquanto um modelo é usado. Cada melhoria que você fez
até aqui neste curso, e cada uma das lições 20 a 29, muda só o texto enviado com o pedido. **O
ajuste fino é o treinamento continuado com os seus próprios exemplos**: os pesos são empurrados, do
mesmo jeito que foram no treinamento original, na direção de tornar mais prováveis as respostas dos
seus exemplos. O resultado é um modelo novo, e todo pedido daí em diante vai para ele.

## Como são os exemplos

Um trabalho de ajuste fino recebe um arquivo de exemplos, cada um uma conversa com a resposta que
você quer. Um formato comum é um objeto JSON por linha, aqui com três exemplos para classificar em
categorias as mensagens dos clientes do café:

```
ana@lab:~/pe$ wc -l train.jsonl
3 train.jsonl
ana@lab:~/pe$ head -1 train.jsonl
{"messages": [{"role": "user", "content": "Are you open on Sunday afternoon?"}, {"role": "assistant", "content": "hours"}]}
```

Três é pouquíssimo; um trabalho de verdade quer centenas ou milhares, cada um conferido por alguém
que sabe a resposta certa. Nada foi treinado aqui. A bancada não tem modelo para treinar, e o que
importa no arquivo é o formato: **cada linha é uma pergunta com a resposta que você decidiu que é a
certa.**

## No que o ajuste fino é bom

Treinar com exemplos muda o que é provável, e isso funciona bem para o que é questão de hábito:

- um formato: sempre os mesmos campos de JSON, sempre uma palavra da sua lista de categorias;
- um estilo: o tom da sua equipe de atendimento, o tamanho que os seus leitores esperam;
- uma tarefa estreita feita muitas vezes: classificar chamados, etiquetar produtos, extrair os
  mesmos cinco campos do mesmo tipo de documento;
- prompts mais curtos: instruções e exemplos que um prompt carregaria em todo pedido passam a
  ser carregados pelos pesos.

## No que ele é ruim

**Fatos que mudam.** Se o horário do café fosse treinado nos pesos, mudá-lo exigiria treinar de
novo, e o horário antigo continuaria lá dentro, espalhado por bilhões de números, sem jeito de
apagar. Um modelo treinado com um fato ainda pode produzir outra coisa, porque ele produz texto
provável, não registros guardados (lição 5). Pôr o fato atual no prompt é mais barato e dá para
conferir, e a lição 11 mostra como fazer isso para um manual inteiro.

**Uma especificação vaga.** Se você não consegue dizer o que é uma boa resposta, também não consegue
escrever os exemplos, e treinar com exemplos inconsistentes ensina a inconsistência. Um modelo que
classifica mal porque ninguém decidiu se "Nobody signed for the milk" é `deliveries` ou `other` se
conserta decidindo, e a decisão vai primeiro no prompt. **O ajuste fino deixa um comportamento mais
barato e mais consistente; ele não diz qual deveria ser esse comportamento.**
