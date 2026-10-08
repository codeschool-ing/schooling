---
title: Escolhendo os exemplos
version: 2
---

Três exemplos consertaram sete respostas e quebraram uma. Essa mensagem quebrada é o melhor lugar
para começar, porque **um exemplo ensina mais do que você pôs nele de propósito**:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 4471"}
stop: stop, tokens in 108, out 28, 3.8 s
ana@lab:~/triage$ pl show runs/v3.jsonl t01
│ {"category": "billing", "urgency": "normal", "summary": "Wants a refund for the second payment of order 4471."}
stop: stop, tokens in 250, out 33, 4.9 s
```

O `t01` é um cliente cobrado duas vezes, e a pessoa que o rotulou chamou isso de `high`: o
dinheiro de alguém sumiu. Sem exemplos, o modelo concordou. Com eles, diz `normal`. Olhe o
primeiro exemplo: *"I paid for express delivery but the order came by normal post"*, uma mensagem
de billing, sobre reembolso, rotulada `normal`. O `t01` também é uma mensagem de billing sobre
reembolso, e o modelo deu a ele a urgência do exemplo com que mais se parece. **Um exemplo puxa as
mensagens parecidas com ele para os rótulos dele**, e ninguém consegue dizer de antemão qual
semelhança o modelo vai notar: aqui foi o assunto, e poderia ter sido uma palavra.

Então escolher exemplos é escolher a partir do que o modelo vai generalizar. Quatro regras dão
conta de quase tudo.

## Cubra as fronteiras, não o centro

Um exemplo de um caso óbvio ensina o formato e pouco mais; o modelo classificaria *"I can't log
in"* corretamente de qualquer jeito. **Os exemplos que valem os seus tokens ficam onde dois
rótulos se encontram**: um reembolso de um livro devolvido (returns, não billing), um pacote que
chegou encharcado (returns, não delivery), uma cobrança por uma entrega expressa que não aconteceu
(billing, não delivery). O primeiro exemplo é um desses, e o `t01` mostra que um exemplo de
fronteira precisa de um vizinho do outro lado: uma mensagem de billing que É urgente, rotulada
`high`, ou a linha se move longe demais.

## Tire-os do tráfego real

Um exemplo inventado é mais limpo do que qualquer coisa que um cliente escreve: uma frase, um
problema, nenhuma saudação. Um modelo que só viu exemplos limpos não aprendeu nada sobre a mensagem
que abre com três linhas de desculpas e faz duas perguntas. Escolha exemplos entre as mensagens que
você tem, depois de tirar nomes e números de pedido, e **mantenha-os fora do conjunto de teste**.
Um exemplo que também é caso de teste é respondido por cópia, e a aula 11 mostra o quanto isso
infla uma nota.

## Equilibre os rótulos

Todo exemplo puxa um pouco para os próprios rótulos, diga ele o que disser. Estes três são dois
`normal` e um `low`, e nenhum `high`; cinco exemplos de billing e um de delivery puxariam todo caso
duvidoso para billing do mesmo jeito. A aula 18 mede o quanto isso move as respostas.

## Conte o que eles custam

Os exemplos são pagos em toda chamada, porque fazem parte de todo prompt. O `pl show` imprime os
tokens que entraram, e o `t01` entrou duas vezes acima: 108 tokens sem os exemplos e 250 com eles.
**Os três exemplos mais que dobraram a entrada de toda chamada**, e um modelo lê cada token que
recebe antes de escrever a primeira palavra da resposta, o que num processador é tempo de espera.
Valeu a pena aqui, por sete respostas em quarenta. Um quarto exemplo tem de merecer o lugar do
mesmo jeito, com uma contagem do que consertou. A aula 16 faz a conta do que cada token custa, e a
aula 17 mostra como um cache barateia a parte fixa de um prompt.
