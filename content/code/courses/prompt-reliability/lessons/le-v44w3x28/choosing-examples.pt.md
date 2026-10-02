---
title: Escolher os exemplos
version: 1
---

Três exemplos corrigiram o formato de quarenta respostas e quebraram uma categoria. Essa mensagem
quebrada é o melhor lugar para começar, porque **um exemplo ensina mais do que você colocou nele de
propósito**:

```
ana@lab:~/triage$ grep t37 cases/dev.jsonl
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/v3.jsonl t37
│ {"category": "billing", "urgency": "normal", "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."}
stop: end, tokens in 246, out 46
```

`t37` é um pedido atrasado, e o prompt sem exemplos o classificava como delivery. Com exemplos, diz
billing. O primeiro exemplo também fala de entrega, *"I paid for express delivery but the order came
by normal post"*, e está rotulado billing porque o cliente quer dinheiro de volta. As duas mensagens
compartilham `order`, e no substituto **um exemplo puxa as mensagens parecidas com ele para o
próprio rótulo**. Modelos reais são puxados do mesmo jeito, pela semelhança de superfície além do
sentido, e ninguém consegue dizer de antemão qual superfície eles vão notar.

Então escolher exemplos é escolher de onde o modelo vai generalizar. Quatro regras cobrem
quase tudo.

## Cubra as fronteiras, não o centro

Um exemplo de caso óbvio ensina o formato e pouco mais; o modelo classificaria *"I can't log in"*
certo de qualquer jeito. **Os exemplos que valem os tokens ficam onde dois rótulos se encontram**: um
reembolso de livro devolvido (returns, não billing), uma encomenda que chegou encharcada (returns,
não delivery), uma cobrança por entrega expressa que não aconteceu (billing, não delivery). O
primeiro exemplo é um desses, e `t37` mostra que um exemplo de fronteira precisa de um vizinho do
outro lado — um pedido atrasado rotulado delivery — ou ele empurra a linha longe demais.

## Tire-os do tráfego real

Um exemplo inventado é mais limpo do que qualquer coisa que um cliente escreve: uma frase, um
problema, nenhum cumprimento. Um modelo que só viu exemplos limpos não aprendeu nada sobre a mensagem
que abre com três linhas de desculpas e faz duas perguntas. Escolha os exemplos entre as mensagens
que você tem, depois de tirar nomes e números de pedido, e **mantenha-os fora do conjunto de
teste**. Um exemplo que também é caso de teste é respondido por cópia, e a aula 11 mostra quanto isso
infla uma nota.

## Equilibre os rótulos

Todo exemplo acrescenta alguma atração para o próprio rótulo, diga o que disser. Cinco exemplos de
billing e um de delivery inclinam toda decisão apertada para billing. A aula 18 mede quanto isso
move as respostas.

## Conte o que eles custam

Exemplos são pagos em toda chamada, porque fazem parte de todo prompt:

```
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl tokens prompts/v3-examples.txt
229 tokens, 122 words, 850 characters
```

Os três exemplos levaram o prompt de 69 tokens para 229, mais de três vezes a entrada de cada
chamada. Aqui valeu a pena; o problema de formato valia treze respostas em quarenta. **Um quarto
exemplo tem que pagar o lugar do mesmo jeito**, com uma contagem do que ele corrigiu. A aula 16 faz a
conta do que cada token custa, e a aula 17 mostra como um cache barateia a parte fixa de um prompt.
