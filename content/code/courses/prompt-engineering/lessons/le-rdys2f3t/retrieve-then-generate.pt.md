---
title: Recuperar, depois gerar
version: 1
---

Um modelo perguntado sobre o horário de domingo do Café Aurora vai responder, com fluência, um
horário que soa certo. Ele nunca leu o manual do café: o café foi escrito para este curso, e nenhum
modelo foi treinado com ele. **Um modelo não tem como conhecer um documento que nunca viu, e o jeito
de formular a pergunta não muda isso.** O que muda é pôr as linhas relevantes do documento na frente
do modelo, no prompt, toda vez que uma pergunta é feita. Isso é geração aumentada por recuperação,
RAG (*retrieval-augmented generation*): primeiro recuperar, depois gerar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma sequência de cinco caixas. A pergunta vai para recuperar, que busca no manual, seis arquivos, e devolve os melhores trechos. Eles entram no prompt, junto com uma instrução e a própria pergunta. O prompt vai para o modelo, que escreve a partir das fontes, e a resposta sai citando a fonte 1.\"><defs><marker id=\"rag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"155\" y=\"10\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o manual, seis arquivos</text><path d=\"M215 54 L215 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><rect x=\"10\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a pergunta</text><text x=\"70\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">on sundays?</text><rect x=\"155\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">recuperar</text><text x=\"215\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os melhores trechos</text><rect x=\"300\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o prompt</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instrução, fontes</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e a pergunta</text><rect x=\"445\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"505\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escreve a partir</text><text x=\"505\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">das fontes</text><rect x=\"590\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a resposta</text><text x=\"650\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00-12:00 [1]</text><path d=\"M130 128.0 L153 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M275 128.0 L298 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M420 128.0 L443 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M565 128.0 L588 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M70 166 L70 215 L360 215 L360 168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#rag-ah)\"></path><text x=\"215\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a pergunta entra também</text></svg>", "caption": "Recuperar, depois gerar. A pergunta é usada duas vezes: uma para buscar no manual, e outra dentro do prompt, ao lado dos trechos que a busca achou."}
```

A bancada tem a metade disso que não precisa de modelo. O `handbook/` é o manual de equipe do café,
seis arquivos curtos, e cada linha deles é um trecho:

```
ana@lab:~/pe$ ls handbook
allergens.md
deliveries.md
hours.md
loyalty.md
refunds.md
wifi.md
ana@lab:~/pe$ cat handbook/hours.md
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
```

O `retrieve` recebe uma pergunta e devolve os trechos com a nota mais alta para ela, três por
padrão:

```
ana@lab:~/pe$ retrieve "when does the café open on sundays"
query words: caf open sundays
  2.94  hours.md       On Sundays it opens at 08:00 and closes at 12:00.
  2.51  hours.md       On public holidays the café follows the Sunday hours.
  2.07  hours.md       Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
```

O trecho que responde à pergunta veio primeiro. **Nada na busca entendeu a pergunta**: ela comparou
palavras, e a primeira linha da saída mostra quais palavras usou.

## Como a nota é feita

A fórmula se chama BM25, e é por onde a maioria dos buscadores por palavra-chave começa. Em palavras
simples, um trecho ganha pontos por cada palavra da pergunta que ele contém, e quatro regras decidem
quanto:

- palavras pequenas e comuns, como `when`, `does`, `the` e `on`, são descartadas antes de qualquer
  contagem, e é por isso que sobram só três palavras da pergunta;
- uma palavra que aparece em poucos trechos vale mais do que uma que aparece em muitos, porque
  encontrá-la diz mais sobre o trecho. `sundays` está numa linha só do manual, e sozinha deu 2,94 ao
  primeiro trecho;
- uma palavra repetida num trecho vale um pouco mais a cada vez, e menos a cada repetição;
- um trecho longo tem um pequeno desconto, para que uma linha não ganhe só por ser longa.

Dois detalhes aparecem nessa saída. `café` virou `caf`, porque este buscador só conhece as letras de
a a z e os dígitos; ele faz o mesmo com o manual, então os dois continuam batendo. E `open` não bateu
com nada, porque o manual só diz `opens`: **para esta busca, duas formas de uma palavra são duas
palavras diferentes.** O segundo e o terceiro trechos estão ali só porque contêm `café`.

As notas não são porcentagens e não têm teto fixo. Elas só ordenam os trechos para uma pergunta, e a
nota de uma pergunta não quer dizer nada ao lado da nota de outra.

## O que vem depois

A recuperação não responde nada. Ela produz as provas, e o modelo escreve a resposta a partir delas,
que é o assunto da próxima seção. Vale guardar essa divisão: **quando um sistema de RAG dá uma
resposta errada, a primeira pergunta é se o trecho certo foi recuperado**, e isso dá para conferir
sem modelo nenhum, rodando a busca sozinha, como aqui.
