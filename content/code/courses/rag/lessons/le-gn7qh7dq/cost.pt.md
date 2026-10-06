---
title: Quanto cada um custa
version: 1
---

As duas abordagens põem o custo em lugares diferentes. A recuperação paga um pouco a cada pergunta,
pelo texto recuperado que ela acrescenta ao prompt. O fine-tuning paga muito de uma vez, pelo
treinamento, e de novo toda vez que os fatos mudam. Qual sai mais barato depende de quantas perguntas
há e de quantas vezes o conhecimento se mexe, e as duas coisas podem ser medidas.

## O custo da recuperação: o contexto

O `context_tokens.py` roda a busca para cada pergunta do conjunto de teste e conta os tokens das três
seções que ela poria no prompt:

```
ana@lab:~/rag$ python context_tokens.py
questions: 30
retrieved tokens per question, mean: 332
smallest: 191  largest: 502
```

**332 tokens por pergunta em média**, o preço de três seções inteiras. É o número que um sistema de
recuperação acrescenta a cada prompt, e o que as aulas 4 e 12 passam a maior parte do esforço reduzindo.

## O custo do fine-tuning: treinar, e treinar de novo

Um treinamento é cobrado pelos tokens em que treina, vezes o número de passadas pelos dados, chamadas
**épocas**. O `dataset.py` produziu 968 tokens de exemplos, e três épocas é um padrão comum.

O `costs.py` põe os dois lado a lado num mês, com **preços ilustrativos digitados na linha de comando,
que não são os de nenhum provedor**: 3 por milhão de tokens de entrada e 25 por milhão de tokens de
treinamento. Ele supõe 30.000 perguntas por mês e quatro mudanças de política, portanto quatro
retreinos:

```
ana@lab:~/rag$ python costs.py --questions 30000 --context 332 --train-tokens 968 --epochs 3 --retrains 4 --input-price 3 --train-price 25
RAG, extra context:       29.88 a month
fine-tuning, training:     0.29 a month
ana@lab:~/rag$ python costs.py --questions 30000 --context 332 --train-tokens 968000 --epochs 3 --retrains 4 --input-price 3 --train-price 25
RAG, extra context:       29.88 a month
fine-tuning, training:   290.40 a month
```

A primeira execução faz o fine-tuning parecer quase de graça, e engana do jeito que um exemplo pequeno
sempre engana. **Vinte e seis exemplos não ensinam um corpus a um modelo.** A seção sobre o que o
fine-tuning muda disse por quê: cada fato precisa de muitas formulações para ficar preso de forma
confiável. A segunda execução multiplica o conjunto por mil, para 968.000 tokens, como ilustração do
crescimento que aquele argumento pede: muitas formulações de cada pergunta, para cada fato. A conta do
treinamento sobe para 290,40 por mês, quase dez vezes o custo da recuperação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico do custo mensal contra as perguntas por mês, de 0 a 500 mil. A linha da recuperação sobe a partir de zero, com 29,88 para 30 mil perguntas. A linha do fine-tuning é plana em 290,40. Elas se cruzam perto de 292 mil perguntas por mês.\"><path d=\"M90 270 L680 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 270 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 270 L90.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M208.0 270 L208.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"208.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100 mil</text><path d=\"M326.0 270 L326.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"326.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200 mil</text><path d=\"M444.0 270 L444.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"444.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 mil</text><path d=\"M562.0 270 L562.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"562.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400 mil</text><path d=\"M680.0 270 L680.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500 mil</text><path d=\"M85 270.0 L90 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M85 224.0 L90 224.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"224.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M85 178.0 L90 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M85 132.0 L90 132.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><path d=\"M85 86.0 L90 86.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M85 40.0 L90 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500</text><text x=\"385.0\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perguntas por mês</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">custo por mês, aos preços ilustrativos</text><path d=\"M90.0 270.0 L680.0 40.91999999999999\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M90.0 136.416 L680.0 136.416\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"434.0\" cy=\"136.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"446.04788\" y=\"156.416\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">elas se cruzam perto de 292 mil</text><text x=\"131.4\" y=\"242.2552\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">30 mil: 29,88</text><circle cx=\"125.4\" cy=\"256.3\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"597.4\" y=\"56.99120000000002\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">recuperação: 332 tokens por pergunta</text><text x=\"99.44\" y=\"124.416\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fine-tuning: quatro retreinos de 968.000 tokens</text></svg>", "caption": "A recuperação custa em proporção às perguntas; o fine-tuning, em proporção às mudanças. Com 332 tokens de contexto, quatro retreinos por mês e os preços ilustrativos, as linhas se cruzam perto de 292 mil perguntas por mês."}
```

As duas linhas se cruzam onde o custo da recuperação iguala o do treinamento: 290,40 dividido pelo
custo de 332 tokens a 3 por milhão, cerca de 292.000 perguntas por mês. Abaixo disso, a esses preços e a
esse ritmo de mudança, a recuperação sai mais barata; acima, o modelo ajustado.

## O que a conta deixa de fora

A comparação acima é honesta e incompleta, e as partes que ela deixa de fora favorecem sobretudo a
recuperação.

**Um modelo ajustado em geral é mais caro por token para rodar** que o modelo base de que foi treinado,
nos provedores que oferecem os dois. Isso também é um preço por pergunta, e ficou zerado acima.

**Retreinar não é só a conta do treinamento.** Cada execução pede o conjunto refeito, o modelo avaliado
e a implantação trocada, que é tempo de gente, e tempo de gente custa mais que qualquer das duas linhas
da figura.

**A recuperação também tem custo fixo**: o banco vetorial, os embeddings do corpus e sua regeração
quando o modelo muda. Para treze documentos é desprezível; para milhões, é a maior linha. A aula 18 do
`embeddings-vectors` mediu quanto custam armazenamento e reindexação.

E o eixo que mais importa não está na figura: quantas vezes o conhecimento muda. Dobre o número de
mudanças de política e a linha do fine-tuning dobra; a da recuperação não se mexe.
