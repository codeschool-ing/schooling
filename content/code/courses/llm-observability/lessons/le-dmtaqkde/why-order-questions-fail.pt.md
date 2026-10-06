---
title: Por que as perguntas sobre pedido eram recusadas
version: 1
---

Uma taxa diz que algo está errado com uma funcionalidade. Um trace diz o quê. Pegue uma das mensagens
sobre pedido da semana e a mesma pergunta sem os dados do cliente, e olhe o span de busca de cada uma:

```
ana@lab:~/obs$ python assistant.py --feature order "Hi, I am Joana Prado (joana.prado@example.com). My order MG-20481937 has not arrived after 12 working days. Is it lost?" > /dev/null; python tree.py --attrs | grep -E "top_score|kept"
                       app.search.kept = 0
                       app.search.top_score = 0.539
ana@lab:~/obs$ python assistant.py "My order has not arrived after 12 working days. Is it lost?" > /dev/null; python tree.py --attrs | grep -E "top_score|kept"
                       app.search.kept = 0
                       app.search.top_score = 0.605
```

A mesma pergunta, **0,539 com o nome, o endereço e o número do pedido nela, 0,605 sem**. O embedding de
uma mensagem é o embedding dela inteira, e um nome, um endereço de e-mail e um número de pedido a puxam
para longe dos documentos, que não contêm nada disso. As duas notas agora estão abaixo do piso de 0,62,
e é por isso que as duas foram recusadas. Sob o piso antigo de 0,5, a primeira teria passado raspando e
a segunda com folga.

Essa é uma descoberta que um painel não teria feito e que um trace fez em dois comandos. Ela também
aponta para a correção, e ela não está no piso: **a busca deveria receber a pergunta, não a mensagem**.
Uma etapa antes da recuperação que tire os dados do cliente, que a aula 2 já escreveu (`redact()`), ou
que peça a um modelo que reformule a pergunta, como faz a aula 6 do `rag` quando reescreve perguntas,
daria às perguntas sobre pedido a mesma chance das de ajuda. A aula 14 testa uma mudança assim contra o
conjunto de avaliação antes de deixá-la chegar perto da produção.

## O movimento geral

A taxa de recusa era o **sintoma**, medido sobre tudo. A **causa** foi achada indo da taxa para alguns
traces por trás dela e lendo os seus atributos. Esse movimento, de um número para os traces que o
compõem, é aquilo em volta do qual toda ferramenta das aulas 6 e 7 é construída: um gráfico em que se
clica para ver os traces debaixo de um ponto. Ele só funciona se os traces carregam os atributos que os
explicam, aqui `app.search.top_score`, e é por isso que a aula 1 insistiu em registrar as entradas além
das saídas.
